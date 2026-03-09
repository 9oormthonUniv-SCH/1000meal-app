import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

import '../../../common/dio/api_error_mapper.dart';
import '../../../common/dio/api_exception.dart';
import '../../../common/widgets/app_bar_common.dart';
import '../../../common/widgets/app_snackbar.dart';
import '../../../util/colors.dart';
import '../../../util/typography.dart';
import '../models/notice_models.dart';
import '../repositories/notice_repository.dart';
import '../viewmodels/notice_list_view_model.dart';

class NoticeEditScreen extends StatefulWidget {
  static const routeName = '/notice/edit';

  final int noticeId;

  const NoticeEditScreen({super.key, required this.noticeId});

  @override
  State<NoticeEditScreen> createState() => _NoticeEditScreenState();
}

class _NoticeEditScreenState extends State<NoticeEditScreen> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _picker = ImagePicker();

  bool _loading = false;
  bool _saving = false;
  String? _errorMessage;
  final List<XFile> _pickedImages = <XFile>[];

  bool get _canSubmit {
    if (_saving || _loading) return false;
    return _titleCtrl.text.trim().isNotEmpty && _contentCtrl.text.trim().isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final repo = context.read<NoticeRepository>();
      final n = await repo.getNotice(id: widget.noticeId);
      if (!mounted) return;
      _titleCtrl.text = n.title;
      _contentCtrl.text = n.content;
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      final msg = (e is ApiException) ? mapErrorToMessage(e, responseData: e.details) : '공지 불러오기 실패';
      setState(() => _errorMessage = msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _saving = true);
    try {
      final repo = context.read<NoticeRepository>();
      await repo.updateNotice(
        id: widget.noticeId,
        request: NoticeUpsertRequest(
          title: _titleCtrl.text.trim(),
          content: _contentCtrl.text.trim(),
          isPinned: false,
        ),
      );

      final uploadedOk = await _uploadPickedImages(noticeId: widget.noticeId);
      if (!mounted) return;
      if (!uploadedOk) {
        // keep screen; user can retry
        setState(() => _saving = false);
        return;
      }

      if (!mounted) return;
      try {
        await context.read<NoticeListViewModel>().refresh();
      } catch (_) {
        // ignore
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      final msg = (e is ApiException) ? mapErrorToMessage(e, responseData: e.details) : '수정 실패';
      AppSnackBar.show(context, msg);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openImageSourceSheet() async {
    if (_saving) return;
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        Widget item({required IconData icon, required String label, required VoidCallback onTap}) {
          return ListTile(
            leading: Icon(icon, color: AppColors.black),
            title: Text(label, style: AppTypography.subtitle1),
            onTap: onTap,
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.gray3, borderRadius: BorderRadius.circular(999))),
              const SizedBox(height: 8),
              item(
                icon: Icons.photo_library_outlined,
                label: '갤러리에서 선택',
                onTap: () async {
                  Navigator.of(context).pop();
                  final images = await _picker.pickMultiImage(imageQuality: 90);
                  if (!mounted) return;
                  if (images.isEmpty) return;
                  setState(() {
                    _pickedImages.addAll(images);
                    if (_pickedImages.length > 5) _pickedImages.removeRange(5, _pickedImages.length);
                  });
                  if (images.length > 5) {
                    AppSnackBar.show(this.context, '이미지는 최대 5장까지 첨부할 수 있어요.');
                  }
                },
              ),
              item(
                icon: Icons.photo_camera_outlined,
                label: '카메라로 촬영',
                onTap: () async {
                  Navigator.of(context).pop();
                  final image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 90);
                  if (!mounted) return;
                  if (image == null) return;
                  setState(() {
                    if (_pickedImages.length < 5) {
                      _pickedImages.add(image);
                    }
                  });
                  if (_pickedImages.length >= 5) {
                    AppSnackBar.show(this.context, '이미지는 최대 5장까지 첨부할 수 있어요.');
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _uploadPickedImages({required int noticeId}) async {
    if (_pickedImages.isEmpty) return true;

    final repo = context.read<NoticeRepository>();
    final fileRequests = <NoticePresignFileRequest>[];
    for (final x in _pickedImages) {
      final name = p.basename(x.path);
      final mime = x.mimeType ?? lookupMimeType(x.path) ?? 'image/jpeg';
      final size = await x.length();
      fileRequests.add(NoticePresignFileRequest(originalName: name, contentType: mime, size: size));
    }

    final presigns = await repo.presignNoticeImages(
      id: noticeId,
      request: NoticePresignRequest(files: fileRequests),
    );
    if (presigns.length != _pickedImages.length) {
      throw ApiException('이미지 업로드 준비에 실패했습니다.');
    }

    final successes = <NoticeImagesUpsertItem>[];
    final failures = <String>[];

    for (var i = 0; i < presigns.length; i++) {
      final presign = presigns[i];
      final file = _pickedImages[i];
      try {
        final bytes = await file.readAsBytes();
        final headers = {...presign.headers};
        headers.putIfAbsent('Content-Type', () => presign.contentType);
        await repo.uploadToPresignedUrl(uploadUrl: presign.uploadUrl, bytes: bytes, headers: headers, method: presign.method);
        successes.add(
          NoticeImagesUpsertItem(
            s3Key: presign.s3Key,
            url: presign.url,
            originalName: presign.originalName,
            contentType: presign.contentType,
            size: presign.size,
          ),
        );
      } catch (e) {
        if (kDebugMode) {
          final code = e is ApiException ? e.statusCode : null;
          final body = e is ApiException ? e.details : null;
          debugPrint('[S3 업로드 실패] originalName=${presign.originalName} statusCode=$code details=$body message=$e');
        }
        failures.add(presign.originalName);
      }
    }

    if (successes.isNotEmpty) {
      try {
        await repo.registerNoticeImages(
          id: noticeId,
          request: NoticeImagesUpsertRequest(images: successes),
        );
      } catch (e) {
        if (kDebugMode) {
          final code = e is ApiException ? e.statusCode : null;
          final body = e is ApiException ? e.details : null;
          debugPrint('[이미지 등록 API 실패] statusCode=$code details=$body message=$e');
        }
        if (!mounted) return false;
        AppSnackBar.show(context, '이미지 등록(서버 저장)에 실패했어요. 다시 시도해주세요.');
        return false;
      }
    }

    if (failures.isNotEmpty) {
      if (!mounted) return false;
      AppSnackBar.show(context, '일부 이미지 업로드 실패: ${failures.take(2).join(', ')}${failures.length > 2 ? ' 외 ${failures.length - 2}개' : ''}');
      return false;
    }
    setState(() => _pickedImages.clear());
    return true;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = _loading && _errorMessage == null
        ? const Center(child: CircularProgressIndicator.adaptive())
        : _errorMessage != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: AppTypography.body4.copyWith(color: AppColors.gray7),
                      ),
                      const SizedBox(height: 12),
                      TextButton(onPressed: _load, child: const Text('다시 시도')),
                    ],
                  ),
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: AppColors.gray7, width: 0.5),
                              ),
                            ),
                            child: TextField(
                              controller: _titleCtrl,
                              enabled: !_saving,
                              textInputAction: TextInputAction.next,
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                hintText: '제목을 입력해주세요',
                                hintStyle: AppTypography.body4.copyWith(color: AppColors.gray5),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: AppTypography.headline5.copyWith(color: AppColors.black),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 260,
                            child: TextField(
                              controller: _contentCtrl,
                              enabled: !_saving,
                              keyboardType: TextInputType.multiline,
                              maxLines: null,
                              expands: true,
                              textAlignVertical: TextAlignVertical.top,
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                hintText: '본문을 입력해주세요',
                                hintStyle: AppTypography.body4.copyWith(color: AppColors.gray5),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: AppTypography.body4.copyWith(color: AppColors.black, height: 1.4),
                            ),
                          ),
                          const SizedBox(height: 10),
                          InkWell(
                            onTap: _openImageSourceSheet,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                children: [
                                  Icon(Icons.photo_camera_outlined, size: 18, color: AppColors.gray6),
                                  const SizedBox(width: 8),
                                  Text(
                                    '사진 첨부하기',
                                    style: AppTypography.caption1.copyWith(color: AppColors.gray6),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_pickedImages.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 74,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _pickedImages.length,
                                separatorBuilder: (_, index) => const SizedBox(width: 10),
                                itemBuilder: (context, index) {
                                  final f = _pickedImages[index];
                                  return Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(
                                          File(f.path),
                                          width: 74,
                                          height: 74,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        top: 6,
                                        right: 6,
                                        child: InkWell(
                                          onTap: _saving
                                              ? null
                                              : () => setState(() {
                                                    _pickedImages.removeAt(index);
                                                  }),
                                          child: Container(
                                            width: 20,
                                            height: 20,
                                            decoration: BoxDecoration(
                                              color: AppColors.black.withValues(alpha: 0.67),
                                              borderRadius: BorderRadius.circular(999),
                                            ),
                                            child: Icon(Icons.close, size: 14, color: AppColors.white),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '이메일 문의: jeong01101095@gmail.com',
                          style: AppTypography.caption2.copyWith(color: AppColors.gray7),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () {
                            AppSnackBar.show(context, 'About 화면은 다음 작업에서 연결됩니다.');
                          },
                          child: Text(
                            'About 오늘손밥',
                            style: AppTypography.caption2.copyWith(
                              color: AppColors.gray7,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBarCommon(
        title: '글쓰기',
        centerTitle: true,
        backEnabled: !_saving,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: TextButton(
              onPressed: _canSubmit ? _submit : null,
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.disabled)) return AppColors.gray4;
                  return AppColors.orange;
                }),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                overlayColor: WidgetStateProperty.all(
                  AppColors.black.withValues(alpha: 0.1),
                ),
              ),
              child: Text(
                '완료',
                style: AppTypography.body3.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(child: body),
    );
  }
}

