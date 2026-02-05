import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/utils/kst_date.dart';
import '../models/store_models.dart';
import '../repositories/store_repository.dart';
import '../viewmodels/store_detail_view_model.dart';
import '../widgets/other_store_card.dart';
import '../widgets/weekly_menu_card.dart';

class StoreDetailScreen extends StatelessWidget {
  static const routeName = '/store/detail';

  final int storeId;

  const StoreDetailScreen({super.key, required this.storeId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          StoreDetailViewModel(context.read<StoreRepository>(), storeId)
            ..load(),
      child: const _StoreDetailView(),
    );
  }
}

class _StoreDetailView extends StatelessWidget {
  const _StoreDetailView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StoreDetailViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 50,
        title: const Text(
          '매장 상세페이지',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(child: _buildBody(context, vm)),
    );
  }

  Widget _buildBody(BuildContext context, StoreDetailViewModel vm) {
    if (vm.loading && vm.detail == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.errorMessage != null && vm.detail == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            vm.errorMessage!,
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      );
    }

    final detail = vm.detail;
    if (detail == null) {
      return const Center(child: Text('매장 정보가 없습니다.'));
    }

    return SingleChildScrollView(
      //appbar 아래로 스크롤 가능
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    height: 231,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x00FFFFFF), Color(0x33FFA588)],
                      ),
                    ),
                    child: _buildStoreImage(
                      detail,
                    ), // 이미지 빌더에서 사진을 축소해서 불러오는 방법 찾아야 함 -> StoreCard와 동일하게 해결
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20.5, 16, 20.5, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (detail.address != null && detail.address!.isNotEmpty)
                      Text(
                        detail.address!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    if (detail.phone != null && detail.phone!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          detail.phone!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    _buildOpenStatus(detail),
                  ],
                ),
              ),
            ],
          ),
          Container(
            height: 14,
            width: double.infinity,
            color: const Color(0xFFF1F1F1),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 10, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _WeeklyMenuSection(detail: detail, onReload: vm.load),
                const SizedBox(height: 20),
                const Text(
                  '다른 매장 보기',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                _buildOtherStores(context, vm),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtherStores(BuildContext context, StoreDetailViewModel vm) {
    final stores = vm.otherStores.take(3).toList();
    if (stores.isEmpty) {
      return const SizedBox.shrink();
    }
    final screenWidth = MediaQuery.of(context).size.width;
    return SizedBox(
      height: 189,
      child: Transform.translate(
        offset: const Offset(-20, 0),
        child: SizedBox(
          width: screenWidth,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: stores.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final store = stores[index];
              return OtherStoreCard(
                store: store,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => StoreDetailScreen(
                      storeId: store.id,
                    ), // 탭 시 해당 매장 상세 페이지로 이동
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildOpenStatus(StoreDetail detail) {
    final isOpen = detail.open == true;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isOpen ? const Color(0xFFDBEAFE) : const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            isOpen ? '영업중' : '영업 종료',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isOpen ? const Color(0xFF2563EB) : const Color(0xFFDC2626),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStoreImage(StoreDetail detail) {
    final url = (detail.imageUrl ?? '').trim();
    if (url.isEmpty) {
      return _buildNoImage();
    }
    final isNetwork = url.startsWith('http://') || url.startsWith('https://');
    if (isNetwork) {
      return Image.network(
        url,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildNoImage(),
      );
    }
    return Image.asset(
      url,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => _buildNoImage(),
    );
  }

  Widget _buildNoImage() {
    return Container(
      color: const Color(0xFFF3F4F6),
      alignment: Alignment.center,
      child: const Text(
        'No Img',
        style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
      ),
    );
  }
}

class _WeeklyMenuSection extends StatefulWidget {
  const _WeeklyMenuSection({required this.detail, required this.onReload});

  final StoreDetail detail;
  final Future<void> Function() onReload;

  @override
  State<_WeeklyMenuSection> createState() => _WeeklyMenuSectionState();
}

class _WeeklyMenuSectionState extends State<_WeeklyMenuSection> {
  static const _cardWidth = 148.0;
  static const _cardGap = 12.0;

  final ScrollController _singleController = ScrollController();
  final Map<int, ScrollController> _groupControllers = <int, ScrollController>{};

  @override
  void dispose() {
    _singleController.dispose();
    for (final c in _groupControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToTodayIfPossible());
  }

  @override
  void didUpdateWidget(covariant _WeeklyMenuSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.detail.weeklyMenuResponse != widget.detail.weeklyMenuResponse) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToTodayIfPossible());
    }
  }

  void _jumpToTodayIfPossible() {
    final weekly = widget.detail.weeklyMenuResponse;
    if (weekly == null) return;
    final days = _weekdayMenus(weekly);
    if (days.isEmpty) return;

    final today = kstTodayYmd();
    final idx = days.indexWhere((d) => d.date == today);
    if (idx < 0) return;

    final offset = (_cardWidth + _cardGap) * idx;

    void animate(ScrollController c) {
      if (!c.hasClients) return;
      c.animateTo(
        offset.clamp(0, c.position.maxScrollExtent),
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    }

    // 단일 그룹(또는 그룹 통합 카드) 스크롤
    animate(_singleController);

    // 다중 그룹: 모든 그룹별 리스트도 오늘 카드로 이동
    for (final c in _groupControllers.values) {
      animate(c);
    }
  }

  List<StoreWeeklyMenuDay> _weekdayMenus(WeeklyMenuResponse weekly) {
    const weekdays = {'MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY'};
    final list = weekly.dailyMenus.where((d) => weekdays.contains(d.dayOfWeek)).toList();
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final weekly = widget.detail.weeklyMenuResponse;
    final today = kstTodayYmd();

    final titleRow = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          '일주일 메뉴',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        IconButton(
          onPressed: widget.onReload,
          icon: const Icon(Icons.refresh, color: Color(0xFF9CA3AF)),
          tooltip: '새로고침',
        ),
      ],
    );

    if (weekly == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleRow,
          const SizedBox(height: 8),
          const Text('메뉴 정보를 불러올 수 없습니다.', style: TextStyle(color: Color(0xFF9CA3AF))),
        ],
      );
    }

    final days = _weekdayMenus(weekly);
    if (days.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleRow,
          const SizedBox(height: 8),
          const Text('표시할 메뉴가 없습니다.', style: TextStyle(color: Color(0xFF9CA3AF))),
        ],
      );
    }

    // 그룹 목록(첫 날 기준, sortOrder)
    final first = days.first;
    final groups = [...first.groups]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final singleGroup = groups.length <= 1;

    ScrollController controllerForGroup(StoreDetailDayGroup? group) {
      if (group == null) return _singleController;
      return _groupControllers.putIfAbsent(group.groupId, () => ScrollController());
    }

    Widget buildCardsForGroup(StoreDetailDayGroup? group) {
      return SizedBox(
        height: 160,
        child: ListView.builder(
          controller: controllerForGroup(group),
          scrollDirection: Axis.horizontal,
          itemCount: days.length,
          itemBuilder: (context, index) {
            final d = days[index];
            final dateLabel = _formatMmDd(d.date);
            final dayLabel = _korDayLabel(d.dayOfWeek);
            final items = group == null
                ? d.groups.expand((g) => g.menus).toList(growable: false)
                : (d.groups.firstWhere(
                        (g) => g.groupId == group.groupId,
                        orElse: () => StoreDetailDayGroup(
                          groupId: group.groupId,
                          name: group.name,
                          sortOrder: group.sortOrder,
                          stock: 0,
                          capacity: 0,
                          menus: const [],
                        ),
                      ).menus);
            return WeeklyMenuCard(
              dateLabel: dateLabel,
              dayLabel: dayLabel,
              items: items,
            );
          },
        ),
      );
    }

    int singleRemain() {
      final todayDaily = days.where((d) => d.date == today).cast<StoreWeeklyMenuDay?>().firstWhere((_) => true, orElse: () => null);
      if (todayDaily == null) return widget.detail.remain ?? 0;
      if (todayDaily.groups.isNotEmpty) return todayDaily.groups.first.stock;
      return widget.detail.remain ?? 0;
    }

    int groupRemain(int groupId) {
      final todayDaily = days.where((d) => d.date == today).cast<StoreWeeklyMenuDay?>().firstWhere((_) => true, orElse: () => null);
      if (todayDaily == null) return 0;
      final g = todayDaily.groups.where((e) => e.groupId == groupId).cast<StoreDetailDayGroup?>().firstWhere((_) => true, orElse: () => null);
      return g?.stock ?? 0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        titleRow,
        const SizedBox(height: 10),
        if (singleGroup) ...[
          buildCardsForGroup(null),
          const SizedBox(height: 10),
          Text(
            '남은 수량 : ${singleRemain()}개',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFFFF6E3F),
            ),
          ),
        ] else ...[
          for (final g in groups) ...[
            Text(
              g.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
            ),
            const SizedBox(height: 8),
            buildCardsForGroup(g),
            const SizedBox(height: 10),
            Text(
              '남은 수량 : ${groupRemain(g.groupId)}개',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFF6E3F),
              ),
            ),
            const SizedBox(height: 18),
          ],
        ],
      ],
    );
  }

  String _formatMmDd(String ymd) {
    // YYYY-MM-DD -> MM월 DD일
    if (ymd.length < 10) return ymd;
    final mm = ymd.substring(5, 7);
    final dd = ymd.substring(8, 10);
    return '$mm월 $dd일';
  }

  String _korDayLabel(String dayOfWeek) {
    switch (dayOfWeek) {
      case 'MONDAY':
        return '월요일';
      case 'TUESDAY':
        return '화요일';
      case 'WEDNESDAY':
        return '수요일';
      case 'THURSDAY':
        return '목요일';
      case 'FRIDAY':
        return '금요일';
      case 'SATURDAY':
        return '토요일';
      case 'SUNDAY':
        return '일요일';
      default:
        return dayOfWeek;
    }
  }
}
