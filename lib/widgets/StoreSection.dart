import 'package:flutter/material.dart';
import 'StoreCard.dart'; // StoreCard 파일 import 필수

class StoreSection extends StatelessWidget {
  const StoreSection({super.key});

  @override
  Widget build(BuildContext context) {
    // 더미 데이터
    final List<Store> dummyStores = [
      Store(
        id: 1,
        name: "향설 1관",
        menus: ["현미밥", "제육볶음", "미역국", "샐러드"],
        remain: 20,
        imageUrl: "assets/icon/dorm_1.png",
      ),
      Store(
        id: 2,
        name: "야외 그라찌에",
        menus: ["소보로빵", "요거트", "우유"],
        remain: 30,
        imageUrl: "assets/icon/grazie_outside.png",
      ),
      Store(
        id: 3,
        name: "베이커리 경",
        menus: ["인절미", "쿠키", "음료 중 택 1"],
        remain: 10,
        imageUrl: "assets/icon/bakery_kyung.png",
      ),
      Store(
        id: 4,
        name: "향설 2관",
        menus: [], // 메뉴 없음
        remain: 0, // 품절 (빨간색)
        imageUrl: "assets/icon/dorm_2.png",
      ),
    ];

    // 2. Column 구조 사용 (스크롤은 메인 페이지에 맡김)
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0), // 좌우 여백 유지
      child: Column(
        children: dummyStores.map((store) {
          return StoreCard(
            store: store,
            onTap: () => print("${store.name} 클릭됨"),
          );
        }).toList(),
      ),
    );
  }
}
