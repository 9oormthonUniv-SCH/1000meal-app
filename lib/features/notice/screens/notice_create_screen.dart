import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

import 'package:meal_app/util/colors.dart';
import '../../../common/dio/api_error_mapper.dart';
import '../../../common/dio/api_exception.dart';
import '../../../common/widgets/app_bar_common.dart';
import '../../../common/widgets/app_snackbar.dart';
import '../models/notice_models.dart';
import '../repositories/notice_repository.dart';
import '../viewmodels/notice_list_view_model.dart';

class NoticeCreateScreen extends StatefulWidget {
  static const routeName = '/notice/create';

  const NoticeCreateScreen({super.key});

  @override
  State<NoticeCreateScreen> createState() => _NoticeCreateScreenState();
}

class _NoticeCreateScreenState extends State<NoticeCreateScreen> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _picker = ImagePicker();

  bool _saving = false;
  final List<XFile> _pickedImages = <XFile>[];

  bool get _canSubmit {
    if (_saving) return false;
    return _titleCtrl.text.trim().isNotEmpty && _contentCtrl.text.trim().isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    void onChanged() {
      if (!mounted) return;
      setState(() {});
    }

    _titleCtrl.addListener(onChanged);
    _contentCtrl.addListener(onChanged);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _openImageSourceSheet() async {
    if (_saving) return;
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        Widget item({required IconData icon, required String label, required VoidCallback onTap}) {
          return ListTile(
            leading: Icon(icon, color: const Color(0xFF111827)),
            title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            onTap: onTap,
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(width: 36, height: 4, decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(999))),
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
    return true;
  }

  Future<void> _submit() async {
    if (_saving) return;

    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();
    if (title.isEmpty) {
      AppSnackBar.show(context, '제목을 입력해주세요.');
      return;
    }
    if (content.isEmpty) {
      AppSnackBar.show(context, '내용을 입력해주세요.');
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = context.read<NoticeRepository>();
      final created = await repo.createNotice(
        request: NoticeUpsertRequest(
          title: title,
          content: content,
          isPinned: false,
        ),
      );

      if (!mounted) return;
      final uploadedOk = await _uploadPickedImages(noticeId: created.id);
      if (!mounted) return;
      if (!uploadedOk) {
        // Notice is created already. Guide user to retry via edit flow later.
        AppSnackBar.show(context, '공지 등록은 완료됐지만 이미지 업로드에 실패했어요. 수정에서 다시 첨부해주세요.');
      }
      // Refresh list so user sees the newly created notice immediately.
      await context.read<NoticeListViewModel>().refresh();
      if (!mounted) return;
      Navigator.of(context).maybePop();
    } catch (e) {
      if (!mounted) return;
      final msg = (e is ApiException) ? mapErrorToMessage(e, responseData: e.details) : '공지 등록 실패';
      AppSnackBar.show(context, msg);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                  if (states.contains(WidgetState.disabled)) return const Color(0xFFD9D9D9);
                  return AppColors.orange;
                }),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                overlayColor: WidgetStateProperty.all(
                  const Color(0x1A111827),
                ),
              ),
              child: Text(
                '완료',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                          ),
                        ),
                        child: TextField(
                          controller: _titleCtrl,
                          enabled: !_saving,
                          textInputAction: TextInputAction.next,
                          onChanged: (_) {
                            if (!mounted) return;
                            setState(() {});
                          },
                          decoration: const InputDecoration(
                            hintText: '제목을 입력해주세요',
                            hintStyle: TextStyle(color: Color(0xFFD1D5DB), fontSize: 14),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
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
                          onChanged: (_) {
                            if (!mounted) return;
                            setState(() {});
                          },
                          decoration: const InputDecoration(
                            hintText: '본문을 입력해주세요',
                            hintStyle: TextStyle(color: Color(0xFFD1D5DB), fontSize: 14),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: const TextStyle(fontSize: 14, color: Color(0xFF111827), height: 1.4),
                        ),
                      ),
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: _openImageSourceSheet,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              Icon(Icons.photo_camera_outlined, size: 18, color: Color(0xFF9CA3AF)),
                              SizedBox(width: 8),
                              Text(
                                '사진 첨부하기',
                                style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
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
                                          color: const Color(0xAA111827),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: const Icon(Icons.close, size: 14, color: Colors.white),
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
                    const Text(
                      '이메일 문의: cheonbab@sch.ac.kr',
                      style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () {
                        AppSnackBar.show(context, 'About 화면은 다음 작업에서 연결됩니다.');
                      },
                      child: const Text(
                        'About 오늘손밥',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

