import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:meal_app/util/colors.dart';
import 'package:meal_app/util/typography.dart';

import '../screens/notice_create_screen.dart';
import '../screens/notice_detail_screen.dart';
import '../viewmodels/notice_list_view_model.dart';

class NoticeListSection extends StatefulWidget {
  const NoticeListSection({super.key});

  @override
  State<NoticeListSection> createState() => _NoticeListSectionState();
}

class _NoticeListSectionState extends State<NoticeListSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<NoticeListViewModel>().ensureLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NoticeListViewModel>();

    Widget content;
    if (vm.loading && vm.notices.isEmpty) {
      content = const Center(child: CircularProgressIndicator.adaptive());
    } else if (vm.errorMessage != null && vm.notices.isEmpty) {
      content = Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                vm.errorMessage!,
                textAlign: TextAlign.center,
                style: AppTypography.body4.copyWith(color: AppColors.gray7),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: vm.loading ? null : vm.refresh,
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    } else if (vm.notices.isEmpty) {
      content = Center(
        child: Text(
          '등록된 공지사항이 없습니다.',
          style: AppTypography.body4.copyWith(color: AppColors.gray7),
        ),
      );
    } else {
      content = RefreshIndicator.adaptive(
        onRefresh: vm.refresh,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            0,
            0,
            0,
            16 + (vm.isAdmin ? (kBottomNavigationBarHeight + 96) : 0),
          ),
          itemCount: vm.notices.length,
          itemBuilder: (context, index) {
            final n = vm.notices[index];
            final dateText = (n.createdAt.length >= 10) ? n.createdAt.substring(0, 10) : n.createdAt;
            return Column(
              children: [
                InkWell(
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      NoticeDetailScreen.routeName,
                      arguments: n.id,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (n.isPinned) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.orangeSelected,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '고정',
                              style: AppTypography.caption1.copyWith(
                                fontSize: 11,
                                color: AppColors.orange,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: Text(
                                      n.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.subtitle1.copyWith(
                                        color: AppColors.black,
                                        fontSize: 16,
                                        height: 32 / 16,
                                      ),
                                    ),
                                  ),
                                  if (n.images.isNotEmpty || n.hasImage) ...[
                                    const SizedBox(width: 12),
                                    SvgPicture.asset(
                                      'assets/icon/clip.svg',
                                      width: 18,
                                      height: 18,
                                      colorFilter: const ColorFilter.mode(
                                        AppColors.gray6,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                dateText,
                                style: AppTypography.caption2.copyWith(
                                  color: AppColors.gray7,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  height: 20 / 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Divider(height: 1, thickness: 0.5, color: AppColors.gray7),
                ),
              ],
            );
          },
        ),
      );
    }

    return Stack(
      children: [
        Positioned.fill(child: content),
        if (vm.isAdmin)
          Positioned(
            left: 0,
            right: 0,
            bottom: kBottomNavigationBarHeight,
            child: Center(
              child: Material(
                color: AppColors.white,
                elevation: 2,
                shadowColor: AppColors.black.withValues(alpha: 0.1),
                shape: const StadiumBorder(
                  side: BorderSide(color: AppColors.orange, width: 1),
                ),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: () => Navigator.of(context).pushNamed(NoticeCreateScreen.routeName),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 26,
                          height: 26,
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/icon/write.svg',
                              width: 16,
                              height: 16,
                              colorFilter: const ColorFilter.mode(
                                AppColors.orange,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '글 쓰기',
                          style: AppTypography.body3.copyWith(
                            color: AppColors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

