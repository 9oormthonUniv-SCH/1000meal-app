import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/utils/week_kst.dart';
import '../viewmodels/admin_menu_edit_view_model.dart';

class AdminMenuEditScreen extends StatefulWidget {
  static const routeName = '/admin/menu/edit';

  final String? initialDate; // YYYY-MM-DD

  const AdminMenuEditScreen({super.key, this.initialDate});

  @override
  State<AdminMenuEditScreen> createState() => _AdminMenuEditScreenState();
}

class _AdminMenuEditScreenState extends State<AdminMenuEditScreen> {
  bool _loaded = false;
  Timer? _toastTimer;
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _toastTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AdminMenuEditViewModel>().load());
  }

  Future<bool> _confirmDiscardIfDirty(AdminMenuEditViewModel vm) async {
    if (!vm.dirty) return true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('변경사항이 있어요'),
        content: const Text('저장하지 않고 나갈까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('나가기')),
        ],
      ),
    );
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminMenuEditViewModel>();

    if (_controller.text != vm.input) {
      _controller.value = TextEditingValue(
        text: vm.input,
        selection: TextSelection.collapsed(offset: vm.input.length),
      );
    }

    // toast (저장되었습니다)
    if (vm.showSavedToast) {
      _toastTimer?.cancel();
      _toastTimer = Timer(const Duration(milliseconds: 700), () {
        if (!mounted) return;
        context.read<AdminMenuEditViewModel>().hideToast();
      });
    }

    // 웹 UI처럼 월~일(7일) 표시
    final days = List.generate(7, (i) => addDaysYmd(vm.mondayId, i));

    return WillPopScope(
      onWillPop: () => _confirmDiscardIfDirty(vm),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('메뉴 수정'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final ok = await _confirmDiscardIfDirty(vm);
              if (!ok) return;
              if (!context.mounted) return;
              Navigator.of(context).pushNamedAndRemoveUntil('/admin/menu', (r) => false);
            },
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ElevatedButton(
                onPressed: vm.saving ? null : () => context.read<AdminMenuEditViewModel>().save(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF97316),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                child: Text(vm.saving ? '저장중...' : '저장', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  _WeekNavigator(
                    mondayId: vm.mondayId,
                    selectedId: vm.selectedId,
                    days: days,
                    onPrevWeek: () async {
                      final ok = await _confirmDiscardIfDirty(vm);
                      if (!ok) return;
                      await vm.shiftWeek(-1);
                    },
                    onNextWeek: () async {
                      final ok = await _confirmDiscardIfDirty(vm);
                      if (!ok) return;
                      await vm.shiftWeek(1);
                    },
                    onSelect: (id) async {
                      final ok = await _confirmDiscardIfDirty(vm);
                      if (!ok) return;
                      await vm.selectDate(id);
                    },
                  ),
                  if (vm.loading)
                    const Expanded(child: Center(child: CircularProgressIndicator()))
                  else
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _InputBar(
                            controller: _controller,
                            onChanged: (v) => context.read<AdminMenuEditViewModel>().setInput(v),
                            onAdd: () => context.read<AdminMenuEditViewModel>().addMenu(),
                            onTapMenu: () {
                              // 다음 단계에서 '자주 쓰는 메뉴' 연동 예정
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('자주 쓰는 메뉴는 다음 단계에서 구현 예정'), duration: Duration(milliseconds: 900)),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          _MenuList(
                            menus: vm.menus,
                            onRemove: (i) => context.read<AdminMenuEditViewModel>().removeMenu(i),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            if (vm.showSavedToast)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(color: const Color(0xFF111827), borderRadius: BorderRadius.circular(999)),
                    child: const Text('저장되었습니다', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WeekNavigator extends StatelessWidget {
  final String mondayId;
  final String selectedId;
  final List<String> days;
  final VoidCallback onPrevWeek;
  final VoidCallback onNextWeek;
  final ValueChanged<String> onSelect;

  const _WeekNavigator({
    required this.mondayId,
    required this.selectedId,
    required this.days,
    required this.onPrevWeek,
    required this.onNextWeek,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    const weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onPrevWeek,
            icon: const Icon(Icons.chevron_left, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            color: const Color(0xFF374151),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (int i = 0; i < days.length; i++)
                  Flexible(
                    child: GestureDetector(
                      onTap: () => onSelect(days[i]),
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 36),
                        height: 52,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: days[i] == selectedId ? const Color(0xFFF97316) : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              weekdayLabels[i.clamp(0, 6)],
                              style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              days[i].substring(8), // DD
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: onNextWeek,
            icon: const Icon(Icons.chevron_right, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            color: const Color(0xFF374151),
          ),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onAdd;
  final VoidCallback onTapMenu;

  const _InputBar({required this.controller, required this.onChanged, required this.onAdd, required this.onTapMenu});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
      child: Row(
        children: [
          InkWell(
            onTap: onTapMenu,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(minWidth: 40),
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.menu, color: Color(0xFF374151), size: 20),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: '메뉴 입력',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 14),
              onChanged: onChanged,
              onSubmitted: (_) => onAdd(),
              textInputAction: TextInputAction.done,
              controller: controller,
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onAdd,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE5E7EB),
              foregroundColor: const Color(0xFF111827),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(60, 40),
            ),
            child: const Text('입력', style: TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

class _MenuList extends StatelessWidget {
  final List<String> menus;
  final ValueChanged<int> onRemove;

  const _MenuList({required this.menus, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    if (menus.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 180),
        child: Text('현재 작성된 메뉴가 없습니다', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14, fontWeight: FontWeight.w600)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < menus.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  child: Text(
                    '${i + 1}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                  ),
                ),
                const SizedBox(width: 12),
                Container(width: 1, height: 20, color: const Color(0xFFD1D5DB)),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED), // orange-50
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        menus[i],
                        style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => onRemove(i),
                        child: const Text(
                          '✕',
                          style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

