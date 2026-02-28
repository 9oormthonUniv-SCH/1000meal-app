import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import './_favorite_button.dart';
import '../../store/models/store_models.dart';
import '../../store/screens/store_detail_screen.dart';
import '../../store/viewmodels/store_list_view_model.dart';

/// 단일 그룹일 때와 다중 그룹일 때 레이아웃이 달라져 높이 가변 (대략 기준)
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
    backgroundColor: Colors.white,
    barrierColor: Colors.transparent,
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
    final statusColor = isOpen
        ? const Color(0xFFF97316)
        : const Color(0xFF9CA3AF);
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

    return SafeArea(
      top: false,
      bottom: false,
      child: SizedBox(
        height: bottomHeight,
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
                      width: 48,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
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
                              IntrinsicWidth(
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Text(
                                      currentStore.name,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                    Positioned(
                                      left: 0,
                                      right: 0,
                                      bottom: 0,
                                      child: Transform.translate(
                                        offset: const Offset(0, -2),
                                        child: Container(
                                          height: 1.1,
                                          color: const Color(0xFF111827),
                                        ),
                                      ),
                                    ),
                                  ],
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
                    const SizedBox(height: 12),
                    Text(
                      currentStore.address!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF767676),
                      ),
                    ),
                  ],
                  if (hasPhone) ...[
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () =>
                          launchUrl(Uri.parse('tel:${currentStore.phone}')),
                      child: Text(
                        '📞 ${currentStore.phone}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF767676),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 4),
                    const Text(
                      '전화번호 미등록',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if ((currentStore.hours ?? '').isNotEmpty)
                    Text(
                      currentStore.hours!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF767676),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                decoration: const BoxDecoration(color: Color(0xFFF97316)),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '오늘의 천밥',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      if (tm == null) ...[
                        const SizedBox(height: 4),
                        Text(
                          menuFallback,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
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
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white,
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
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const Text(
                                  '남았어요!',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white,
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
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 6, right: 8),
                  child: SizedBox(
                    width: 6,
                    height: 6,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    menuText.isEmpty ? '—' : menuText,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
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
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const Text(
                '남았어요!',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
