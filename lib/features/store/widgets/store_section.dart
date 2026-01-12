import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/store_view_model.dart';
import 'store_card.dart';

class StoreSection extends StatelessWidget {
  const StoreSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StoreViewModel>(
      builder: (context, viewModel, child) {
        // 로딩 상태
        if (viewModel.isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        // 에러 상태
        if (viewModel.error != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Text(
                    '데이터를 불러오는데 실패했습니다',
                    style: TextStyle(color: Colors.red[600]),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => viewModel.loadStores(),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            ),
          );
        }

        // 데이터 없음
        if (viewModel.stores.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('등록된 매장이 없습니다'),
            ),
          );
        }

        // 매장 목록 표시
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: viewModel.stores.map((store) {
              return StoreCard(
                store: store,
                onTap: () => _handleStoreTap(context, store),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _handleStoreTap(BuildContext context, store) {
    print("${store.name} 클릭됨");
    // TODO: 매장 상세 페이지로 네비게이션
    // Navigator.push(context, MaterialPageRoute(
    //   builder: (context) => StoreDetailPage(storeId: store.id),
    // ));
  }
}
