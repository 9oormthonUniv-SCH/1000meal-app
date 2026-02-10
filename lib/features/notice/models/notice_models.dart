int _toInt(dynamic v) => v is int ? v : int.tryParse((v ?? '').toString()) ?? 0;
bool _toBool(dynamic v) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  final s = v?.toString().trim().toLowerCase();
  if (s == null || s.isEmpty) return false;
  return s == 'true' || s == '1' || s == 'y' || s == 'yes';
}

DateTime? _tryParseDateTime(String? raw) {
  if (raw == null) return null;
  final s = raw.trim();
  if (s.isEmpty) return null;
  return DateTime.tryParse(s);
}

class Notice {
  final int id;
  final String title;
  final String content;
  final bool isPublished;
  final bool isPinned;
  final String createdAt; // ISO string
  final String updatedAt; // ISO string

  Notice({
    required this.id,
    required this.title,
    required this.content,
    required this.isPublished,
    required this.isPinned,
    required this.createdAt,
    required this.updatedAt,
  });

  DateTime? get createdAtDateTime => _tryParseDateTime(createdAt);
  DateTime? get updatedAtDateTime => _tryParseDateTime(updatedAt);

  factory Notice.fromJson(Map<String, dynamic> json) {
    return Notice(
      id: _toInt(json['id']),
      title: (json['title'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      isPublished: _toBool(json['isPublished']),
      isPinned: _toBool(json['isPinned']),
      createdAt: (json['createdAt'] ?? '').toString(),
      updatedAt: (json['updatedAt'] ?? '').toString(),
    );
  }
}

/// 공지 작성/수정 공용 요청 모델.
///
/// - UI에서는 `isPublished`를 노출하지 않고, 서버 정책에 따라 default 처리되는 것을 가정.
/// - 백엔드에서 필드가 필수면 `isPublished=true`로 고정해서 보냄.
class NoticeUpsertRequest {
  final String title;
  final String content;
  final bool isPinned;
  final bool isPublished;

  NoticeUpsertRequest({
    required this.title,
    required this.content,
    required this.isPinned,
    this.isPublished = true,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'content': content,
        'isPublished': isPublished,
        'isPinned': isPinned,
      };
}

