import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/store_models.dart';
import '../repositories/store_repository.dart';
import '../viewmodels/store_detail_view_model.dart';
import '../widgets/other_store_card.dart';
import '../widgets/weekly_menu_card.dart';

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
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
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
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20.5, 2, 20.5, 20),
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
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                if (detail.address != null && detail.address!.isNotEmpty)
                  Text(
                    detail.address!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                if (detail.phone != null && detail.phone!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      detail.phone!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                _buildOpenStatus(detail),
              ],
            ),
          ),
          Container(
            height: 14,
            width: double.infinity,
            color: const Color(0xFFF1F1F1),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 10, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '일주일 메뉴',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _weekdayDates(DateTime.now()).map((date) {
                      return WeeklyMenuCard(
                        dateLabel: _formatDateLabel(date),
                        dayLabel: _weekdayLabel(date.weekday),
                        items: detail.menus,
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  '다른 매장 보기',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                _buildOtherStores(context, vm),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _weekdayLabel(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return '월요일';
      case DateTime.tuesday:
        return '화요일';
      case DateTime.wednesday:
        return '수요일';
      case DateTime.thursday:
        return '목요일';
      case DateTime.friday:
        return '금요일';
      case DateTime.saturday:
        return '토요일';
      case DateTime.sunday:
        return '일요일';
      default:
        return '';
    }
  }

  String _formatDateLabel(DateTime date) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(date.month)}월 ${two(date.day)}일';
  }

  List<DateTime> _weekdayDates(DateTime today) {
    final startOfWeek = today.subtract(
      Duration(days: today.weekday - DateTime.monday),
    );
    return List.generate(5, (i) => startOfWeek.add(Duration(days: i)));
  }

  Widget _buildOtherStores(BuildContext context, StoreDetailViewModel vm) {
    final stores = vm.otherStores.take(3).toList();
    if (stores.isEmpty) {
      return const SizedBox.shrink();
    }
    final screenWidth = MediaQuery.of(context).size.width;
    return SizedBox(
      height: 189,
      child: Transform.translate(
        offset: const Offset(-20, 0),
        child: SizedBox(
          width: screenWidth,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: stores.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return OtherStoreCard(store: stores[index]);
            },
          ),
        ),
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
