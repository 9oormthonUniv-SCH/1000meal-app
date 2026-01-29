import 'package:flutter/material.dart';

import '../../store/models/store_models.dart';

Future<void> showStoreBottomSheet(BuildContext context, StoreListItem store) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
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

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    store.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  statusText,
                  style: TextStyle(color: statusColor, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '잔여 수량: ${store.remain}개',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 12),
            const Text(
              '오늘의 천밥',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            for (final menu in store.menus)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• $menu',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF374151),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
