import 'package:flutter/material.dart';
import 'package:meal_app/util/colors.dart';
import 'package:meal_app/util/typography.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import './_favorite_button.dart';
import '../../store/models/store_models.dart';
import '../../store/screens/store_detail_screen.dart';
import '../../store/viewmodels/store_list_view_model.dart';

/// 단일 그룹일 때와 다중 그룹일 때 레이아웃이 달라져 높이 가변 (피그마: 단일 h-80, 다중 h-96)
const double kStoreBottomSheetHeightBase = 317;
const double kStoreBottomSheetRowHeight = 40;

/// 맵 화면에서 새로고침 버튼 위치 계산용 (다중 그룹 시 시트가 더 높아지므로 여유값 사용)
const double kStoreBottomSheetHeight = 400;

double storeBottomSheetHeight(StoreListItem store) {
  final groups = store.menuGroups;
  if (groups.length <= 1) return kStoreBottomSheetHeightBase;
  return kStoreBottomSheetHeightBase +
      (groups.length - 1) * kStoreBottomSheetRowHeight;
}

Future<void> showStoreBottomSheet(BuildContext context, StoreListItem store) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.white,
    barrierColor: Colors.transparent,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => StoreBottomSheet(store: store),
  );
}

class StoreBottomSheet extends StatelessWidget {
  final StoreListItem store;

  const StoreBottomSheet({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StoreListViewModel>();
    final currentStore = vm.items.firstWhere(
      (s) => s.id == store.id,
      orElse: () => store,
    );
    final isOpen = currentStore.open ?? false;
    final statusColor = isOpen ? AppColors.orange : AppColors.gray6;
    final statusText = isOpen ? '영업 중' : '영업 종료';
    final groups = currentStore.menuGroups;
    final isMultiGroup = groups.length >= 2;
    final tm = currentStore.todayMenu;
    final sortedGroups = List<TodayMenuGroup>.from(groups)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final singleGroup = sortedGroups.length <= 1;
    final menuFallback = isOpen ? '메뉴 정보 없음' : '오늘 휴무';

    final hasPhone =
        (currentStore.phone ?? '').trim().isNotEmpty &&
        currentStore.phone != '010-0000-0000';
    final bottomHeight = storeBottomSheetHeight(currentStore);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      top: false,
      bottom: false,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: bottomHeight + bottomInset,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppColors.gray3,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    StoreDetailScreen(storeId: currentStore.id),
                              ),
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  currentStore.name,
                                  style: AppTypography.headline4.copyWith(
                                    fontSize: 18,
                                    height: 28 / 18,
                                    color: AppColors.black,
                                  ),
                                ),
                              ),
                              FavoriteButton(store: currentStore),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if ((currentStore.address ?? '').isNotEmpty) ...[
                    Text(
                      currentStore.address!,
                      style: AppTypography.caption2.copyWith(
                        color: AppColors.gray7,
                        height: 20 / 16,
                      ),
                    ),
                  ],
                  if (hasPhone) ...[
                    GestureDetector(
                      onTap: () =>
                          launchUrl(Uri.parse('tel:${currentStore.phone}')),
                      child: Text(
                        '📞 ${currentStore.phone}',
                        style: AppTypography.caption2.copyWith(
                          color: AppColors.gray7,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 4),
                    Text(
                      '전화번호 미등록',
                      style: AppTypography.caption2.copyWith(color: AppColors.gray6),
                    ),
                  ],
                  const SizedBox(height: 25),
                  Text(
                    statusText,
                    style: AppTypography.caption1.copyWith(
                      color: statusColor,
                      fontSize: 12,
                      height: 20 / 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if ((currentStore.hours ?? '').isNotEmpty)
                    Text(
                      currentStore.hours!,
                      style: AppTypography.caption2.copyWith(color: AppColors.gray7),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                decoration: const BoxDecoration(color: AppColors.orange),
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '오늘의 천밥',
                        style: AppTypography.subtitle1.copyWith(
                          color: AppColors.white,
                          fontSize: 16,
                          height: 32 / 16,
                        ),
                      ),
                      if (tm == null) ...[
                        const SizedBox(height: 4),
                        Text(
                          menuFallback,
                          style: AppTypography.body4.copyWith(
                            color: AppColors.white,
                            fontSize: 14,
                            height: 20 / 14,
                          ),
                        ),
                      ] else if (singleGroup) ...[
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                currentStore.singleGroupMenusText.isEmpty
                                    ? menuFallback
                                    : currentStore.singleGroupMenusText,
                                style: AppTypography.body4.copyWith(
                                  color: AppColors.white,
                                  fontSize: 14,
                                  height: 20 / 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${currentStore.firstGroupStock}개',
                                  style: AppTypography.body3.copyWith(
                                    color: AppColors.white,
                                    fontSize: 14,
                                    height: 20 / 14,
                                  ),
                                ),
                                Text(
                                  '남았어요!',
                                  style: AppTypography.caption2.copyWith(
                                    color: AppColors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ] else ...[
                        const SizedBox(height: 8),
                        ...sortedGroups.map(
                          (group) => _MapStoreCardGroupRow(group: group),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

class _MapStoreCardGroupRow extends StatelessWidget {
  final TodayMenuGroup group;

  const _MapStoreCardGroupRow({required this.group});

  @override
  Widget build(BuildContext context) {
    final menuText = group.menus.isNotEmpty
        ? group.menus.map((m) => m.name).join(', ')
        : '—';
    final stock = group.stock;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 6, right: 16),
                  child: SizedBox(
                    width: 6,
                    height: 6,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    menuText.isEmpty ? '—' : menuText,
                    style: AppTypography.body4.copyWith(
                      color: AppColors.white,
                      fontSize: 14,
                      height: 20 / 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${stock}개',
                style: AppTypography.body3.copyWith(
                  color: AppColors.white,
                  fontSize: 14,
                  height: 20 / 14,
                ),
              ),
              Text(
                '남았어요!',
                style: AppTypography.caption2.copyWith(color: AppColors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
