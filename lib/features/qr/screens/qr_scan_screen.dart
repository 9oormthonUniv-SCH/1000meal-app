import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../../common/config/app_config.dart';
import '../../../common/dio/api_exception.dart';
import '../../../common/widgets/app_snackbar.dart';
import '../../../util/colors.dart';
import '../data/qr_api.dart';
import '../models/qr_models.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../auth/screens/login_screen.dart';
import 'qr_auth_screen.dart';
import 'qr_camera_view.dart';
import 'qr_confirm_screen.dart';

enum _QrView { loading, camera, confirm, auth }

/// 사용자 노출 메시지 (예외/안내 통일)
abstract class _QrMessages {
  static const alreadyUsedToday = '오늘 이미 명부 등록을 완료했습니다.';
  static const noStoreInfoInQr = 'QR 코드에 매장 정보가 없습니다. 매장에 배포된 오늘순밥 QR을 스캔해 주세요.';
  static const notStoreQr = '인식된 QR이 오늘순밥 매장 QR이 아닙니다. 매장에 배포된 전용 QR을 스캔해 주세요.';
  static const invalidStoreQr = '올바른 매장 QR이 아닙니다. 매장에 배포된 오늘순밥 QR을 스캔해 주세요.';
  static const loginRequired = '로그인이 필요합니다.';
  static const storeNotFound = '해당 매장을 찾을 수 없습니다. QR 코드를 확인해 주세요.';
  static const registerFailed = '명부 등록에 실패했습니다. 잠시 후 다시 시도해 주세요.';
  static const testScanLoginRequired = '테스트 스캔은 로그인 후 사용할 수 있습니다.';
}

