import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/menu_models.dart';
import '../viewmodels/admin_frequent_menu_view_model.dart';
import 'admin_frequent_menu_edit_screen.dart';

class AdminFrequentMenuScreen extends StatefulWidget {
  static const routeName = '/admin/menu/frequent';

  const AdminFrequentMenuScreen({super.key});

  @override
  State<AdminFrequentMenuScreen> createState() => _AdminFrequentMenuScreenState();
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
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AdminFrequentMenuViewModel>().init());
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
            child: const Text('취소', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
          ),
          TextButton(
            onPressed: _selectedIds.isEmpty
                ? null
                : () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('삭제하시겠습니까?'),
                        content: const Text('이 동작은 취소할 수 없습니다'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('취소'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('삭제', style: TextStyle(color: Color(0xFFEF4444))),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await _handleDelete();
                    }
                  },
            style: TextButton.styleFrom(
              foregroundColor: _selectedIds.isEmpty ? const Color(0xFF9CA3AF) : const Color(0xFFF97316),
            ),
            child: const Text('삭제', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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
        child: const Text('선택', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminFrequentMenuViewModel>();

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(_selectMode ? '' : '자주 쓰는 메뉴', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
          onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/admin/menu', (r) => false),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildRightElement(),
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFFF5F6F7),
        child: vm.loading && vm.groups.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: vm.groups.isEmpty
                        ? const Center(child: Text('자주 쓰는 메뉴가 없습니다', style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF))))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: vm.groups.length,
                            itemBuilder: (context, index) {
                              final group = vm.groups[index];
                              return _FrequentMenuRow(
                                group: group,
                                selectMode: _selectMode,
                                isSelected: _selectedIds.contains(group.groupId),
                                onTap: () {
                                  if (_selectMode) {
                                    _toggleSelect(group.groupId);
                                  } else {
                                    Navigator.of(context).pushNamed(
                                      AdminFrequentMenuEditScreen.routeName,
                                      arguments: group.groupId,
                                    );
                                  }
                                },
                              );
                            },
                          ),
                  ),
                  if (vm.errorMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      color: const Color(0xFFFFF1F2),
                      child: Text(vm.errorMessage!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
                    ),
                  if (!_selectMode)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: FloatingActionButton(
                          onPressed: () => Navigator.of(context).pushNamed(AdminFrequentMenuEditScreen.routeName),
                          backgroundColor: const Color(0xFFD1D5DB),
                          child: const Icon(Icons.add, color: Colors.white),
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
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
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
                  group.menu.join(', '),
                  style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (selectMode)
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => onTap(),
                  activeColor: const Color(0xFFE5E7EB),
                )
              else
                const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
