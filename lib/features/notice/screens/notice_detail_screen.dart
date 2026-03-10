import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:meal_app/util/colors.dart';
import 'package:meal_app/util/typography.dart';

import '../../../common/dio/api_error_mapper.dart';
import '../../../common/dio/api_exception.dart';
import '../../../common/utils/external_link.dart';
import '../../../common/widgets/app_bar_common.dart';
import '../../../common/widgets/app_confirm_dialog.dart';
import '../../../common/widgets/app_snackbar.dart';
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

    final ok = await AppConfirmDialog.showDelete(
      context,
      content: '이 동작은 취소할 수 없습니다\n삭제하시겠습니까?',
      cancelLabel: '아니요',
      confirmLabel: '삭제',
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
      AppSnackBar.show(context, '삭제되었습니다.');
    } catch (e) {
      if (!mounted) return;
      final msg = (e is ApiException) ? mapErrorToMessage(e, responseData: e.details) : '삭제 실패';
      AppSnackBar.show(context, msg);
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
            backgroundColor: AppColors.gray4,
            foregroundColor: AppColors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 18),
          ),
          child: Text(text, style: AppTypography.body3.copyWith(color: AppColors.white)),
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
                style: AppTypography.body4.copyWith(color: AppColors.gray7),
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
      final images = n?.images ?? const <NoticeImage>[];

      body = CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 10),
                Text(
                  title,
                  style: AppTypography.subtitle1.copyWith(
                    color: AppColors.gray7,
                    fontSize: 16,
                    height: 32 / 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  dateText,
                  style: AppTypography.caption2.copyWith(
                    color: AppColors.gray7,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 20 / 14,
                  ),
                ),
                const SizedBox(height: 14),
                Divider(height: 1, thickness: 0.5, color: AppColors.gray7),
                if (images.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ...List.generate(images.length, (i) {
                    final img = images[i];
                    return Padding(
                      padding: EdgeInsets.only(bottom: i == images.length - 1 ? 0 : 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Image.network(
                              img.url,
                              fit: BoxFit.contain,
                              width: constraints.maxWidth,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: AppColors.background,
                                alignment: Alignment.center,
                                child: Text(
                                  '이미지를 불러올 수 없습니다.',
                                  style: AppTypography.caption2.copyWith(color: AppColors.gray7),
                                ),
                              ),
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: AppColors.background,
                                  alignment: Alignment.center,
                                  child: const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                ] else ...[
                  const SizedBox(height: 16),
                ],
                Text(
                  content,
                  style: AppTypography.body4.copyWith(
                    color: AppColors.gray7,
                    fontSize: 14,
                    height: 20 / 14,
                  ),
                ),
                _adminButtons(isAdmin: isAdmin),
                const SizedBox(height: 40),
              ]),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '이메일 문의: jeong01101095@gmail.com',
                    style: AppTypography.caption2.copyWith(color: AppColors.gray7),
                  ),
                  const SizedBox(height: 2),
                  InkWell(
                    onTap: () => openExternalUrl('https://1000meal.store'),
                    child: Text(
                      'About 오늘순밥',
                      style: AppTypography.caption2.copyWith(
                        color: AppColors.gray7,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const AppBarCommon(
        title: '',
      ),
      body: SafeArea(child: body),
    );
  }
}

