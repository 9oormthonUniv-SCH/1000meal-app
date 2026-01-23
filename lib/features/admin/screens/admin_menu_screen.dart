import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/utils/week_kst.dart';
import '../models/admin_menu_week.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('메뉴 관리'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/admin', (r) => false),
        ),
      ),
      body: Container(
        color: const Color(0xFFF5F6F7),
        child: Column(
          children: [
            // "헤더로 취급"되는 영역: ActionBar까지 포함
            _ActionBar(
              onTapCalendar: () => _toast(context, '다음 단계에서 구현 예정'),
              onTapFrequent: () => _toast(context, '다음 단계에서 구현 예정'),
            ),

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
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
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
                              onTapDay: (ymd) => _toast(context, '메뉴 수정 화면은 다음 단계에서 구현 예정 ($ymd)'),
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
    );
  }

  static void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), duration: const Duration(milliseconds: 900)));
  }
}

class _ActionBar extends StatelessWidget {
  final VoidCallback onTapCalendar;
  final VoidCallback onTapFrequent;

  const _ActionBar({required this.onTapCalendar, required this.onTapFrequent});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: onTapCalendar,
            icon: const Icon(Icons.calendar_today, size: 18, color: Color(0xFF4B5563)),
            label: const Text('다른 주 보기', style: TextStyle(color: Color(0xFF4B5563))),
          ),
          TextButton(
            onPressed: onTapFrequent,
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFF97316),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            child: const Text('자주 쓰는 메뉴', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          for (int i = 0; i < week.length; i++) ...[
            _DayRow(day: week[i], onTap: () => onTapDay(week[i].id)),
            if (i != week.length - 1) const Divider(height: 1, color: Color(0xFFE5E7EB)),
          ],
        ],
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  final AdminMenuDay day;
  final VoidCallback onTap;

  const _DayRow({required this.day, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final summary = day.items.isNotEmpty ? day.items.join(', ') : '메뉴 없음';
    final opacity = day.isPast ? 0.4 : 1.0;

    return Opacity(
      opacity: opacity,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              SizedBox(
                width: 64,
                child: Text(
                  day.dateLabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: day.isToday ? FontWeight.w800 : FontWeight.w600,
                    color: day.isToday ? const Color(0xFFF97316) : const Color(0xFF6B7280),
                  ),
                ),
              ),
              SizedBox(
                width: 40,
                child: Text(day.weekdayLabel, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
              ),
              Expanded(
                child: Text(
                  summary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: day.items.isNotEmpty ? const Color(0xFF111827) : const Color(0xFF9CA3AF),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

