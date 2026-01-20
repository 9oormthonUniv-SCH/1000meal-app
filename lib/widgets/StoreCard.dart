import 'package:flutter/material.dart';
import 'package:meal_app/util/colors.dart';

// 1. 데이터 모델 정의 (React의 StoreListItem 대응)
class Store {
  final int id;
  final String name;
  final String? imageUrl;
  final List<String> menus; // todayMenu.menus 대신 단순화
  final int remain;

  Store({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.menus,
    required this.remain,
  });
}

class StoreCard extends StatelessWidget {
  final Store store;
  final bool isSelected;
  final VoidCallback? onTap;

  const StoreCard({
    super.key,
    required this.store,
    this.isSelected = false, // 기본값 false
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 메뉴 텍스트 로직 (join)
    final String menusText = store.menus.isNotEmpty
        ? store.menus.join(', ')
        : '메뉴 정보 없음';

    return GestureDetector(
      onTap: () {
        onTap?.call();
        // 네비게이션 로직 추가 필요
        // Navigator.push(context, ); -> 각 가게 상세페이지로 이동... 라우팅 ㄱㄱ
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16), // mb-4
        padding: const EdgeInsets.all(12), // p-4
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange[50] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.orange[400]! : Colors.grey[300]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 좌측 매장 이미지
            ClipRRect(
              borderRadius: BorderRadius.circular(8), // rounded-lg
              child: SizedBox(
                width: 48,
                height: 48,
                child: store.imageUrl != null && store.imageUrl!.isNotEmpty
                    ? Image.asset(
                        store.imageUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildNoImage(), //이미지 없는 경우 보여주는 위젯 -> 하단 위젯 참고
                      )
                    : _buildNoImage(),
              ),
            ),

            const SizedBox(width: 16),
            // 가게 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 매장명
                  Text(
                    store.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // 메뉴 목록
                  Text(
                    menusText,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),
            // 남은 개수
            SizedBox(
              width: 64,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${store.remain}개",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      // 색상 로직: 0개면 빨강, 아니면 주황
                      color: store.remain == 0 ? Colors.red : AppColors.primary,
                    ),
                  ),
                  Text(
                    "남았어요!",
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 이미지 없을 때 보여줄 위젯 (No Img)
  Widget _buildNoImage() {
    return Container(
      color: Colors.grey[200],
      alignment: Alignment.center,
      child: Text(
        "No Img",
        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
      ),
    );
  }
}
