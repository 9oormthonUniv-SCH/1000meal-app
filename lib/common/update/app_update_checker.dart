import 'dart:io';

import 'package:flutter/material.dart';
import 'package:new_version_plus/new_version_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// 업데이트 노출 정책
/// - 메이저/마이너 상승: 강제 업데이트(업데이트 하러가기만)
/// - 패치 상승: 권장 업데이트(다음에 하기 포함, 하루 1회)
class AppUpdateChecker {
  static const String _lastRecommendedShownYmdKey =
      'update_recommended_last_shown_ymd_v1';

  static const String _iosStoreUrl =
      'https://apps.apple.com/us/app/%EC%98%A4%EB%8A%98%EC%88%9C%EB%B0%A5/id6759449946';
  static const String _androidStoreUrl =
      'https://play.google.com/store/apps/details?id=com.todaysunbap.app';

  static String _todayYmdLocal() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static Future<void> checkAndPromptIfNeeded(BuildContext context) async {
    try {
      final status = await NewVersionPlus(
        iOSId: '6759449946',
        androidId: 'com.todaysunbap.app',
      ).getVersionStatus();

      if (!context.mounted) return;
      if (status == null) return;
      final local = _parseSemVer(status.localVersion);
      final store = _parseSemVer(status.storeVersion);
      if (local == null || store == null) return;

      final cmp = _compareSemVer(local, store);
      if (cmp >= 0) return; // already latest or newer

      final isMajorOrMinorBump =
          store.major > local.major || (store.major == local.major && store.minor > local.minor);
      final isPatchBump =
          store.major == local.major && store.minor == local.minor && store.patch > local.patch;

      // 정책상 patch bump만 권장, 그 외(major/minor)는 강제
      if (isMajorOrMinorBump) {
        await _showForceDialog(context, storeVersion: status.storeVersion);
        return;
      }
      if (isPatchBump) {
        final prefs = await SharedPreferences.getInstance();
        if (!context.mounted) return;
        final today = _todayYmdLocal();
        final last = prefs.getString(_lastRecommendedShownYmdKey);
        if (last == today) return;
        final shown = await _showRecommendedDialog(
          context,
          storeVersion: status.storeVersion,
        );
        if (shown) {
          await prefs.setString(_lastRecommendedShownYmdKey, today);
        }
      }
    } catch (_) {
      // network/store fetch failure: ignore
    }
  }

  static Future<void> _openStore() async {
    final url = Platform.isIOS ? _iosStoreUrl : _androidStoreUrl;
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<void> _showForceDialog(
    BuildContext context, {
    required String storeVersion,
  }) async {
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('업데이트가 필요합니다'),
          content: Text('새 버전($storeVersion)이 출시되었습니다.\n업데이트 후 이용해 주세요.'),
          actions: [
            TextButton(
              onPressed: () async {
                await _openStore();
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('업데이트 하러가기'),
            ),
          ],
        );
      },
    );
  }

  static Future<bool> _showRecommendedDialog(
    BuildContext context, {
    required String storeVersion,
  }) async {
    if (!context.mounted) return false;
    bool shown = false;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        shown = true;
        return AlertDialog(
          title: const Text('업데이트 안내'),
          content: Text('새 버전($storeVersion)이 있습니다.\n업데이트하시겠어요?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('다음에 하기'),
            ),
            TextButton(
              onPressed: () async {
                await _openStore();
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('업데이트'),
            ),
          ],
        );
      },
    );
    return shown;
  }
}

class _SemVer {
  final int major;
  final int minor;
  final int patch;
  const _SemVer(this.major, this.minor, this.patch);
}

_SemVer? _parseSemVer(String raw) {
  final cleaned = raw.trim().split('+').first; // ignore build
  final parts = cleaned.split('.');
  if (parts.length < 2) return null;
  final major = int.tryParse(parts.elementAtOrNull(0) ?? '') ?? 0;
  final minor = int.tryParse(parts.elementAtOrNull(1) ?? '') ?? 0;
  final patch = int.tryParse(parts.elementAtOrNull(2) ?? '') ?? 0;
  return _SemVer(major, minor, patch);
}

int _compareSemVer(_SemVer a, _SemVer b) {
  if (a.major != b.major) return a.major.compareTo(b.major);
  if (a.minor != b.minor) return a.minor.compareTo(b.minor);
  return a.patch.compareTo(b.patch);
}

extension _ListExt<T> on List<T> {
  T? elementAtOrNull(int index) =>
      (index >= 0 && index < length) ? this[index] : null;
}

