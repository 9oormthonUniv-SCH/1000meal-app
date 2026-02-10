import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

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
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
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
                color: Colors.white,
                elevation: 2,
                shadowColor: const Color(0x1A000000),
                shape: const StadiumBorder(
                  side: BorderSide(color: Color(0xFFF97316), width: 1),
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
                                Color(0xFFF97316),
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          '글 쓰기',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF374151),
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

