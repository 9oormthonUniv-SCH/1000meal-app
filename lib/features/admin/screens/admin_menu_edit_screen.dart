import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/utils/week_kst.dart';
import '../models/menu_models.dart';
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
          toolbarHeight: 48,
          backgroundColor: Colors.white,
          elevation: 0,
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('메뉴 수정', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
              if (vm.groupName.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    vm.groupName,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
                  ),
                ),
            ],
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
            onPressed: () async {
              final ok = await _confirmDiscardIfDirty(vm);
              if (!ok) return;
              if (!context.mounted) return;
              Navigator.of(context).maybePop();
            },
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ElevatedButton(
                onPressed: (vm.saving || vm.groupId == null)
                  ? null
                  : () async {
                      final editVm = context.read<AdminMenuEditViewModel>();
                      await editVm.save();
                      if (!context.mounted) return;
                      if (editVm.errorMessage != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(editVm.errorMessage!),
                            backgroundColor: const Color(0xFFEF4444),
                          ),
                        );
                      }
                    },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF97316),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: const Size(40, 20),
                ),
                child: Text('저장', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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
                  if (vm.errorMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      color: const Color(0xFFFFF1F2),
                      child: Text(
                        vm.errorMessage!,
                        style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13),
                      ),
                    ),
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
                  if (vm.groupId == null)
                    const Expanded(
                      child: Center(
                        child: Text(
                          '메뉴 그룹을 선택해주세요',
                          style: TextStyle(color: Color(0xFF6B7280), fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                    )
                  else if (vm.loading)
                    const Expanded(child: Center(child: CircularProgressIndicator()))
                  else
                    Expanded(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              _InputBar(
                                controller: _controller,
                                onChanged: (v) => context.read<AdminMenuEditViewModel>().setInput(v),
                                onAdd: () => context.read<AdminMenuEditViewModel>().addMenu(),
                                onTapMenu: () async {
                                  final hasMenus = await context.read<AdminMenuEditViewModel>().toggleFrequentMenu();
                                  if (!context.mounted) return;
                                  if (!hasMenus) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('자주 쓰는 메뉴가 없습니다'),
                                        duration: Duration(milliseconds: 1500),
                                      ),
                                    );
                                  }
                                },
                                showFrequentMenu: vm.showFrequentMenu,
                                frequentMenus: vm.frequentMenus,
                                onSelectFrequentMenu: (group) => context.read<AdminMenuEditViewModel>().selectFrequentMenu(group),
                              ),
                              const SizedBox(height: 16),
                              _MenuList(
                                menus: vm.menus,
                                onRemove: (i) => context.read<AdminMenuEditViewModel>().removeMenu(i),
                              ),
                            ],
                          ),
                          // 드롭다운을 Stack의 최상위에 배치
                          if (vm.showFrequentMenu && vm.frequentMenus.isNotEmpty)
                            Positioned(
                              top: 72, // ListView padding(16) + InputBar padding(4) + InputBar height(40) + spacing(12)
                              left: 20, // ListView padding(16) + InputBar padding(4)
                              child: Material(
                                elevation: 8,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 285,
                                  constraints: const BoxConstraints(maxHeight: 300),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                                  ),
                                  child: ListView(
                                    shrinkWrap: true,
                                    children: [
                                      for (int i = 0; i < vm.frequentMenus.length; i++)
                                        InkWell(
                                          onTap: () => context.read<AdminMenuEditViewModel>().selectFrequentMenu(vm.frequentMenus[i]),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                            decoration: BoxDecoration(
                                              border: i < vm.frequentMenus.length - 1
                                                  ? const Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1))
                                                  : null,
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    vm.frequentMenus[i].preview.isNotEmpty
                                                        ? vm.frequentMenus[i].preview
                                                        : vm.frequentMenus[i].menus.join(', '),
                                                    style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF), size: 16),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onPrevWeek,
            icon: const Icon(Icons.chevron_left, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            color: const Color(0xFF374151),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (int i = 0; i < days.length; i++)
                  Flexible(
                    child: GestureDetector(
                      onTap: i >= 5 ? null : () => onSelect(days[i]), // ✅ 토/일 클릭 불가
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 36),
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: (i < 5 && days[i] == selectedId) ? const Color(0xFFF97316) : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              weekdayLabels[i.clamp(0, 6)],
                              style: TextStyle(
                                fontSize: 10,
                                color: i >= 5 ? const Color(0xFFD6D3D1) : const Color(0xFF6B7280), // stone-300 / gray
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              days[i].substring(8), // DD
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: i >= 5 ? const Color(0xFFD6D3D1) : const Color(0xFF111827), // stone-300 / zinc-900
                              ),
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
            icon: const Icon(Icons.chevron_right, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
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
  final bool showFrequentMenu;
  final List<FavoriteGroup> frequentMenus;
  final ValueChanged<FavoriteGroup> onSelectFrequentMenu;

  const _InputBar({
    required this.controller,
    required this.onChanged,
    required this.onAdd,
    required this.onTapMenu,
    required this.showFrequentMenu,
    required this.frequentMenus,
    required this.onSelectFrequentMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
      child: Row(
        children: [
          // 피그마: 햄버거 아이콘(회색), 배경 없음
          InkWell(
            onTap: onTapMenu,
            borderRadius: BorderRadius.circular(12),
            child: const SizedBox(
              width: 40,
              height: 40,
              child: Icon(Icons.menu, color: Color(0xFF9CA3AF), size: 24),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SizedBox(
              height: 40, // 버튼(minimumSize)의 height와 동일
              child: TextField(
                decoration: InputDecoration(
                  hintText: '메뉴 입력',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFD6D3D1), width: 1), // stone-300
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFD6D3D1), width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFD6D3D1), width: 1),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  isDense: true,
                  suffixIconConstraints: const BoxConstraints.tightFor(width: 40, height: 40),
                  // 피그마: 우측 동그란 X(입력 클리어)
                  suffixIcon: controller.text.isEmpty
                      ? null
                      : Center(
                          child: InkWell(
                            onTap: () => onChanged(''),
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              width: 15,
                              height: 15,
                              decoration: const BoxDecoration(
                                color: Color(0xFFA1A1A1), // neutral-400
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(Icons.close, size: 10, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                ),
                style: const TextStyle(fontSize: 14),
                onChanged: onChanged,
                onSubmitted: (_) => onAdd(),
                textInputAction: TextInputAction.done,
                controller: controller,
              ),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: onAdd,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE5E7EB), // zinc-100
              foregroundColor: const Color(0xFF111827),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(60, 40),
            ),
            child: const Text('입력', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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
      return const Center(
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
                    color: const Color(0xFFFFF5F0), // orange-50
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
                      InkWell(
                        onTap: () => onRemove(i),
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          width: 15,
                          height: 15,
                          decoration: const BoxDecoration(
                            color: Color(0xFFA1A1A1), // zinc-300
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(Icons.close, size: 10, color: Colors.white),
                          ),
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