/// QR 탭: 진입 시 당일 등록 여부에 따라 인증 화면 또는 카메라.
/// 스캔 → 확인 화면 → 확인 시 POST → 인증 화면. 인증 화면에서 카메라로 돌아가기 / X 동작.
class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key, this.onExit, this.onQrViewChanged});

  /// 카메라 화면에서 X 탭 시(인증 화면에서 온 경우 제외) 호출. null이면 무시.
  final VoidCallback? onExit;
  /// auth(당일 등록 완료) 화면 표시 여부. 바텀바 표시 제어용.
  final void Function(bool isAuthScreen)? onQrViewChanged;

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  _QrView _view = _QrView.loading;
  QrTodayResponse? _todayUsage;
  bool _fromAuth = false;
  String? _pendingQrToken;
  String _pendingStoreName = '매장';
  bool _isProcessing = false;
  String _authName = '';
  String _authUserId = '';
  String? _lastProcessedUrl;
  DateTime? _lastProcessedAt;
  static const _cooldown = Duration(seconds: 2);

  bool _didCheckToday = false;
  /// 비로그인 시 카메라 진입 시 하단에 로그인 유도 문구·버튼 표시
  bool _showLoginPromptOnCamera = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didCheckToday) return;
    _didCheckToday = true;
    _checkTodayAndOpen();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkTodayAndOpen() async {
    final authRepo = context.read<AuthRepository>();
    final qrApi = context.read<QrApi>();
    final token = await authRepo.getAccessToken();
    if (!mounted) return;
    if (token == null || token.isEmpty) {
      setState(() {
        _todayUsage = null;
        _view = _QrView.camera;
        _showLoginPromptOnCamera = true;
      });
      return;
    }
    try {
      final today = await qrApi.getTodayUsage(token);
      if (!mounted) return;
      setState(() {
        _todayUsage = today;
        _view = today != null ? _QrView.auth : _QrView.camera;
        _showLoginPromptOnCamera = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _view = _QrView.camera;
        _showLoginPromptOnCamera = false;
      });
    }
  }

  /// QR 인식에 쓰는 URL 형식:
  /// 1) 스캔 문자열이 36자 UUID이면 그대로 토큰으로 사용 (QR에 UUID만 넣은 경우).
  /// 2) 쿼리: "https://아무도메인/경로?qrToken=매장토큰" → qrToken 추출.
  /// 3) path 마지막 세그먼트가 토큰인 경우.
  /// 반환 전 trim, UUID 형식이면 대문자로 통일.
  String? _parseQrTokenFromUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.length == 36 && _isValidQrToken(trimmed)) {
      return trimmed.toUpperCase();
    }
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    String? token;
    final queryToken = uri.queryParameters['qrToken'];
    if (queryToken != null && queryToken.isNotEmpty) {
      final base = AppConfig.appDownloadUrlBase;
      if (base != null && base.isNotEmpty) {
        if (!url.startsWith(base)) return null;
      }
      token = queryToken.trim();
    } else {
      final segments = uri.pathSegments;
      if (segments.isEmpty) return null;
      final base = AppConfig.appDownloadUrlBase;
      if (base != null && base.isNotEmpty && !url.startsWith(base)) return null;
      token = segments.last.trim();
    }
    if (token == null || token.isEmpty) return null;
    if (RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(token)) {
      token = token.toUpperCase();
    }
    return token;
  }

  /// 백엔드가 매장 식별에 쓰는 qrToken 형식: UUID (36자, 8-4-4-4-12)
  static bool _isValidQrToken(String token) {
    if (token.length != 36) return false;
    return RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(token);
  }

  /// 스캔된 URL이 "앱 다운로드" 고정 링크인지 (qrToken 없을 때 안내용).
  bool _isAppDownloadUrl(String url) {
    final base = AppConfig.appDownloadUrlBase;
    if (base == null || base.isEmpty) return false;
    return url.startsWith(base);
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing || _view != _QrView.camera) return;
    final raw = capture.barcodes.firstOrNull?.rawValue?.trim();
    if (raw == null || raw.isEmpty) return;
    final url = raw;
    final now = DateTime.now();
    if (_lastProcessedUrl == url &&
        _lastProcessedAt != null &&
        now.difference(_lastProcessedAt!) < _cooldown) return;

    if (_todayUsage != null) {
      setState(() {
        _lastProcessedUrl = url;
        _lastProcessedAt = now;
      });
      AppSnackBar.showWithShake(context, _QrMessages.alreadyUsedToday);
      return;
    }

    final qrToken = _parseQrTokenFromUrl(url);
    if (kDebugMode) {
      debugPrint('[QR] 스캔 raw(${url.length}): "$url" → qrToken: ${qrToken ?? "null"}');
    }
    if (qrToken == null) {
      AppSnackBar.showWithShake(
        context,
        _isAppDownloadUrl(url) ? _QrMessages.noStoreInfoInQr : _QrMessages.notStoreQr,
      );
      return;
    }
    if (!_isValidQrToken(qrToken)) {
      AppSnackBar.showWithShake(context, _QrMessages.invalidStoreQr);
      return;
    }

    setState(() {
      _lastProcessedUrl = url;
      _lastProcessedAt = now;
      _isProcessing = true;
    });

    final authRepo = context.read<AuthRepository>();
    final qrApi = context.read<QrApi>();
    authRepo.getAccessToken().then((token) async {
      if (!mounted) return;
      if (token == null || token.isEmpty) {
        setState(() => _isProcessing = false);
        _showLoginRequiredDialog(context);
        return;
      }
      String storeName = '매장';
      try {
        final name = await qrApi.getStoreNameByQrToken(qrToken, token);
        if (name != null && name.isNotEmpty) storeName = name;
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _pendingQrToken = qrToken;
        _pendingStoreName = storeName;
        _isProcessing = false;
        _view = _QrView.confirm;
      });
    });
  }

  void _onConfirmBack() {
    setState(() {
      _view = _QrView.camera;
      _pendingQrToken = null;
      _pendingStoreName = '매장';
    });
  }

  void _showLoginRequiredDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('로그인이 필요해요'),
        content: const Text(
          '로그인하면 매장 QR 명부 등록을 할 수 있어요.',
          style: TextStyle(fontSize: 15, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(ctx).pushNamedAndRemoveUntil('/login', (route) => false);
            },
            child: const Text('로그인 하기'),
          ),
        ],
      ),
    );
  }

  void _onConfirmSubmit() {
    final token = _pendingQrToken;
    if (token == null) return;
    setState(() => _isProcessing = true);
    final authRepo = context.read<AuthRepository>();
    final qrApi = context.read<QrApi>();
    authRepo.getAccessToken().then((t) async {
      if (!mounted || t == null || t.isEmpty) {
        if (mounted) setState(() => _isProcessing = false);
        return;
      }
      try {
        final usage = await qrApi.reportQrUsageByToken(token, t);
        String authName = '';
        String authUserId = '';
        try {
          final me = await authRepo.getMe();
          authName = me.name?.trim() ?? '';
          authUserId = me.username.trim();
        } catch (_) {}
        if (!mounted) return;
        setState(() {
          _todayUsage = QrTodayResponse(
            used: true,
            storeId: usage.storeId,
            storeName: usage.storeName,
            usedAt: usage.usedAt,
            usedDate: usage.usedDate,
          );
          _authName = authName;
          _authUserId = authUserId;
          _pendingQrToken = null;
          _isProcessing = false;
          _view = _QrView.auth;
        });
      } catch (e, _) {
        if (!mounted) return;
        setState(() => _isProcessing = false);
        String msg = _QrMessages.registerFailed;
        if (e is ApiException) {
          if (e.statusCode == 409) {
            final d = e.details;
            msg = (d is Map && d['message'] != null)
                ? d['message'].toString().trim()
                : '오늘 이미 이용했습니다.';
            if (msg.isEmpty) msg = '오늘 이미 이용했습니다.';
          } else if (e.statusCode == 404) {
            msg = _QrMessages.storeNotFound;
          } else if (e.message.isNotEmpty) {
            msg = e.message;
          }
        }
        AppSnackBar.show(context, msg, centered: true);
      }
    });
  }

  void _goToCameraFromAuth() {
    setState(() {
      _fromAuth = true;
      _view = _QrView.camera;
    });
  }

  void _onCameraClose() {
    if (_fromAuth) {
      setState(() {
        _fromAuth = false;
        _view = _QrView.auth;
      });
    }
  }

  void _notifyAuthScreenVisible() {
    widget.onQrViewChanged?.call(_view == _QrView.auth);
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _notifyAuthScreenVisible());
    if (_view == _QrView.loading) {
      return Scaffold(
        backgroundColor: AppColors.black,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.white),
        ),
      );
    }

    if (_view == _QrView.confirm) {
      final token = _pendingQrToken ?? '';
      final suffix = token.length >= 8 ? token.substring(token.length - 8) : token;
      return QrConfirmScreen(
        storeName: _pendingStoreName,
        isLoading: _isProcessing,
        onBack: _onConfirmBack,
        onConfirm: _onConfirmSubmit,
        debugTokenSuffix: kDebugMode ? suffix : null,
      );
    }

    if (_view == _QrView.auth) {
      return QrAuthScreen(
        today: _todayUsage!,
        name: _authName,
        userId: _authUserId,
        onBackToCamera: _goToCameraFromAuth,
      );
    }

    return QrCameraView(
      controller: _controller,
      onDetect: _onDetect,
      isProcessing: _isProcessing,
      fromAuth: _fromAuth,
      onClose: _onCameraClose,
      onExit: widget.onExit,
      onTestScan: kDebugMode ? _runTestScan : null,
      showLoginPrompt: _showLoginPromptOnCamera,
      onLoginTap: _showLoginPromptOnCamera
          ? () async {
              await Navigator.of(context).pushNamed(LoginScreen.routeName);
              if (!mounted) return;
              _didCheckToday = false;
              _checkTodayAndOpen();
            }
          : null,
    );
  }

  void _runTestScan() async {
    if (!mounted) return;
    final authRepo = context.read<AuthRepository>();
    final qrApi = context.read<QrApi>();
    final token = await authRepo.getAccessToken();
    if (!mounted) return;
    if (token == null || token.isEmpty) {
      AppSnackBar.show(context, _QrMessages.testScanLoginRequired);
      return;
    }
    const testUrl = 'https://1000meal.shop/qr/stores/?qrToken=E722A795-B214-43E8-B8AE-A336ED0FBDC4';
    final testToken = _parseQrTokenFromUrl(testUrl);
    if (testToken == null || !_isValidQrToken(testToken)) {
      if (mounted) {
        AppSnackBar.show(context, _QrMessages.invalidStoreQr);
      }
      return;
    }
    String storeName = '매장';
    try {
      final name = await qrApi.getStoreNameByQrToken(testToken, token);
      if (name != null && name.isNotEmpty) storeName = name;
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _pendingQrToken = testToken;
      _pendingStoreName = storeName;
      _view = _QrView.confirm;
    });
  }
}
