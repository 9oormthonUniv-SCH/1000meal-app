import 'package:flutter/material.dart';

// Enums
enum DayOfWeek {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday,
}

// 제네릭을 활용하여 재사용 가능한 API 응답 래퍼 클래스
class ApiEnvelope<T> {
  final T data;
  final ApiResult result;

  ApiEnvelope({required this.data, required this.result});

  factory ApiEnvelope.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    return ApiEnvelope(
      data: fromJson(json['data']),
      result: ApiResult.fromJson(json['result']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'data': data, 'result': result.toJson()};
  }
}

class ApiResult {
  final String code;
  final String message;
  final String timestamp;

  ApiResult({
    required this.code,
    required this.message,
    required this.timestamp,
  });

  factory ApiResult.fromJson(Map<String, dynamic> json) {
    return ApiResult(
      code: json['code'],
      message: json['message'],
      timestamp: json['timestamp'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'code': code, 'message': message, 'timestamp': timestamp};
  }
}

class StoreListItem {
  final int id;
  final String? imageUrl;
  final String name;
  final String address;
  final String phone;
  final String description;
  final String hours;
  final int remain;
  final double lat;
  final double lng;
  final TodayMenu? todayMenu;
  final bool open;

  StoreListItem({
    required this.id,
    this.imageUrl,
    required this.name,
    required this.address,
    required this.phone,
    required this.description,
    required this.hours,
    required this.remain,
    required this.lat,
    required this.lng,
    this.todayMenu,
    required this.open,
  });

  factory StoreListItem.fromJson(Map<String, dynamic> json) {
    return StoreListItem(
      id: json['id'],
      imageUrl: json['imageUrl'],
      name: json['name'],
      address: json['address'],
      phone: json['phone'],
      description: json['description'],
      hours: json['hours'],
      remain: json['remain'],
      lat: json['lat'].toDouble(),
      lng: json['lng'].toDouble(),
      todayMenu: json['todayMenu'] != null
          ? TodayMenu.fromJson(json['todayMenu'])
          : null,
      open: json['open'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imageUrl': imageUrl,
      'name': name,
      'address': address,
      'phone': phone,
      'description': description,
      'hours': hours,
      'remain': remain,
      'lat': lat,
      'lng': lng,
      'todayMenu': todayMenu?.toJson(),
      'open': open,
    };
  }
}

class TodayMenu {
  final int id;
  final String date;
  final DayOfWeek dayOfWeek;
  final List<String> menus;
  final bool open;

  TodayMenu({
    required this.id,
    required this.date,
    required this.dayOfWeek,
    required this.menus,
    required this.open,
  });

  factory TodayMenu.fromJson(Map<String, dynamic> json) {
    return TodayMenu(
      id: json['id'],
      date: json['date'],
      dayOfWeek: DayOfWeek.values.firstWhere(
        (e) => e.name.toUpperCase() == json['dayOfWeek'],
      ),
      menus: List<String>.from(json['menus']),
      open: json['open'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'dayOfWeek': dayOfWeek.name.toUpperCase(),
      'menus': menus,
      'open': open,
    };
  }
}

class StoreDetail {
  final int id;
  final String? imageUrl;
  final String name;
  final String address;
  final String phone;
  final String description;
  final TimeOfDay openTime;
  final TimeOfDay closeTime;
  final int remain;
  final String hours;
  final double lat;
  final double lng;
  final WeeklyMenuResponse weeklyMenuResponse;
  final bool open;
  final List<Menu> menus;

  StoreDetail({
    required this.id,
    this.imageUrl,
    required this.name,
    required this.address,
    required this.phone,
    required this.description,
    required this.openTime,
    required this.closeTime,
    required this.remain,
    required this.hours,
    required this.lat,
    required this.lng,
    required this.weeklyMenuResponse,
    required this.open,
    required this.menus,
  });

  factory StoreDetail.fromJson(Map<String, dynamic> json) {
    return StoreDetail(
      id: json['id'],
      imageUrl: json['imageUrl'],
      name: json['name'],
      address: json['address'],
      phone: json['phone'],
      description: json['description'],
      openTime: _parseTime(json['openTime']),
      closeTime: _parseTime(json['closeTime']),
      remain: json['remain'],
      hours: json['hours'],
      lat: json['lat'].toDouble(),
      lng: json['lng'].toDouble(),
      weeklyMenuResponse: WeeklyMenuResponse.fromJson(
        json['weeklyMenuResponse'],
      ),
      open: json['open'],
      menus: (json['menus'] as List)
          .map((item) => Menu.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imageUrl': imageUrl,
      'name': name,
      'address': address,
      'phone': phone,
      'description': description,
      'openTime': _timeToJson(openTime),
      'closeTime': _timeToJson(closeTime),
      'remain': remain,
      'hours': hours,
      'lat': lat,
      'lng': lng,
      'weeklyMenuResponse': weeklyMenuResponse.toJson(),
      'open': open,
    };
  }

  static TimeOfDay _parseTime(Map<String, dynamic> json) {
    return TimeOfDay(hour: json['hour'], minute: json['minute']);
  }

  static Map<String, dynamic> _timeToJson(TimeOfDay time) {
    return {'hour': time.hour, 'minute': time.minute, 'second': 0, 'nano': 0};
  }
}

class WeeklyMenuResponse {
  final int storeId;
  final String startDate;
  final String endDate;
  final List<DailyMenu> dailyMenus;

  WeeklyMenuResponse({
    required this.storeId,
    required this.startDate,
    required this.endDate,
    required this.dailyMenus,
  });

  factory WeeklyMenuResponse.fromJson(Map<String, dynamic> json) {
    return WeeklyMenuResponse(
      storeId: json['storeId'],
      startDate: json['startDate'],
      endDate: json['endDate'],
      dailyMenus: (json['dailyMenus'] as List)
          .map((item) => DailyMenu.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'storeId': storeId,
      'startDate': startDate,
      'endDate': endDate,
      'dailyMenus': dailyMenus.map((item) => item.toJson()).toList(),
    };
  }
}

class DailyMenu {
  final int id;
  final String date;
  final DayOfWeek dayOfWeek;
  final List<String> menus;
  final bool open;

  DailyMenu({
    required this.id,
    required this.date,
    required this.dayOfWeek,
    required this.menus,
    required this.open,
  });

  factory DailyMenu.fromJson(Map<String, dynamic> json) {
    return DailyMenu(
      id: json['id'],
      date: json['date'],
      dayOfWeek: DayOfWeek.values.firstWhere(
        (e) => e.name.toUpperCase() == json['dayOfWeek'],
      ),
      menus: List<String>.from(json['menus']),
      open: json['open'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'dayOfWeek': dayOfWeek.name.toUpperCase(),
      'menus': menus,
      'open': open,
    };
  }
}

class Menu {
  final int id;
  final String name;
  final int price;
  final String? description;
  final String? image;
  final bool available;

  Menu({
    required this.id,
    required this.name,
    required this.price,
    this.description,
    this.image,
    required this.available,
  });

  factory Menu.fromJson(Map<String, dynamic> json) {
    return Menu(
      id: json['id'],
      name: json['name'],
      price: json['price'],
      description: json['description'],
      image: json['image'],
      available: json['available'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'description': description,
      'image': image,
      'available': available,
    };
  }
}
