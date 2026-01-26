import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/admin_frequent_menu_edit_view_model.dart';

class AdminFrequentMenuEditScreen extends StatefulWidget {
  static const routeName = '/admin/menu/frequent/edit';

  final int? groupId; // null이면 새로 만들기, 있으면 수정

  const AdminFrequentMenuEditScreen({super.key, this.groupId});

  @override
  State<AdminFrequentMenuEditScreen> createState() => _AdminFrequentMenuEditScreenState();
}

class _AdminFrequentMenuEditScreenState extends State<AdminFrequentMenuEditScreen> {
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
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AdminFrequentMenuEditViewModel>().init());
  }

  Future<bool> _confirmDiscardIfDirty(AdminFrequentMenuEditViewModel vm) async {
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
    final vm = context.watch<AdminFrequentMenuEditViewModel>();

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
        context.read<AdminFrequentMenuEditViewModel>().hideToast();
      });
    }

    // 확인 모달
    if (vm.showConfirm && vm.pendingAction != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('변경사항이 있어요'),
            content: const Text('저장하지 않고 나갈까요?'),
            actions: [
              TextButton(
                onPressed: () {
                  context.read<AdminFrequentMenuEditViewModel>().setShowConfirm(false);
                  context.read<AdminFrequentMenuEditViewModel>().setPendingAction(null);
                  Navigator.of(context).pop();
                },
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () {
                  context.read<AdminFrequentMenuEditViewModel>().setShowConfirm(false);
                  final action = context.read<AdminFrequentMenuEditViewModel>().pendingAction;
                  context.read<AdminFrequentMenuEditViewModel>().setPendingAction(null);
                  Navigator.of(context).pop();
                  action?.call();
                },
                child: const Text('나가기'),
              ),
            ],
          ),
        );
      });
    }

    return WillPopScope(
      onWillPop: () => _confirmDiscardIfDirty(vm),
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 48,
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(widget.groupId == null ? '자주 쓰는 메뉴 추가' : '자주 쓰는 메뉴 수정',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
            onPressed: () async {
              final ok = await _confirmDiscardIfDirty(vm);
              if (!ok) return;
              if (!context.mounted) return;
              Navigator.of(context).pushNamedAndRemoveUntil('/admin/menu/frequent', (r) => false);
            },
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ElevatedButton(
                onPressed: vm.saving ? null : () => context.read<AdminFrequentMenuEditViewModel>().save(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF97316),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: Size.zero,
                ),
                child: vm.saving
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('저장', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            Container(
              color: const Color(0xFFF5F6F7),
              child: Column(
                children: [
                  if (vm.loading)
                    const Expanded(child: Center(child: CircularProgressIndicator()))
                  else
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _InputBar(
                            controller: _controller,
                            onChanged: (v) => context.read<AdminFrequentMenuEditViewModel>().setInput(v),
                            onAdd: () => context.read<AdminFrequentMenuEditViewModel>().addMenu(),
                          ),
                          const SizedBox(height: 16),
                          _MenuList(
                            menus: vm.menus,
                            onRemove: (i) => context.read<AdminFrequentMenuEditViewModel>().removeMenu(i),
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

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onAdd;

  const _InputBar({required this.controller, required this.onChanged, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
      child: Row(
        children: [
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
