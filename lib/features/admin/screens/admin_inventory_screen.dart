import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/admin_inventory_view_model.dart';

class AdminInventoryScreen extends StatefulWidget {
  static const routeName = '/admin/inventory';

  const AdminInventoryScreen({super.key});

  @override
  State<AdminInventoryScreen> createState() => _AdminInventoryScreenState();
}

class _AdminInventoryScreenState extends State<AdminInventoryScreen> {
  final _controller = TextEditingController();
  bool _loaded = false;

  @override
  void dispose() {
    _controller.dispose();
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
    _controller.value = _controller.value.copyWith(text: vm.stock.toString(), selection: TextSelection.collapsed(offset: vm.stock.toString().length));

    final formatted = _formatKstKorean(vm.date);

    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Stack(
        children: [
          Container(
            color: const Color(0xFFFAFAFA),
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
                  ),
                ),

                // 재고 패널
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 10, offset: Offset(0, 4))],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '현재 수량',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: vm.open ? const Color(0xFF111827) : const Color(0xFFD1D5DB),
                              ),
                            ),
                            Row(
                              children: [
                                _CircleButton(
                                  label: '–',
                                  onTap: () => vm.adjustStock(-1),
                                  disabled: vm.loading || vm.saving,
                                ),
                                const SizedBox(width: 10),
                                SizedBox(
                                  width: 96,
                                  height: 48,
                                  child: TextField(
                                    controller: _controller,
                                    enabled: !vm.loading && !vm.saving,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: vm.open ? const Color(0xFF111827) : const Color(0xFFD1D5DB),
                                    ),
                                    decoration: InputDecoration(
                                      contentPadding: EdgeInsets.zero,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onChanged: vm.setStockFromInput,
                                    onSubmitted: (_) => vm.commitStock(),
                                    onEditingComplete: () => vm.commitStock(),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                _CircleButton(
                                  label: '+',
                                  onTap: () => vm.adjustStock(1),
                                  disabled: vm.loading || vm.saving,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 10, offset: Offset(0, 4))],
                        ),
                        child: Row(
                          children: const [10, 5, 1].asMap().entries.map((e) {
                            final idx = e.key;
                            final value = e.value;
                            return Expanded(
                              child: _QuickMinusButton(value: value, showDivider: idx < 2),
                            );
                          }).toList(growable: false),
                        ),
                      ),
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
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: const Color(0xFFD1D5DB),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Center(
          child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 18, height: 1.0)),
        ),
      ),
    );
  }
}

class _QuickMinusButton extends StatelessWidget {
  final int value;
  final bool showDivider;
  const _QuickMinusButton({required this.value, required this.showDivider});

  @override
  Widget build(BuildContext context) {
    final vm = context.read<AdminInventoryViewModel>();
    return InkWell(
      onTap: () => vm.adjustStock(-value),
      child: Container(
        height: 112,
        decoration: BoxDecoration(
          border: showDivider ? const Border(right: BorderSide(color: Color(0xFFE5E7EB))) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(color: const Color(0xFFD1D5DB), borderRadius: BorderRadius.circular(999)),
              child: const Center(child: Text('–', style: TextStyle(color: Colors.white, fontSize: 14, height: 1.0))),
            ),
            const SizedBox(width: 8),
            Text('$value개', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          ],
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

