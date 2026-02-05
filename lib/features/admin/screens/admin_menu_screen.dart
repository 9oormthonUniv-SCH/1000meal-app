import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/utils/week_kst.dart';
import '../models/admin_menu_week.dart';
import 'admin_menu_edit_screen.dart';
import '../viewmodels/admin_menu_view_model.dart';

class AdminMenuScreen extends StatefulWidget {
  static const routeName = '/admin/menu';

  const AdminMenuScreen({super.key});

  @override
  State<AdminMenuScreen> createState() => _AdminMenuScreenState();
}

class _AdminMenuScreenState extends State<AdminMenuScreen> {
  final _scroll = ScrollController();
  bool _loaded = false;
  final Map<String, GlobalKey> _weekKeys = <String, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    final vm = context.read<AdminMenuViewModel>();
    if (!_scroll.hasClients) return;
    if (_scroll.position.extentAfter < 300) {
      vm.loadNextWeek();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AdminMenuViewModel>().init());
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminMenuViewModel>();

    return WillPopScope(
      onWillPop: () async {
        if (!mounted) return true;
        Navigator.of(context).pushNamedAndRemoveUntil('/admin', (r) => false);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
        toolbarHeight: 48,
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('메뉴 관리', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
          onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/admin', (r) => false),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: () => Navigator.of(context).pushNamed('/admin/menu/frequent'),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFFB923C), // orange-400
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('자주 쓰는 메뉴', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1)),
            ),
          ),
        ],
        ),
        body: Container(
        color: const Color(0xFFF7F7F7), // stone-50
        child: Column(
          children: [
            if (vm.groups.length > 1)
              Container(
                width: double.infinity,
                height: 48,
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final g in vm.groups) ...[
                        _GroupChip(
                          label: g.name,
                          selected: vm.selectedGroupId == g.id,
                          onTap: () => context.read<AdminMenuViewModel>().selectGroup(g.id),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
              ),
            if (vm.groups.length > 1) const Divider(height: 1, thickness: 1, color: Color(0xFFFAFAF9)),
            Expanded(
              child: vm.loading && vm.weeks.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator.adaptive(
                      onRefresh: () async {
                        if (vm.weeks.isEmpty) return;
                        final inserted = await vm.loadPrevWeek();

                        // 요구사항: 갱신(이전 주 추가) 후 새로 갱신된 메뉴가 레이아웃 최상단에 위치
                        if (inserted && _scroll.hasClients) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!_scroll.hasClients) return;
                            _scroll.animateTo(
                              0,
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOut,
                            );
                          });
                        }
                      },
                      child: ListView.builder(
                        controller: _scroll,
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                        itemCount: vm.weeks.length + 1,
                        itemBuilder: (context, idx) {
                          if (idx == vm.weeks.length) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: vm.loadingNext
                                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                    : const SizedBox.shrink(),
                              ),
                            );
                          }

                          final week = vm.weeks[idx];
                          final monday = mondayOfYmd(week.first.id);
                          final key = _weekKeys.putIfAbsent(monday, () => GlobalKey());
                          return KeyedSubtree(
                            key: key,
                            child: _WeekCard(
                              week: week,
                              onTapDay: (ymd) {
                                final groupId = vm.selectedGroupId;
                                if (groupId == null) return;
                                Navigator.of(context).pushNamed(
                                  AdminMenuEditScreen.routeName,
                                  arguments: {'date': ymd, 'groupId': groupId},
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
            ),
            if (vm.errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: const Color(0xFFFFF1F2),
                child: Text(vm.errorMessage!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
              ),
          ],
        ),
      ),
      ),
    );
  }

}

class _GroupChip extends StatelessWidget {
  const _GroupChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFB923C) : const Color(0xFFF4F4F5), // orange-400 / zinc-100
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1,
            color: selected ? Colors.white : const Color(0xFF27272A), // zinc-800
          ),
        ),
      ),
    );
  }
}

class _WeekCard extends StatelessWidget {
  final List<AdminMenuDay> week;
  final ValueChanged<String> onTapDay;

  const _WeekCard({required this.week, required this.onTapDay});

  @override
  Widget build(BuildContext context) {
    const line = Color(0xFFD9D9D9); // zinc-300 (figma)
    final hairline = 1 / MediaQuery.of(context).devicePixelRatio;

    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // left date column (w-12)
          SizedBox(
            width: 48,
            child: Column(
              children: [
                for (int i = 0; i < week.length; i++)
                  Opacity(
                    opacity: week[i].isPast ? 0.4 : 1.0,
                    child: Container(
                      height: 48,
                      alignment: Alignment.center,
                      child: Text(
                        week[i].dateLabel,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: week[i].isToday ? const Color(0xFFFB923C) : const Color(0xFF737373), // orange-400 / neutral-500
                          fontSize: 14,
                          fontWeight: week[i].isToday ? FontWeight.w600 : FontWeight.w400,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // right day/summary column (w-72)
          Expanded(
            child: Stack(
              children: [
                Column(
                  children: [
                    for (int i = 0; i < week.length; i++)
                      Opacity(
                        opacity: week[i].isPast ? 0.4 : 1.0,
                        child: InkWell(
                          onTap: () => onTapDay(week[i].id),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(i == 0 ? 16 : 0),
                            topRight: Radius.circular(i == 0 ? 16 : 0),
                            bottomLeft: Radius.circular(i == week.length - 1 ? 16 : 0),
                            bottomRight: Radius.circular(i == week.length - 1 ? 16 : 0),
                          ),
                          child: Container(
                            height: 48,
                            
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(i == 0 ? 16 : 0),
                                topRight: Radius.circular(i == 0 ? 16 : 0),
                                bottomLeft: Radius.circular(i == week.length - 1 ? 16 : 0),
                                bottomRight: Radius.circular(i == week.length - 1 ? 16 : 0),
                              ),
                            ),
                            child: Stack(
                              children: [
                                // bottom divider (except last)
                                if (i != week.length - 1)
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    bottom: 0,
                                    child: SizedBox(
                                      height: hairline,
                                      child: const DecoratedBox(decoration: BoxDecoration(color: line)),
                                    ),
                                  ),
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 48,
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 19),
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            week[i].weekdayLabel,
                                            style: const TextStyle(
                                              color: Color(0xFF737373), // neutral-500
                                              fontSize: 14,
                                              fontWeight: FontWeight.w400,
                                              height: 1,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: hairline), // divider 공간(실선은 Stack이 그림)
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 12, right: 8),
                                        child: Text(
                                          week[i].items.isNotEmpty ? week[i].items.join(', ') : '',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            height: 1,
                                            color: week[i].items.isNotEmpty ? const Color(0xFF111827) : const Color(0xFF9CA3AF),
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.only(right: 10),
                                      child: Icon(Icons.chevron_right, color: Color(0xFFA3A3A3), size: 20),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                // ✅ 요일(48px) ↔ 메뉴 영역 사이 세로 구분선 (전체 높이)
                Positioned(
                  left: 48,
                  top: 0,
                  bottom: 0,
                  child: SizedBox(
                    width: hairline,
                    child: const DecoratedBox(decoration: BoxDecoration(color: line)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

