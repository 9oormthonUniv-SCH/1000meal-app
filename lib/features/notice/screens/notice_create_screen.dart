import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/dio/api_error_mapper.dart';
import '../../../common/dio/api_exception.dart';
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

  bool _saving = false;

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

  Future<void> _submit() async {
    if (_saving) return;

    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('제목을 입력해주세요.')));
      return;
    }
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('내용을 입력해주세요.')));
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = context.read<NoticeRepository>();
      await repo.createNotice(
        request: NoticeUpsertRequest(
          title: title,
          content: content,
          isPinned: false,
        ),
      );

      if (!mounted) return;
      // Refresh list so user sees the newly created notice immediately.
      await context.read<NoticeListViewModel>().refresh();
      if (!mounted) return;
      Navigator.of(context).maybePop();
    } catch (e) {
      if (!mounted) return;
      final msg = (e is ApiException) ? mapErrorToMessage(e, responseData: e.details) : '공지 등록 실패';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          ),
        ),
      ),
    );
  }
}

