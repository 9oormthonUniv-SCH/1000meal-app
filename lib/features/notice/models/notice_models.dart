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

class NoticeImage {
  final int id;
  final String url;
  final String originalName;
  final String contentType;
  final int size;

  const NoticeImage({
    required this.id,
    required this.url,
    required this.originalName,
    required this.contentType,
    required this.size,
  });

  factory NoticeImage.fromJson(Map<String, dynamic> json) {
    return NoticeImage(
      id: _toInt(json['id']),
      url: (json['url'] ?? '').toString(),
      originalName: (json['originalName'] ?? '').toString(),
      contentType: (json['contentType'] ?? '').toString(),
      size: _toInt(json['size']),
    );
  }
}

class NoticeImagePresign {
  final String s3Key;
  final String url;
  final String uploadUrl;
  final Map<String, String> headers;
  final String originalName;
  final String contentType;
  final int size;
  /// Optional: "PUT" (default, S3 PutObject presigned) or "POST".
  final String method;

  const NoticeImagePresign({
    required this.s3Key,
    required this.url,
    required this.uploadUrl,
    required this.headers,
    required this.originalName,
    required this.contentType,
    required this.size,
    this.method = 'PUT',
  });

  factory NoticeImagePresign.fromJson(Map<String, dynamic> json) {
    final rawHeaders = json['headers'];
    final Map<String, String> headers = {};
    if (rawHeaders is Map) {
      for (final entry in rawHeaders.entries) {
        headers[entry.key.toString()] = (entry.value ?? '').toString();
      }
    }
    final method = (json['method'] ?? 'PUT').toString().toUpperCase();
    return NoticeImagePresign(
      s3Key: (json['s3Key'] ?? '').toString(),
      url: (json['url'] ?? '').toString(),
      uploadUrl: (json['uploadUrl'] ?? '').toString(),
      headers: headers,
      originalName: (json['originalName'] ?? '').toString(),
      contentType: (json['contentType'] ?? '').toString(),
      size: _toInt(json['size']),
      method: method == 'POST' ? 'POST' : 'PUT',
    );
  }
}

class NoticePresignFileRequest {
  final String originalName;
  final String contentType;
  final int size;

  const NoticePresignFileRequest({
    required this.originalName,
    required this.contentType,
    required this.size,
  });

  Map<String, dynamic> toJson() => {
        'originalName': originalName,
        'contentType': contentType,
        'size': size,
      };
}

class NoticePresignRequest {
  final List<NoticePresignFileRequest> files;

  const NoticePresignRequest({required this.files});

  Map<String, dynamic> toJson() => {
        'files': files.map((e) => e.toJson()).toList(growable: false),
      };
}

class NoticeImagesUpsertItem {
  final String s3Key;
  final String url;
  final String originalName;
  final String contentType;
  final int size;

  const NoticeImagesUpsertItem({
    required this.s3Key,
    required this.url,
    required this.originalName,
    required this.contentType,
    required this.size,
  });

  Map<String, dynamic> toJson() => {
        's3Key': s3Key,
        'url': url,
        'originalName': originalName,
        'contentType': contentType,
        'size': size,
      };
}

class NoticeImagesUpsertRequest {
  final List<NoticeImagesUpsertItem> images;

  const NoticeImagesUpsertRequest({required this.images});

  Map<String, dynamic> toJson() => {
        'images': images.map((e) => e.toJson()).toList(growable: false),
      };
}

class Notice {
  final int id;
  final String title;
  final String content;
  final bool isPublished;
  final bool isPinned;
  final String createdAt; // ISO string
  final String updatedAt; // ISO string
  final List<NoticeImage> images;
  /// 목록 API에서 이미지 개수 없이 이미지 존재 여부만 내려줄 때 사용
  final bool hasImage;

  Notice({
    required this.id,
    required this.title,
    required this.content,
    required this.isPublished,
    required this.isPinned,
    required this.createdAt,
    required this.updatedAt,
    this.images = const <NoticeImage>[],
    this.hasImage = false,
  });

  DateTime? get createdAtDateTime => _tryParseDateTime(createdAt);
  DateTime? get updatedAtDateTime => _tryParseDateTime(updatedAt);

  factory Notice.fromJson(Map<String, dynamic> json) {
    final rawImages = json['images'];
    final images = (rawImages is List)
        ? rawImages.whereType<Map<String, dynamic>>().map(NoticeImage.fromJson).toList(growable: false)
        : const <NoticeImage>[];

    return Notice(
      id: _toInt(json['id']),
      title: (json['title'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      isPublished: _toBool(json['isPublished']),
      isPinned: _toBool(json['isPinned']),
      createdAt: (json['createdAt'] ?? '').toString(),
      updatedAt: (json['updatedAt'] ?? '').toString(),
      images: images,
      hasImage: _toBool(json['hasImage']),
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

