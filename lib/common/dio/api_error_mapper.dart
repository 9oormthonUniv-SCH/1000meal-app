import 'api_exception.dart';

/// Next.js의 `extractServerMessage()` 규칙을 최대한 비슷하게 따라감:
/// - errors[0].reason
/// - result.message
/// - message
/// - fallback
String mapErrorToMessage(Object error, {Object? responseData}) {
  Object? body = responseData;
  if (error is ApiException && body == null) body = error.details;

  if (body is Map) {
    final errors = body['errors'];
    if (errors is List && errors.isNotEmpty) {
      final first = errors.first;
      if (first is Map && first['reason'] is String) {
        final reason = first['reason'] as String;
        if (reason.isNotEmpty) return reason;
      }
    }

    final result = body['result'];
    if (result is Map && result['message'] is String) {
      final msg = result['message'] as String;
      if (msg.isNotEmpty) return msg;
    }

    final message = body['message'];
    if (message is String && message.isNotEmpty) return message;
  }

  if (error is ApiException && error.message.isNotEmpty) return error.message;
  return '요청 처리 중 오류가 발생했습니다.';
}


