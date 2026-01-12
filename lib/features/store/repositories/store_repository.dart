import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/store_models.dart';

// 1. 인터페이스 정의
abstract class StoreRepository {
  Future<List<StoreListItem>> fetchStores();
  Future<StoreDetail> fetchStoreDetail(int storeId);
}

// 2. 실제 구현체 (API 호출)
class StoreRepositoryImpl implements StoreRepository {
  final Dio _dio;
  StoreRepositoryImpl(this._dio);

  @override
  Future<List<StoreListItem>> fetchStores() async {
    try {
      final response = await _dio.get('/api/v1/stores');
      final envelope = ApiEnvelope<List<StoreListItem>>.fromJson(
        response.data,
        (data) =>
            (data as List).map((item) => StoreListItem.fromJson(item)).toList(),
      );
      return envelope.data;
    } catch (e) {
      throw Exception('데이터 로드 실패: $e');
    }
  }

  @override
  Future<StoreDetail> fetchStoreDetail(int storeId) async {
    try {
      final response = await _dio.get('/api/v1/stores/$storeId');
      final envelope = ApiEnvelope<StoreDetail>.fromJson(
        response.data,
        (data) => StoreDetail.fromJson(data),
      );
      return envelope.data;
    } catch (e) {
      throw Exception('매장 상세 정보 로드 실패: $e');
    }
  }
}

// 3. 더미 구현체 (테스트용)
class FakeStoreRepository implements StoreRepository {
  @override
  Future<List<StoreListItem>> fetchStores() async {
    await Future.delayed(const Duration(milliseconds: 500)); // 로딩 흉내
    return [
      StoreListItem(
        id: 1,
        name: "향설 1관",
        address: "학생회관 1층",
        phone: "010-1234-5678",
        description: "든든한 한식 뷔페",
        hours: "08:00-20:00",
        remain: 15,
        lat: 37.5665,
        lng: 126.9780,
        open: true,
        todayMenu: TodayMenu(
          id: 1,
          date: "2024-01-10",
          dayOfWeek: DayOfWeek.monday,
          menus: ["제육볶음", "밥", "된장찌개"],
          open: true,
        ),
      ),
      StoreListItem(
        id: 2,
        name: "향설 2관",
        address: "학생회관 2층",
        phone: "010-2345-6789",
        description: "신선한 샐러드 전문점",
        hours: "09:00-18:00",
        remain: 8,
        lat: 37.5666,
        lng: 126.9781,
        open: true,
        todayMenu: TodayMenu(
          id: 2,
          date: "2024-01-10",
          dayOfWeek: DayOfWeek.monday,
          menus: ["카프레제 샐러드", "퀴노아 볼", "야채 스무디"],
          open: true,
        ),
      ),
      StoreListItem(
        id: 3,
        name: "학생식당",
        address: "본관 지하 1층",
        phone: "010-3456-7890",
        description: "가성비 좋은 학생 식당",
        hours: "07:30-19:30",
        remain: 25,
        lat: 37.5667,
        lng: 126.9782,
        open: true,
        todayMenu: TodayMenu(
          id: 3,
          date: "2024-01-10",
          dayOfWeek: DayOfWeek.monday,
          menus: ["김치찌개", "불고기", "밥", "김치"],
          open: true,
        ),
      ),
      StoreListItem(
        id: 4,
        name: "카페테리아",
        address: "도서관 1층",
        phone: "010-4567-8901",
        description: "커피와 간단한 식사",
        hours: "08:00-22:00",
        remain: 12,
        lat: 37.5668,
        lng: 126.9783,
        open: false, // 영업 종료
        todayMenu: TodayMenu(
          id: 4,
          date: "2024-01-10",
          dayOfWeek: DayOfWeek.monday,
          menus: ["아메리카노", "샌드위치", "쿠키"],
          open: false,
        ),
      ),
    ];
  }

  @override
  Future<StoreDetail> fetchStoreDetail(int storeId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return StoreDetail(
      id: storeId,
      name: "향설 1관 (더미 상세)",
      address: "학생회관 1층",
      phone: "010-0000-0000",
      description: "맛있는 밥이 있는 곳",
      hours: "08:00-09:00",
      lat: 37.0,
      lng: 127.0,
      openTime: const TimeOfDay(hour: 8, minute: 0),
      closeTime: const TimeOfDay(hour: 21, minute: 0),
      remain: 20,
      weeklyMenuResponse: WeeklyMenuResponse(
        storeId: storeId,
        startDate: "2024-01-08",
        endDate: "2024-01-14",
        dailyMenus: [],
      ),
      open: true,
      menus: [
        Menu(
          id: 1,
          name: "제육볶음",
          price: 5000,
          description: "매콤달콤 제육볶음",
          image: null,
          available: true,
        ),
        Menu(
          id: 2,
          name: "밥",
          price: 1000,
          description: "따뜻한 밥",
          image: null,
          available: true,
        ),
      ],
    );
  }
}
