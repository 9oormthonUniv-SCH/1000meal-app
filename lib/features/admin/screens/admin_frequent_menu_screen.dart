import 'package:flutter/material.dart';
import 'package:meal_app/util/colors.dart';
import 'package:meal_app/util/typography.dart';
import 'package:provider/provider.dart';

import '../../../common/widgets/app_bar_common.dart';
import '../../../common/widgets/app_confirm_dialog.dart';
import '../models/menu_models.dart';
import '../viewmodels/admin_frequent_menu_view_model.dart';
import 'admin_frequent_menu_edit_screen.dart';

class AdminFrequentMenuScreen extends StatefulWidget {
  static const routeName = '/admin/menu/frequent';

  final int groupId; // 일일 메뉴 그룹 ID (필수)

  const AdminFrequentMenuScreen({super.key, required this.groupId});

  @override
  State<AdminFrequentMenuScreen> createState() =>
      _AdminFrequentMenuScreenState();
}

class _AdminFrequentMenuScreenState extends State<AdminFrequentMenuScreen> {
  bool _loaded = false;
  bool _selectMode = false;
  final Set<int> _selectedIds = <int>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<AdminFrequentMenuViewModel>().init(),
    );
  }

  void _toggleSelect(int groupId) {
    setState(() {
      if (_selectedIds.contains(groupId)) {
        _selectedIds.remove(groupId);
      } else {
        _selectedIds.add(groupId);
      }
    });
  }

  Future<void> _handleDelete() async {
    if (_selectedIds.isEmpty) return;
    final vm = context.read<AdminFrequentMenuViewModel>();
    await vm.deleteGroups(_selectedIds.toList());
    setState(() {
      _selectedIds.clear();
      _selectMode = false;
    });
  }

  Widget _buildRightElement() {
    if (_selectMode) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectMode = false;
                _selectedIds.clear();
              });
            },
            child: Text(
              '취소',
              style: AppTypography.body3.copyWith(
                color: AppColors.gray7,
              ),
            ),
          ),
          TextButton(
            onPressed: _selectedIds.isEmpty
                ? null
                : () async {
                    final confirmed = await AppConfirmDialog.showDelete(
                      context,
                      content: '이 동작은 취소할 수 없습니다\n삭제하시겠습니까?',
                      cancelLabel: '아니요',
                      confirmLabel: '삭제',
                    );
                    if (confirmed == true) {
                      await _handleDelete();
                    }
                  },
            style: TextButton.styleFrom(
              foregroundColor: _selectedIds.isEmpty
                  ? AppColors.gray6
                  : AppColors.orange,
            ),
            child: Text('삭제', style: AppTypography.body3),
          ),
        ],
      );
    } else {
      return TextButton(
        onPressed: () {
          setState(() {
            _selectMode = true;
          });
        },
        child: Text(
          '선택',
          style: AppTypography.body3.copyWith(color: AppColors.gray6),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminFrequentMenuViewModel>();

    return Scaffold(
      appBar: AppBarCommon(
        toolbarHeight: 48,
        title: _selectMode ? '' : '자주 쓰는 메뉴',
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildRightElement(),
          ),
        ],
      ),
      floatingActionButton: _selectMode
          ? null
          : FloatingActionButton(
              onPressed: () async {
                await Navigator.of(context).pushNamed(
                  AdminFrequentMenuEditScreen.routeName,
                  arguments: {'groupId': widget.groupId},
                );
                if (!context.mounted) return;
                context.read<AdminFrequentMenuViewModel>().refresh();
              },
              backgroundColor: AppColors.gray4,
              child: Icon(Icons.add, color: AppColors.white),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Container(
        color: AppColors.gray1,
        child: vm.loading && vm.groups.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: vm.groups.isEmpty
                        ? Center(
                            child: Text(
                              '자주 쓰는 메뉴가 없습니다',
                              style: AppTypography.body4.copyWith(
                                color: AppColors.gray6,
                              ),
                            ),
                          )
                        : RefreshIndicator.adaptive(
                            onRefresh: () => context
                                .read<AdminFrequentMenuViewModel>()
                                .refresh(),
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              padding: const EdgeInsets.all(16),
                              itemCount: vm.groups.length,
                              itemBuilder: (context, index) {
                                final group = vm.groups[index];
                                return _FrequentMenuRow(
                                  group: group,
                                  selectMode: _selectMode,
                                  isSelected: _selectedIds.contains(group.id),
                                  onTap: () async {
                                    if (_selectMode) {
                                      _toggleSelect(group.id);
                                    } else {
                                      await Navigator.of(context).pushNamed(
                                        AdminFrequentMenuEditScreen.routeName,
                                        arguments: {
                                          'groupId': widget.groupId,
                                          'presetId': group.id,
                                        },
                                      );
                                      if (!context.mounted) return;
                                      context
                                          .read<AdminFrequentMenuViewModel>()
                                          .refresh();
                                    }
                                  },
                                );
                              },
                            ),
                          ),
                  ),
                  if (vm.errorMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      color: AppColors.error.withValues(alpha: 0.08),
                      child: Text(
                        vm.errorMessage!,
                        style: AppTypography.caption2.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _FrequentMenuRow extends StatelessWidget {
  final FavoriteGroup group;
  final bool selectMode;
  final bool isSelected;
  final VoidCallback onTap;

  const _FrequentMenuRow({
    required this.group,
    required this.selectMode,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.gray3, width: 1)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  group.preview.isNotEmpty
                      ? group.preview
                      : group.menus.join(', '),
                  style: AppTypography.body4.copyWith(color: AppColors.black),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (selectMode)
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => onTap(),
                  activeColor: AppColors.orange,
                )
              else
                Icon(
                  Icons.chevron_right,
                  color: AppColors.gray6,
                  size: 25,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
