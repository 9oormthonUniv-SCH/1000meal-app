import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/store_models.dart';
import '../repositories/store_repository.dart';
import '../viewmodels/store_detail_view_model.dart';

class StoreDetailScreen extends StatelessWidget {
  static const routeName = '/store/detail';

  final int storeId;

  const StoreDetailScreen({super.key, required this.storeId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          StoreDetailViewModel(context.read<StoreRepository>(), storeId)
            ..load(),
      child: const _StoreDetailView(),
    );
  }
}

class _StoreDetailView extends StatelessWidget {
  const _StoreDetailView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StoreDetailViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 50,
        title: const Text(
          '매장 상세페이지',
          style: TextStyle(color: Colors.black, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(child: _buildBody(context, vm)),
    );
  }

  Widget _buildBody(BuildContext context, StoreDetailViewModel vm) {
    if (vm.loading && vm.detail == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.errorMessage != null && vm.detail == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            vm.errorMessage!,
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      );
    }

    final detail = vm.detail;
    if (detail == null) {
      return const Center(child: Text('매장 정보가 없습니다.'));
    }

    return SingleChildScrollView(
      //appbar 아래로 스크롤 가능
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 197,
                height: 220,
                child: _buildStoreImage(
                  detail,
                ), // 이미지 빌더에서 사진을 축소해서 불러오는 방법 찾아야 함
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            detail.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (detail.address != null && detail.address!.isNotEmpty)
            Text(
              detail.address!,
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
          if (detail.phone != null && detail.phone!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                detail.phone!,
                style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
            ),
          const SizedBox(height: 16),
          _buildOpenStatus(detail),
          const Divider(height: 22, thickness: 1.5, color: Color(0xFFF1F1F1)),
          const SizedBox(height: 20),
          const Text(
            '오늘의 메뉴',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          if (detail.menus.isEmpty)
            const Text('메뉴 정보 없음', style: TextStyle(color: Color(0xFF9CA3AF)))
          else
            ...detail.menus.map(
              (menu) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('• $menu', style: const TextStyle(fontSize: 14)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOpenStatus(StoreDetail detail) {
    final isOpen = detail.open == true;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isOpen ? const Color(0xFFDBEAFE) : const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            isOpen ? '영업중' : '영업 종료',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isOpen ? const Color(0xFF2563EB) : const Color(0xFFDC2626),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStoreImage(StoreDetail detail) {
    final url = (detail.imageUrl ?? '').trim();
    if (url.isEmpty) {
      return _buildNoImage();
    }
    final isNetwork = url.startsWith('http://') || url.startsWith('https://');
    if (isNetwork) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildNoImage(),
      );
    }
    return Image.asset(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildNoImage(),
    );
  }

  Widget _buildNoImage() {
    return Container(
      color: const Color(0xFFF3F4F6),
      alignment: Alignment.center,
      child: const Text(
        'No Img',
        style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
      ),
    );
  }
}
