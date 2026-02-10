import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/dio/api_error_mapper.dart';
import '../../../common/dio/api_exception.dart';
import '../models/notice_models.dart';
import '../repositories/notice_repository.dart';
import '../viewmodels/notice_list_view_model.dart';
import 'notice_edit_screen.dart';

class NoticeDetailScreen extends StatefulWidget {
  static const routeName = '/notice/detail';

  final int noticeId;

  const NoticeDetailScreen({super.key, required this.noticeId});

  @override
  State<NoticeDetailScreen> createState() => _NoticeDetailScreenState();
}

class _NoticeDetailScreenState extends State<NoticeDetailScreen> {
  bool _loading = false;
  String? _errorMessage;
  Notice? _notice;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // Keep admin gating consistent with notice list/write button.
      await context.read<NoticeListViewModel>().ensureLoaded();
      if (!mounted) return;
      await _load();
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final noticeRepo = context.read<NoticeRepository>();
      final notice = await noticeRepo.getNotice(id: widget.noticeId);

      if (!mounted) return;
      setState(() {
        _notice = notice;
      });
    } catch (e) {
      if (!mounted) return;
      final msg = (e is ApiException) ? mapErrorToMessage(e, responseData: e.details) : '공지 불러오기 실패';
      setState(() => _errorMessage = msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmDelete() async {
    final isAdmin = context.read<NoticeListViewModel>().isAdmin;
    if (!isAdmin) return;

    final n = _notice;
    if (n == null) return;

    final repo = context.read<NoticeRepository>();
    NoticeListViewModel? listVm;
    try {
      listVm = context.read<NoticeListViewModel>();
    } catch (_) {
      listVm = null;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('공지 삭제'),
        content: const Text('정말 삭제할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제', style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!mounted) return;

    try {
      await repo.deleteNotice(id: n.id);
      if (!mounted) return;

      // Refresh list (best-effort)
      if (listVm != null) await listVm.refresh();

      if (!mounted) return;
      Navigator.of(context).maybePop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('삭제되었습니다.')));
    } catch (e) {
      if (!mounted) return;
      final msg = (e is ApiException) ? mapErrorToMessage(e, responseData: e.details) : '삭제 실패';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _goEdit() async {
    final isAdmin = context.read<NoticeListViewModel>().isAdmin;
    if (!isAdmin) return;

    final n = _notice;
    if (n == null) return;
    final updated = await Navigator.of(context).pushNamed(
      NoticeEditScreen.routeName,
      arguments: n.id,
    );
    if (!mounted) return;
    if (updated == true) {
      await _load();
    }
  }

  Widget _adminButtons({required bool isAdmin}) {
    if (!isAdmin) return const SizedBox.shrink();

    Widget button({required String text, required VoidCallback onTap}) {
      return SizedBox(
        height: 40,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD9D9D9),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 18),
          ),
          child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Row(
        children: [
          button(text: '삭제', onTap: _confirmDelete),
          const SizedBox(width: 12),
          button(text: '수정', onTap: _goEdit),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final n = _notice;
    final isAdmin = context.watch<NoticeListViewModel>().isAdmin;

    Widget body;
    if (_loading && n == null) {
      body = const Center(child: CircularProgressIndicator.adaptive());
    } else if (_errorMessage != null && n == null) {
      body = Center(
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
      );
    } else {
      final title = n?.title ?? '';
      final dateText = (n?.createdAt ?? '').length >= 10 ? (n!.createdAt.substring(0, 10)) : (n?.createdAt ?? '');
      final content = n?.content ?? '';

      // Use a single scrollable ListView to avoid semantics/layout edge cases
      // during route transitions.
      body = ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
        children: [
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B7280),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            dateText,
            style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF), height: 1.0),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 16),
          Text(
            content,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.6),
          ),
          _adminButtons(isAdmin: isAdmin),
          const SizedBox(height: 40),
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
          const SizedBox(height: 24),
        ],
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF111827)),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const SizedBox.shrink(),
      ),
      body: SafeArea(child: body),
    );
  }
}

