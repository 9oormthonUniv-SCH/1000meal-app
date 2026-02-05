import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/menu_models.dart';
import '../viewmodels/admin_inventory_view_model.dart';

class AdminInventoryScreen extends StatefulWidget {
  static const routeName = '/admin/inventory';

  const AdminInventoryScreen({super.key});

  @override
  State<AdminInventoryScreen> createState() => _AdminInventoryScreenState();
}

class _AdminInventoryScreenState extends State<AdminInventoryScreen> {
  final Map<int, TextEditingController> _controllers = <int, TextEditingController>{};
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
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AdminInventoryViewModel>().loadToday());
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminInventoryViewModel>();

    final formatted = _formatKstKorean(vm.date);
    final groups = vm.groupsSorted;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 56,
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '재고 관리',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
            fontFamily: 'Pretendard',
            height: 1.6,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          IconButton(
            onPressed: (vm.loading || vm.saving) ? null : () => vm.loadToday(),
            icon: Icon(
              Icons.refresh,
              color: (vm.loading || vm.saving) ? const Color(0xFFBDBDBD) : const Color(0xFFBDBDBD),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Stack(
        children: [
          Container(
            color: const Color(0xFFF7F7F7), // stone-50
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // 날짜 바
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
                      children: [
                        TextSpan(text: '${formatted.monthDay} '),
                        TextSpan(text: formatted.weekday, style: const TextStyle(color: Color(0xFFFB923C))),
                      ],
                    ),
                  ),),

                // 재고 패널
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                  child: Column(
                    children: [
                      for (final g in groups) ...[
                        _GroupStockCard(
                          group: g,
                          open: vm.open,
                          loading: vm.loading,
                          saving: vm.saving,
                          stock: vm.groupStock(g.id),
                          controller: _controllers.putIfAbsent(g.id, () => TextEditingController()),
                          onMinus: () => vm.deductGroupStock(g.id, DeductionUnit.single),
                          onPlus: () => vm.adjustGroupStock(g.id, 1),
                          onChanged: (v) => vm.setGroupStockFromInput(g.id, v),
                          onCommit: () => vm.commitGroupStock(g.id),
                          onDeduct: (DeductionUnit unit) => vm.deductGroupStock(g.id, unit),
                        ),
                        const SizedBox(height: 28),
                        const Divider(height: 1, thickness: 0.5, color: Color(0xFFBDBDBD)),
                        const SizedBox(height: 22),
                      ],
                      if (vm.errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(vm.errorMessage!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
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

          // 영업 전 모달
          if (vm.showOpenModal)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: Center(
                  child: Container(
                    width: 280,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('아직 영업 전입니다', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                        const SizedBox(height: 6),
                        const Text(
                          '영업중으로 상태를 변경하시겠습니까?',
                          style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: vm.saving ? null : vm.closeModal,
                                style: TextButton.styleFrom(
                                  backgroundColor: const Color(0xFFF3F4F6),
                                  foregroundColor: const Color(0xFF6B7280),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('아니요'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextButton(
                                onPressed: vm.saving ? null : vm.confirmOpenAndUnlock,
                                style: TextButton.styleFrom(
                                  backgroundColor: const Color(0xFF60A5FA),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: vm.saving
                                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Text('네'),
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

          // 재고 0개 → 영업 종료 제안 모달
          if (vm.showCloseModal)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: Center(
                  child: Container(
                    width: 280,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('재고가 0개입니다', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                        const SizedBox(height: 6),
                        const Text(
                          '영업 종료로 상태를 변경하시겠습니까?',
                          style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: vm.saving ? null : vm.closeModal,
                                style: TextButton.styleFrom(
                                  backgroundColor: const Color(0xFFF3F4F6),
                                  foregroundColor: const Color(0xFF6B7280),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('아니요'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextButton(
                                onPressed: vm.saving ? null : vm.confirmCloseAndLock,
                                style: TextButton.styleFrom(
                                  backgroundColor: const Color(0xFF60A5FA),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: vm.saving
                                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Text('네'),
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

class _CircleButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool disabled;
  const _CircleButton({required this.label, required this.onTap, required this.disabled});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: const Color(0xFFBDBDBD).withValues(alpha: 0.7), // stone-300 opacity-70
          borderRadius: BorderRadius.circular(999),
        ),
        child: Center(
          child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.0)),
        ),
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
    final titleColor = open ? const Color(0xFF1A1A1A) : const Color(0xFFBDBDBD);

    return SizedBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '[${group.name}]  현재 수량',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFFBDBDBD),
              fontFamily: 'Pretendard',
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _CircleButton(label: '–', onTap: onMinus, disabled: disabled),
              const SizedBox(width: 14),
              SizedBox(
                width: 88,
                height: 36,
                child: TextField(
                  controller: controller,
                  enabled: !disabled,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                    fontFamily: 'Pretendard',
                    height: 1.0,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFBDBDBD), width: 0.72),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFBDBDBD), width: 0.72),
                    ),
                  ),
                  onChanged: onChanged,
                  onSubmitted: (_) => onCommit(),
                  onEditingComplete: onCommit,
                ),
              ),
              const SizedBox(width: 14),
              _CircleButton(label: '+', onTap: onPlus, disabled: disabled),
            ],
          ),
          const SizedBox(height: 28),
          _DeductRow(
            disabled: disabled,
            stock: stock,
            onDeduct: onDeduct,
          ),
        ],
      ),
    );
  }
}

class _DeductRow extends StatelessWidget {
  const _DeductRow({
    required this.disabled,
    required this.stock,
    required this.onDeduct,
  });

  final bool disabled;
  final int stock;
  final ValueChanged<DeductionUnit> onDeduct;

  @override
  Widget build(BuildContext context) {
    final can10 = !disabled && stock >= 10;
    final can5 = !disabled && stock >= 5;
    final can1 = !disabled && stock >= 1;

    return Container(
      height: 96,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000), // rgba(0,0,0,0.15)
            blurRadius: 20,
            offset: Offset(0, 0),
          ),
        ],
      ),
      child: Row(
        children: [
          _DeductCell(
            label: '10개',
            enabled: can10,
            roundedLeft: true,
            onTap: () => onDeduct(DeductionUnit.multiTen),
          ),
          _DeductCell(
            label: '5개',
            enabled: can5,
            onTap: () => onDeduct(DeductionUnit.multiFive),
          ),
          _DeductCell(
            label: '1개',
            enabled: can1,
            roundedRight: true,
            onTap: () => onDeduct(DeductionUnit.single),
          ),
        ],
      ),
    );
  }
}

class _DeductCell extends StatelessWidget {
  const _DeductCell({
    required this.label,
    required this.enabled,
    required this.onTap,
    this.roundedLeft = false,
    this.roundedRight = false,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;
  final bool roundedLeft;
  final bool roundedRight;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.only(
      topLeft: roundedLeft ? const Radius.circular(16) : Radius.zero,
      bottomLeft: roundedLeft ? const Radius.circular(16) : Radius.zero,
      topRight: roundedRight ? const Radius.circular(16) : Radius.zero,
      bottomRight: roundedRight ? const Radius.circular(16) : Radius.zero,
    );

    return Expanded(
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: const Border(
              right: BorderSide(color: Color(0xFFBDBDBD), width: 0.5),
            ),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFFBDBDBD).withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Center(
                    child: Text('–', style: TextStyle(color: Colors.white, fontSize: 14, height: 1.0)),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: enabled ? const Color(0xFFBDBDBD) : const Color(0xFFBDBDBD),
                    fontFamily: 'Pretendard',
                    height: 1.0,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
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
  T? elementAtOrNull(int index) => (index >= 0 && index < length) ? this[index] : null;
}

