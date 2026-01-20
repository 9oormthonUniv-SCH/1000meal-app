import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/store/models/store_models.dart';
import '../features/store/viewmodels/store_list_view_model.dart';
import 'StoreCard.dart';

class StoreSection extends StatefulWidget {
  const StoreSection({super.key});

  @override
  State<StoreSection> createState() => _StoreSectionState();
}

class _StoreSectionState extends State<StoreSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<StoreListViewModel>().load();
    });
  }

  Store _toUi(StoreListItem item) {
    return Store(
      id: item.id,
      name: item.name,
      menus: item.menus,
      remain: item.remain,
      imageUrl: item.imageUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StoreListViewModel>();
    final stores = vm.items.map(_toUi).toList();

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
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                vm.errorMessage!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
              ),
            )
          else if (stores.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('매장이 없습니다.'),
            )
          else
            ...stores.map((store) {
              return StoreCard(
                store: store,
                onTap: () => debugPrint("${store.name} 클릭됨"),
              );
            }),
        ],
      ),
    );
  }
}
