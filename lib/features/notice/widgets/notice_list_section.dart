import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
                style: const TextStyle(color: Color(0xFF6B7280)),
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
    } else {
      content = RefreshIndicator.adaptive(
        onRefresh: vm.refresh,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            0,
            0,
            0,
            16 + (vm.isAdmin ? (kBottomNavigationBarHeight + 72) : 0),
          ),
          itemCount: vm.notices.length,
          separatorBuilder: (_, index) => const Divider(height: 1, color: Color(0xFFF3F4F6)),
          itemBuilder: (context, index) {
            final n = vm.notices[index];
            final dateText = (n.createdAt.length >= 10) ? n.createdAt.substring(0, 10) : n.createdAt;
            return InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('공지 상세 화면은 다음 작업에서 연결됩니다.')),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (n.isPinned) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEDD5),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          '고정',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFEA580C),
                            height: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            n.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            dateText,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9CA3AF),
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Color(0xFFD1D5DB), size: 22),
                  ],
                ),
              ),
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
            left: 20,
            right: 20,
            bottom: 16 + kBottomNavigationBarHeight,
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('공지 작성 화면은 다음 작업에서 연결됩니다.')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF97316),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  '글쓰기',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

