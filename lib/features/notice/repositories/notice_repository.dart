import '../../../common/dio/api_exception.dart';
import '../../auth/repositories/auth_repository.dart';
import '../data/notice_api.dart';
import '../models/notice_models.dart';

class NoticeRepository {
  final AuthRepository _authRepo;
  final NoticeApi _api;

  NoticeRepository({required AuthRepository authRepo, required NoticeApi api})
      : _authRepo = authRepo,
        _api = api;

  Future<String> _requireToken() async {
    final token = await _authRepo.getAccessToken();
    if (token == null || token.isEmpty) throw ApiException('로그인이 필요합니다.');
    return token;
  }

  Future<List<Notice>> getNotices() async {
    final token = await _authRepo.getAccessToken();
    return _api.getNotices(token: token);
  }

  Future<Notice> getNotice({required int id}) async {
    final token = await _authRepo.getAccessToken();
    return _api.getNotice(id: id, token: token);
  }

  Future<Notice> createNotice({required NoticeUpsertRequest request}) async {
    final token = await _requireToken();
    return _api.createNotice(request: request, token: token);
  }

  Future<Notice> updateNotice({required int id, required NoticeUpsertRequest request}) async {
    final token = await _requireToken();
    return _api.updateNotice(id: id, request: request, token: token);
  }

  Future<void> deleteNotice({required int id}) async {
    final token = await _requireToken();
    await _api.deleteNotice(id: id, token: token);
  }

  Future<List<NoticeImagePresign>> presignNoticeImages({
    required int id,
    required NoticePresignRequest request,
  }) async {
    final token = await _requireToken();
    return _api.presignNoticeImages(id: id, request: request, token: token);
  }

  Future<List<NoticeImage>> registerNoticeImages({
    required int id,
    required NoticeImagesUpsertRequest request,
  }) async {
    final token = await _requireToken();
    return _api.registerNoticeImages(id: id, request: request, token: token);
  }

  Future<void> uploadToPresignedUrl({
    required String uploadUrl,
    required List<int> bytes,
    required Map<String, String> headers,
    String method = 'PUT',
  }) async {
    await _api.uploadToPresignedUrl(uploadUrl: uploadUrl, bytes: bytes, headers: headers, method: method);
  }
}

