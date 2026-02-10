import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/dio/api_error_mapper.dart';
import '../../../common/dio/api_exception.dart';
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

  bool _loading = false;
  bool _saving = false;
  String? _errorMessage;

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
                        style: const TextStyle(color: Color(0xFF6B7280)),
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
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                              ),
                            ),
                            child: TextField(
                              controller: _titleCtrl,
                              enabled: !_saving,
                              textInputAction: TextInputAction.next,
                              onChanged: (_) => setState(() {}),
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
                              onChanged: (_) => setState(() {}),
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
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('사진 첨부는 다음 작업에서 연결됩니다.')),
                              );
                            },
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('About 화면은 다음 작업에서 연결됩니다.')),
                            );
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
              );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          '글쓰기',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF111827)),
          onPressed: _saving ? null : () => Navigator.of(context).maybePop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: TextButton(
              onPressed: _canSubmit ? _submit : null,
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.disabled)) return const Color(0xFFD9D9D9);
                  return const Color(0xFFFF6E3F);
                }),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                ),
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                overlayColor: WidgetStateProperty.all(
                  const Color(0x1A111827),
                ),
              ),
              child: const Text(
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
      body: SafeArea(child: body),
    );
  }
}

