import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:meal_app/util/colors.dart';
import 'package:meal_app/util/typography.dart';

import '../../../common/utils/kst_date.dart';
import '../../../common/widgets/app_bar_common.dart';
import '../../../common/widgets/store_open_status_badge.dart';
import '../models/store_models.dart';
import '../repositories/store_repository.dart';
import '../viewmodels/store_detail_view_model.dart';
import '../viewmodels/store_list_view_model.dart';
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
      backgroundColor: AppColors.white,
      appBar: AppBarCommon(
        toolbarHeight: 50,
        title: '매장 상세페이지',
        centerTitle: true,
      ),
      body: SafeArea(
        bottom: false,
        child: _buildBody(context, vm),
      ),
    );
  }

  Widget _buildBody(BuildContext context, StoreDetailViewModel vm) {
    final listVm = context.watch<StoreListViewModel>();
    if (vm.loading && vm.detail == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.errorMessage != null && vm.detail == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Text(
            vm.errorMessage!,
            style: const TextStyle(color: AppColors.error),
          ),
        ),
      );
    }

    final detail = vm.detail;
    if (detail == null) {
      return const Center(child: Text('매장 정보가 없습니다.'));
    }

    final currentStore = listVm.items.firstWhere(
      (s) => s.id == detail.id,
      orElse: () => StoreListItem(
        id: detail.id,
        name: detail.name,
        imageUrl: detail.imageUrl,
        address: detail.address,
        phone: detail.phone,
        hours: detail.hours,
        menus: const [],
        remain: detail.remain ?? 0,
        open: detail.open,
        todayMenu: null,
        lat: null,
        lng: null,
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: ClipRRect(
                  child: Container(
                    width: double.infinity,
                    height: 231,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.lightOrange.withValues(alpha: 0.2),
                        ],
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            detail.name,
                            style: AppTypography.headline4.copyWith(
                              fontSize: 18,
                              height: 28 / 18,
                              color: AppColors.black,
                            ),
                          ),
                        ),
                        Selector<StoreListViewModel, bool>(
                          selector: (_, listVM) {
                            final list = listVM.items.where((s) => s.id == detail.id).toList();
                            return list.isNotEmpty ? list.first.isFavorite : currentStore.isFavorite;
                          },
                          builder: (_, isFavorite, __) => IconButton(
                            onPressed: () async {
                              final store = listVm.items
                                  .where((s) => s.id == detail.id)
                                  .toList();
                              final toToggle = store.isNotEmpty ? store.first : currentStore;
                              await listVm.toggleFavorite(toToggle);
                              if (!context.mounted) return;
                              final msg = listVm.errorMessage;
                              if (msg != null && msg.isNotEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(msg)),
                                );
                              }
                            },
                            icon: SvgPicture.asset(
                              isFavorite
                                  ? 'assets/icon/favorite_star_on.svg'
                                  : 'assets/icon/favorite_star_off.svg',
                              width: 24,
                              height: 24,
                            ),
                            highlightColor: AppColors.orange.withValues(alpha: 0.2),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ),
                      ],
                    ),
                    if (detail.address != null && detail.address!.isNotEmpty)
                      Text(
                        detail.address!,
                        style: AppTypography.caption2.copyWith(color: AppColors.gray7),
                      ),
                    if (detail.phone != null && detail.phone!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 0),
                        child: Text(
                          detail.phone!,
                          style: AppTypography.caption2.copyWith(color: AppColors.gray7),
                        ),
                      ),
                    const SizedBox(height: 16),
                    _buildOpenStatus(detail),
                    if (detail.hours != null && detail.hours!.isNotEmpty) ...[
                      Text(
                        '천원의 아침밥 운영 시간: ${detail.hours!}',
                        style: AppTypography.caption2.copyWith(color: AppColors.gray7),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          Container(
            height: 14,
            width: double.infinity,
            color: AppColors.gray2,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _WeeklyMenuSection(detail: detail, onReload: vm.load),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  '다른 매장 보기',
                  style: AppTypography.headline2.copyWith(
                    color: AppColors.black,
                    fontSize: 24,
                    height: 32 / 24,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildOtherStores(context, vm),
            ],
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
    return SizedBox(
      height: 213,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        itemCount: stores.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final store = stores[index];
          return OtherStoreCard(
            store: store,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => StoreDetailScreen(storeId: store.id),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOpenStatus(StoreDetail detail) {
    return Row(
      children: [
        StoreOpenStatusBadge(isOpen: detail.open == true),
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
      color: AppColors.background,
      alignment: Alignment.center,
      child: Text(
        'No Img',
        style: AppTypography.caption2.copyWith(
          fontSize: 11,
          color: AppColors.gray7,
        ),
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
  final Map<int, ScrollController> _groupControllers =
      <int, ScrollController>{};

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
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _jumpToTodayIfPossible(),
    );
  }

  @override
  void didUpdateWidget(covariant _WeeklyMenuSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.detail.weeklyMenuResponse !=
        widget.detail.weeklyMenuResponse) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _jumpToTodayIfPossible(),
      );
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
    final list = weekly.dailyMenus
        .where((d) => weekdays.contains(d.dayOfWeek))
        .toList();
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final weekly = widget.detail.weeklyMenuResponse;
    final today = kstTodayYmd();

    final titleRow = Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '주간 메뉴',
            style: AppTypography.headline2.copyWith(
              fontSize: 24,
              height: 32 / 24,
              color: AppColors.black,
            ),
          ),
          IconButton(
            onPressed: widget.onReload,
            icon: const Icon(Icons.refresh, color: AppColors.gray6),
            tooltip: '새로고침',
          ),
        ],
      ),
    );

    if (weekly == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleRow,
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '메뉴 정보를 불러올 수 없습니다.',
              style: AppTypography.body4.copyWith(color: AppColors.gray7),
            ),
          ),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '표시할 메뉴가 없습니다.',
              style: AppTypography.body4.copyWith(color: AppColors.gray7),
            ),
          ),
        ],
      );
    }

    // 그룹 목록(첫 날 기준, sortOrder)
    final first = days.first;
    final groups = [...first.groups]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final singleGroup = groups.length <= 1;

    ScrollController controllerForGroup(StoreDetailDayGroup? group) {
      if (group == null) return _singleController;
      return _groupControllers.putIfAbsent(
        group.groupId,
        () => ScrollController(),
      );
    }

    // 오늘(주말 포함) 재고 조회용 – 전체 dailyMenus에서 오늘 찾음
    StoreWeeklyMenuDay? todayDailyForRemain() {
      try {
        return weekly.dailyMenus.firstWhere((d) => d.date == today);
      } catch (_) {
        return null;
      }
    }

    /// 오늘 날짜 기준 재고. 오늘 데이터 없을 때(토·일 등)는 아무 요일의 첫 그룹 stock 사용 (remain 미사용)
    int singleRemain() {
      final todayDaily = todayDailyForRemain();
      if (todayDaily != null && todayDaily.groups.isNotEmpty) {
        return todayDaily.groups.first.stock;
      }
      if (days.isNotEmpty && days.first.groups.isNotEmpty) {
        return days.first.groups.first.stock;
      }
      return 0;
    }

    /// 그룹별 재고. 오늘 없을 때(토·일 등)는 해당 그룹이 있는 아무 요일의 stock 사용
    int groupRemain(int groupId) {
      final todayDaily = todayDailyForRemain();
      if (todayDaily != null) {
        final g = todayDaily.groups
            .where((e) => e.groupId == groupId)
            .cast<StoreDetailDayGroup?>()
            .firstWhere((_) => true, orElse: () => null);
        if (g != null) return g.stock;
      }
      for (final d in days) {
        final g = d.groups
            .where((e) => e.groupId == groupId)
            .cast<StoreDetailDayGroup?>()
            .firstWhere((_) => true, orElse: () => null);
        if (g != null) return g.stock;
      }
      return 0;
    }

    Widget buildCardsForGroup(StoreDetailDayGroup? group) {
      return SizedBox(
        height: 216,
        child: ListView.builder(
          controller: controllerForGroup(group),
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          itemCount: days.length,
          itemBuilder: (context, index) {
            final d = days[index];
            final dateLabel = _formatMmDd(d.date);
            final dayLabel = _korDayLabel(d.dayOfWeek);
            final items = group == null
                ? d.groups.expand((g) => g.menus).toList(growable: false)
                : (d.groups
                      .firstWhere(
                        (g) => g.groupId == group.groupId,
                        orElse: () => StoreDetailDayGroup(
                          groupId: group.groupId,
                          name: group.name,
                          sortOrder: group.sortOrder,
                          stock: 0,
                          capacity: 0,
                          menus: const [],
                        ),
                      )
                      .menus);
            final isToday = d.date == today;
            final remain = group == null
                ? (isToday ? singleRemain() : null)
                : (isToday ? groupRemain(group.groupId) : null);
            return WeeklyMenuCard(
              dateLabel: dateLabel,
              dayLabel: dayLabel,
              items: items,
              isSelected: isToday,
              showRemain: remain,
            );
          },
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        titleRow,
        const SizedBox(height: 10),
        if (singleGroup) ...[
          buildCardsForGroup(null),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: RichText(
              text: TextSpan(
                style: AppTypography.caption2.copyWith(color: AppColors.gray7),
                children: [
                  TextSpan(
                    text: '${singleRemain()}개',
                    style: AppTypography.caption1.copyWith(color: AppColors.orange),
                  ),
                  const TextSpan(text: ' 남았어요!'),
                ],
              ),
            ),
          ),
        ] else ...[
          for (final g in groups) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                g.name,
                style: AppTypography.subtitle1.copyWith(
                  color: AppColors.black,
                  fontSize: 16,
                  height: 32 / 16,
                ),
              ),
            ),
            const SizedBox(height: 8),
            buildCardsForGroup(g),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: RichText(
                text: TextSpan(
                  style: AppTypography.caption2.copyWith(color: AppColors.gray7),
                  children: [
                    TextSpan(
                      text: '${groupRemain(g.groupId)}개',
                      style: AppTypography.caption1.copyWith(color: AppColors.orange),
                    ),
                    const TextSpan(text: ' 남았어요!'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
          ],
        ], // else
      ], // children
    ); // Column
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
