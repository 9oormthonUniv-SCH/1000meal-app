import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:meal_app/util/colors.dart';

import '../features/store/screens/store_detail_screen.dart';
import '../features/store/viewmodels/store_list_view_model.dart';
import 'StoreCard.dart';

class StoreSection extends StatefulWidget {
  const StoreSection({super.key});

  @override
  State<StoreSection> createState() => _StoreSectionState();
}

class _StoreSectionState extends State<StoreSection> {
  int? _selectedStoreId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<StoreListViewModel>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StoreListViewModel>();
    final stores = vm.items;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          if (vm.loading && stores.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (vm.errorMessage != null && stores.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    vm.errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.gray7,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: vm.loading ? null : vm.load,
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            )
          else if (stores.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  '등록된 매장 정보가 없습니다.',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.gray7,
                  ),
                ),
              ),
            )
          else
            ...stores.map((store) {
              return StoreCard(
                store: store,
                isSelected: _selectedStoreId == store.id,
                onTap: () {
                  setState(() => _selectedStoreId = store.id);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => StoreDetailScreen(storeId: store.id),
                    ),
                  );
                },
              );
            }),
        ],
      ),
    );
  }
}
