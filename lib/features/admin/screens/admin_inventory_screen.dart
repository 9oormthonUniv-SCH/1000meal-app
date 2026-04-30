import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:meal_app/util/colors.dart';
import 'package:meal_app/util/typography.dart';

import '../../../common/widgets/app_bar_common.dart';
import '../../../common/widgets/app_button.dart';
import '../../../common/widgets/app_deduct_row.dart';
import '../../../common/widgets/app_quantity_stepper.dart';
import '../models/menu_models.dart';
import '../viewmodels/admin_inventory_view_model.dart';

class AdminInventoryScreen extends StatefulWidget {
  static const routeName = '/admin/inventory';

  const AdminInventoryScreen({super.key});

  @override
  State<AdminInventoryScreen> createState() => _AdminInventoryScreenState();
}

class _AdminInventoryScreenState extends State<AdminInventoryScreen> {
  final Map<int, TextEditingController> _controllers =
      <int, TextEditingController>{};
  bool _loaded = false;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    // 188488b 시절과 동일: 한 프레임 뒤 로드 (TestFlight 등에서 즉시 호출 시 타이밍 이슈 가능성 완화)
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<AdminInventoryViewModel>().loadToday(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminInventoryViewModel>();

    final formatted = _formatKstKorean(vm.date);
    final groups = vm.groupsSorted;

    return Scaffold(
      appBar: AppBarCommon(
        toolbarHeight: 56,
        title: '재고 관리',
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: (vm.loading || vm.saving) ? null : () => vm.loadToday(),
            icon: const Icon(Icons.refresh, color: AppColors.gray5),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Stack(
        children: [
          Container(
            color: AppColors.gray1,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // 날짜 바
                Container(
                  color: AppColors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  child: RichText(
                    text: TextSpan(
                      style: AppTypography.headline4.copyWith(
                        color: AppColors.gray7,
                      ),
                      children: [
                        TextSpan(text: '${formatted.monthDay} '),
                        TextSpan(
                          text: formatted.weekday,
                          style: AppTypography.headline4.copyWith(
                            color: AppColors.gray7,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 재고 패널
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                  child: Column(
                    children: [
                      for (int i = 0; i < groups.length; i++) ...[
                        _GroupStockCard(
                          group: groups[i],
                          open: vm.open,
                          loading: vm.loading,
                          saving: vm.saving,
                          stock: vm.groupStock(groups[i].id),
                          controller: _controllers.putIfAbsent(
                            groups[i].id,
                            () => TextEditingController(),
                          ),
                          onMinus: () {
                            if (!vm.open) {
                              vm.showOpenModal = true;
                              vm.notifyListeners();
                              return;
                            }
                            vm.deductGroupStock(groups[i].id, DeductionUnit.single);
                          },
                          onPlus: () {
                            if (!vm.open) {
                              vm.showOpenModal = true;
                              vm.notifyListeners();
                              return;
                            }
                            vm.adjustGroupStock(groups[i].id, 1);
                          },
                          onChanged: (v) => vm.setGroupStockFromInput(groups[i].id, v),
                          onCommit: () {
                            if (!vm.open) {
                              vm.showOpenModal = true;
                              vm.notifyListeners();
                              return;
                            }
                            vm.commitGroupStock(groups[i].id);
                          },
                          onDeduct: (DeductionUnit unit) {
                            if (!vm.open) {
                              vm.showOpenModal = true;
                              vm.notifyListeners();
                              return;
                            }
                            vm.deductGroupStock(groups[i].id, unit);
                          },
                        ),
                        if (i < groups.length - 1) ...[
                          const SizedBox(height: 28),
                          const Divider(
                            height: 1,
                            thickness: 0.5,
                            color: AppColors.gray5,
                          ),
                          const SizedBox(height: 22),
                        ],
                      ],
                      if (vm.errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          vm.errorMessage!,
                          style: AppTypography.caption2.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ],
                      if (vm.loading) ...[
                        const SizedBox(height: 14),
                        const Center(child: CircularProgressIndicator()),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 재고 차감/적용 중 로딩 (알림 등 지연 시 중복 탭 방지)
          if (vm.saving)
            Positioned.fill(
              child: Container(
                color: AppColors.black.withValues(alpha: 0.08),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: AppColors.blue),
                      const SizedBox(height: 12),
                      Text(
                        '저장 중...',
                        style: AppTypography.caption2.copyWith(
                          color: AppColors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 영업 전 모달: "영업중"만 54AAFF, 아니오 F1F1F1/767676, 네 54AAFF/FFFFFF
          if (vm.showOpenModal)
            Positioned.fill(
              child: Container(
                color: AppColors.black.withValues(alpha: 0.3),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 280,
                      maxWidth: 340,
                      minHeight: 180,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '아직 영업 전입니다',
                          style: AppTypography.subtitle1.copyWith(
                            color: AppColors.black,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: AppTypography.body2.copyWith(height: 1.45),
                            children: const [
                              TextSpan(
                                text: '영업중',
                                style: TextStyle(color: AppColors.blue),
                              ),
                              TextSpan(
                                text: '으로 상태를 변경하시겠습니까?',
                                style: TextStyle(color: AppColors.black),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        Row(
                          children: [
                            Expanded(
                              child: AppButton(
                                label: '아니요',
                                variant: AppButtonVariant.secondary,
                                backgroundColor: AppColors.gray2,
                                foregroundColor: AppColors.gray7,
                                height: 48,
                                onPressed: vm.saving ? null : vm.closeModal,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppButton(
                                label: '네',
                                variant: AppButtonVariant.primaryBlue,
                                backgroundColor: AppColors.blue,
                                foregroundColor: AppColors.white,
                                height: 48,
                                loading: vm.saving,
                                onPressed: vm.saving
                                    ? null
                                    : vm.confirmOpenAndUnlock,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // 재고 0개 → 영업 종료 제안 모달: 첫 줄 767676, 둘째 줄 1A1A1A, 아니오 F1F1F1/767676, 네 767676/FFFFFF
          if (vm.showCloseModal)
            Positioned.fill(
              child: Container(
                color: AppColors.black.withValues(alpha: 0.3),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 280,
                      maxWidth: 340,
                      minHeight: 180,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "현재 재고가 '0개'입니다",
                          style: AppTypography.body2.copyWith(
                            color: AppColors.gray7,
                            height: 1.45,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '영업을 종료하시겠습니까?',
                          style: AppTypography.body2.copyWith(
                            color: AppColors.black,
                            height: 1.45,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),
                        Row(
                          children: [
                            Expanded(
                              child: AppButton(
                                label: '아니요',
                                variant: AppButtonVariant.secondary,
                                backgroundColor: AppColors.gray2,
                                foregroundColor: AppColors.gray7,
                                height: 48,
                                onPressed: vm.saving ? null : vm.closeModal,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppButton(
                                label: '네',
                                variant: AppButtonVariant.primaryBlue,
                                backgroundColor: AppColors.gray7,
                                foregroundColor: AppColors.white,
                                height: 48,
                                loading: vm.saving,
                                onPressed: vm.saving
                                    ? null
                                    : vm.confirmCloseAndLock,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GroupStockCard extends StatelessWidget {
  const _GroupStockCard({
    required this.group,
    required this.open,
    required this.loading,
    required this.saving,
    required this.stock,
    required this.controller,
    required this.onMinus,
    required this.onPlus,
    required this.onChanged,
    required this.onCommit,
    required this.onDeduct,
  });

  final DailyMenuGroupItem group;
  final bool open;
  final bool loading;
  final bool saving;
  final int stock;
  final TextEditingController controller;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final ValueChanged<String> onChanged;
  final VoidCallback onCommit;
  final ValueChanged<DeductionUnit> onDeduct;

  @override
  Widget build(BuildContext context) {
    controller.value = controller.value.copyWith(
      text: stock.toString(),
      selection: TextSelection.collapsed(offset: stock.toString().length),
    );

    final disabled = loading || saving;
    // 영업 종료 시에도 버튼/입력은 비활성화하지 않음. 탭·입력 시 "영업중으로 바꾸겠어요?" 팝업 표시.
    final stepperEnabled = !disabled;
    final deductEnabled = !disabled;
    final labelColor = open ? AppColors.black : AppColors.gray5;
    final valueColor = open ? AppColors.error : AppColors.gray5;

    return SizedBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '[${group.name}]  현재 수량',
            style: AppTypography.headline4.copyWith(
              color: labelColor,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          AppQuantityStepper(
            value: stock,
            controller: controller,
            onMinus: onMinus,
            onPlus: onPlus,
            onChanged: onChanged,
            onCommit: onCommit,
            enabled: stepperEnabled,
            valueColor: valueColor,
          ),
          const SizedBox(height: 28),
          AppDeductRow(
            labels: const ['10개', '5개', '1개'],
            labelColor: labelColor,
            enabledList: [
              deductEnabled && (open ? stock >= 10 : true),
              deductEnabled && (open ? stock >= 5 : true),
              deductEnabled && (open ? stock >= 1 : true),
            ],
            onDeduct: (i) {
              if (i == 0)
                onDeduct(DeductionUnit.multiTen);
              else if (i == 1)
                onDeduct(DeductionUnit.multiFive);
              else
                onDeduct(DeductionUnit.single);
            },
          ),
        ],
      ),
    );
  }
}

class _KstKoreanDate {
  final String monthDay; // "1월 19일"
  final String weekday; // "월요일"
  const _KstKoreanDate({required this.monthDay, required this.weekday});
}

_KstKoreanDate _formatKstKorean(String ymd) {
  // ymd: YYYY-MM-DD
  final parts = ymd.split('-');
  final y = int.tryParse(parts.elementAtOrNull(0) ?? '') ?? 2000;
  final m = int.tryParse(parts.elementAtOrNull(1) ?? '') ?? 1;
  final d = int.tryParse(parts.elementAtOrNull(2) ?? '') ?? 1;
  final dt = DateTime(y, m, d);
  const weekdays = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
  final wd = weekdays[(dt.weekday - 1).clamp(0, 6)];
  return _KstKoreanDate(monthDay: '$m월 $d일', weekday: wd);
}

extension _ListExt<T> on List<T> {
  T? elementAtOrNull(int index) =>
      (index >= 0 && index < length) ? this[index] : null;
}
