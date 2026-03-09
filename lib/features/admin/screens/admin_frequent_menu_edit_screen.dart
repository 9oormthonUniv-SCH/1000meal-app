import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:meal_app/util/colors.dart';
import 'package:meal_app/util/typography.dart';
import '../../../common/widgets/app_bar_common.dart';
import '../../../common/widgets/app_confirm_dialog.dart';
import '../viewmodels/admin_frequent_menu_edit_view_model.dart';

class AdminFrequentMenuEditScreen extends StatefulWidget {
  static const routeName = '/admin/menu/frequent/edit';

  final int groupId; // 일일 메뉴 그룹 ID (필수)
  final int? presetId; // null이면 새로 만들기, 있으면 수정

  const AdminFrequentMenuEditScreen({
    super.key,
    required this.groupId,
    this.presetId,
  });

  @override
  State<AdminFrequentMenuEditScreen> createState() =>
      _AdminFrequentMenuEditScreenState();
}

class _AdminFrequentMenuEditScreenState
    extends State<AdminFrequentMenuEditScreen> {
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
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<AdminFrequentMenuEditViewModel>().init(),
    );
  }

  Future<bool> _confirmDiscardIfDirty(AdminFrequentMenuEditViewModel vm) async {
    if (!vm.dirty) return true;
    final ok = await AppConfirmDialog.showDiscard(context);
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
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final vm2 = context.read<AdminFrequentMenuEditViewModel>();
        final action = vm2.pendingAction;
        vm2.setShowConfirm(false);
        vm2.setPendingAction(null);
        if (!mounted) return;
        final ok = await AppConfirmDialog.showDiscard(context);
        if (ok == true && action != null) action();
      });
    }

    return WillPopScope(
      onWillPop: () async {
        final ok = await _confirmDiscardIfDirty(vm);
        return ok;
      },
      child: Scaffold(
        appBar: AppBarCommon(
          toolbarHeight: 48,
          title: widget.presetId == null ? '자주 쓰는 메뉴 추가' : '자주 쓰는 메뉴 수정',
          centerTitle: true,
          onBackPressed: () async {
            final ok = await _confirmDiscardIfDirty(vm);
            if (!ok) return;
            if (!context.mounted) return;
            Navigator.of(context).maybePop();
          },
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ElevatedButton(
                onPressed:
                    (vm.saving || !vm.dirty) // 저장 중이거나 변경사항이 없으면 비활성화
                    ? null
                    : () async {
                        await context
                            .read<AdminFrequentMenuEditViewModel>()
                            .save();
                        if (!context.mounted) return;
                        // 저장 성공 시 토스트 후 이전 화면으로 이동
                        final savedVm = context
                            .read<AdminFrequentMenuEditViewModel>();
                        if (savedVm.errorMessage == null) {
                          await Future.delayed(
                            const Duration(milliseconds: 400),
                          ); // 0.4초 대기 (저장되었습니다 토스트가 보이도록)
                          if (!context.mounted) return;
                          Navigator.of(context).pop(true); //저장 완료되면 이전 화면으로 pop
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                ),
                child: vm.saving
                    ? SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : Text(
                        '저장',
                        style: AppTypography.body3.copyWith(
                          color: vm.dirty ? AppColors.white : AppColors.white.withValues(alpha: 0.6),
                        ),
                      ),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            Container(
              color: AppColors.gray1,
              child: Column(
                children: [
                  if (vm.loading)
                    const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _InputBar(
                            controller: _controller,
                            onChanged: (v) => context
                                .read<AdminFrequentMenuEditViewModel>()
                                .setInput(v),
                            onAdd: () => context
                                .read<AdminFrequentMenuEditViewModel>()
                                .addMenu(),
                          ),
                          const SizedBox(height: 16),
                          _MenuList(
                            menus: vm.menus,
                            onRemove: (i) => context
                                .read<AdminFrequentMenuEditViewModel>()
                                .removeMenu(i),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.black,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '저장되었습니다',
                      style: AppTypography.caption2.copyWith(
                        color: AppColors.white,
                      ),
                    ),
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

  const _InputBar({
    required this.controller,
    required this.onChanged,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 40,
              child: TextField(
                decoration: InputDecoration(
                  hintText: '메뉴 입력',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.gray4,
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.gray4,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.gray4,
                      width: 1,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  isDense: true,
                  suffixIconConstraints: const BoxConstraints.tightFor(
                    width: 40,
                    height: 40,
                  ),
                  suffixIcon: controller.text.isEmpty
                      ? null
                      : Center(
                          child: InkWell(
                            onTap: () => onChanged(''),
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              width: 15,
                              height: 15,
                              decoration: BoxDecoration(
                                color: AppColors.gray6,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.close,
                                  size: 10,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
                style: AppTypography.body4,
                onChanged: onChanged,
                onSubmitted: (_) => onAdd(),
                textInputAction: TextInputAction.done,
                controller: controller,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onAdd,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gray3,
              foregroundColor: AppColors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(60, 40),
            ),
            child: Text('입력', style: AppTypography.body3),
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
      return Center(
        child: Text(
          '현재 작성된 메뉴가 없습니다',
          style: AppTypography.body3.copyWith(color: AppColors.gray6),
        ),
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
                    style: AppTypography.body4.copyWith(
                      color: AppColors.gray7,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(width: 1, height: 20, color: AppColors.gray4),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.orangeSelected,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        menus[i],
                        style: AppTypography.body4.copyWith(
                          color: AppColors.gray8,
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => onRemove(i),
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          width: 15,
                          height: 15,
                          decoration: BoxDecoration(
                            color: AppColors.gray6,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              Icons.close,
                              size: 10,
                              color: AppColors.white,
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
      ],
    );
  }
}
