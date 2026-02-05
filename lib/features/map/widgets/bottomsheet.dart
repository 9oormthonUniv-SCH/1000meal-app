import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../store/models/store_models.dart';
import '../../store/screens/store_detail_screen.dart';

const double kStoreBottomSheetHeight = 317;

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
    final isOpen = store.open ?? false;
    final statusColor = isOpen
        ? const Color(0xFFF97316)
        : const Color(0xFF9CA3AF);
    final statusText = isOpen ? '영업 중' : '영업 종료';
    final menusText = store.menus.isNotEmpty
        ? store.menus.join(', ')
        : '메뉴 정보 없음';

    return SafeArea(
      top: false,
      child: SizedBox(
        height: kStoreBottomSheetHeight,
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
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    StoreDetailScreen(storeId: store.id),
                              ),
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                store
                                    .name, //ontap() -> Navigator to StoreDetailScreen
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  if (kDebugMode) debugPrint('즐겨찾기');
                                  //즐겨찾기 클릭 시 아이콘 변경 로직 + 즐겨찾기 리스트에 포함되도록 하는 로직 들어가야 함.
                                },
                                icon: Icon(Icons.star, color: Colors.grey[400]),
                                highlightColor: Colors.orange.withOpacity(0.2),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if ((store.address ?? '').isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      store.address!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF767676),
                      ),
                    ),
                  ],
                  if ((store.phone ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${store.phone}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF767676),
                      ),
                    ),
                  ],
                  const SizedBox(height: 25),
                  Text(
                    //영업 중 or 영업 종료
                    statusText,
                    style: TextStyle(color: statusColor, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  if ((store.hours ?? '').isNotEmpty) ...[
                    Text(
                      '천원의 아침밥 운영 시간: ${store.hours!}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF767676),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 105,
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 13, 20, 20),
              decoration: const BoxDecoration(color: Color(0xFFF97316)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '오늘의 천밥',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        //const SizedBox(height: 6),
                        Text(
                          menusText,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 5),
                  Padding(
                    padding: const EdgeInsets.only(right: 3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 5),
                          child: Text(
                            ' ${store.remain}개 ',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          '남았어요!',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
