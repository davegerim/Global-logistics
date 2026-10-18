import 'package:dio/dio.dart';

/// Non-admin endpoints from OpenAPI (mobile: driver).
class BackendApi {
  BackendApi(this._dio);
  final Dio _dio;

  // --- auth ---
  Future<Map<String, dynamic>> authLogin({
    required String phone,
    required String password,
  }) async {
    final r = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'phone': phone, 'password': password},
    );
    return r.data ?? {};
  }

  Future<Map<String, dynamic>> authRegister({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String role,
    required String password,
    required String confirmPassword,
  }) async {
    final r = await _dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: {
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': phoneNumber,
        'role': role,
        'password': password,
        'confirmPassword': confirmPassword,
      },
    );
    return r.data ?? {};
  }

  Future<void> authOtpSend(String phone) async {
    await _dio.post<void>('/auth/otp/send', data: {'phone': phone});
  }

  Future<Map<String, dynamic>> authOtpVerify({
    required String phone,
    required String code,
  }) async {
    final r = await _dio.post<Map<String, dynamic>>(
      '/auth/otp/verify',
      data: {'phone': phone, 'code': code},
    );
    return r.data ?? {};
  }

  Future<void> authForgetPassword(String phone) async {
    await _dio.post<void>('/auth/forget-password', data: {'phone': phone});
  }

  Future<void> authResetPassword({
    required String phone,
    required String otpCode,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _dio.post<void>(
      '/auth/reset-password',
      data: {
        'phone': phone,
        'otpCode': otpCode,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
    );
  }

  Future<void> authChangePassword({
    required String phone,
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _dio.post<void>(
      '/auth',
      data: {
        'phone': phone,
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
    );
  }

  Future<void> authLogout() async {
    await _dio.put<void>('/sign-out/all');
  }

  // --- identity ---
  Future<Map<String, dynamic>> identityGet() async {
    final r = await _dio.get<Map<String, dynamic>>('/identity');
    return r.data ?? {};
  }

  Future<Map<String, dynamic>> identityPut(Map<String, dynamic> body) async {
    final r = await _dio.put<Map<String, dynamic>>('/identity', data: body);
    return r.data ?? {};
  }

  Future<void> identityVerifyPhone(String publicId) async {
    await _dio.put<void>('/identity/verify-phone/$publicId');
  }

  // --- driver profile ---
  Future<Map<String, dynamic>> driversProfile() async {
    final r = await _dio.get<Map<String, dynamic>>('/drivers/profile');
    return r.data ?? {};
  }

  Future<void> driversUpdate({
    String? profilePic,
    String? nationalId,
    String? nationalIdImg,
    String? licenceNumber,
    String? licenceDocument,
    String? preferredLanes,
  }) async {
    final payload = <String, dynamic>{};
    if (profilePic != null) payload['profilePic'] = profilePic;
    if (nationalId != null) payload['nationalId'] = nationalId;
    if (nationalIdImg != null) payload['nationalIdImg'] = nationalIdImg;
    if (licenceNumber != null) payload['licenceNumber'] = licenceNumber;
    if (licenceDocument != null) payload['licenceDocument'] = licenceDocument;
    if (preferredLanes != null) payload['preferredLanes'] = preferredLanes;
    await _dio.post<void>('/drivers/update', data: payload);
  }

  Future<void> driversCreate({
    String? profilePic,
    String? nationalId,
    String? nationalIdImg,
    String? licenceNumber,
    String? licenceDocument,
    String? preferredLanes,
  }) async {
    final payload = <String, dynamic>{};
    if (profilePic != null) payload['profilePic'] = profilePic;
    if (nationalId != null) payload['nationalId'] = nationalId;
    if (nationalIdImg != null) payload['nationalIdImg'] = nationalIdImg;
    if (licenceNumber != null) payload['licenceNumber'] = licenceNumber;
    if (licenceDocument != null) payload['licenceDocument'] = licenceDocument;
    if (preferredLanes != null) payload['preferredLanes'] = preferredLanes;
    await _dio.post<void>('/drivers/create', data: payload);
  }

  // --- vehicles ---
  Future<Map<String, dynamic>> vehiclesCreate(Map<String, dynamic> body) async {
    final r = await _dio.post<Map<String, dynamic>>(
      '/vehicles/create',
      data: body,
    );
    return r.data ?? {};
  }

  Future<Map<String, dynamic>> vehiclesProfile(String driverId) async {
    final r = await _dio.get<Map<String, dynamic>>(
      '/vehicles/profile/$driverId',
    );
    return r.data ?? {};
  }

  Future<void> vehiclesUpdate({
    String? libreDocument,
    String? libreDocumentSec,
    String? plateNumber,
    String? type,
    String? insuranceDoc,
    String? details,
    String? photo,
  }) async {
    final payload = <String, dynamic>{};
    if (libreDocument != null) payload['libreDocument'] = libreDocument;
    if (libreDocumentSec != null) payload['libreDocumentSec'] = libreDocumentSec;
    if (plateNumber != null) payload['plateNumber'] = plateNumber;
    if (type != null) payload['type'] = type;
    if (insuranceDoc != null) payload['insuranceDoc'] = insuranceDoc;
    if (details != null) payload['details'] = details;
    if (photo != null) payload['photo'] = photo;
    await _dio.post<void>('/vehicles/update', data: payload);
  }

  // --- assignments ---
  /// Loads all driver assignments via the paged API and returns a flat list
  /// (same shape callers expect from the old `GET /assignments/driver`).
  /// Omits `status` so the backend returns ACTIVE + COMPLETED + CANCELLED.
  Future<List<dynamic>> assignmentsDriver() async {
    return _assignmentsDriverAllPages();
  }

  /// [status] is optional: `ACTIVE`, `COMPLETED`, `CANCELLED`, or null/omitted for all.
  Future<Map<String, dynamic>> assignmentsDriverPages({
    String? status,
    int page = 0,
    int size = 10,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'size': size,
    };
    final trimmed = status?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      query['status'] = trimmed;
    }
    final r = await _dio.get<Map<String, dynamic>>(
      '/assignments/driver/pages',
      queryParameters: query,
    );
    return r.data ?? {};
  }

  Future<List<dynamic>> _assignmentsDriverAllPages({
    String? status,
    int size = 10,
  }) async {
    final out = <dynamic>[];
    var page = 0;
    while (true) {
      final raw = await assignmentsDriverPages(
        status: status,
        page: page,
        size: size,
      );
      final data = _unwrapAssignmentsPage(raw);
      final content = data['content'];
      final batch = content is List ? List<dynamic>.from(content) : <dynamic>[];
      out.addAll(batch);
      if (!_assignmentsPageHasMore(data, batch.length, size)) break;
      page += 1;
      if (page > 1000) break;
    }
    return out;
  }

  static Map<String, dynamic> _unwrapAssignmentsPage(Map<String, dynamic> raw) {
    final data = raw['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return raw;
  }

  static bool _assignmentsPageHasMore(
    Map<String, dynamic> data,
    int fetchedCount,
    int pageSize,
  ) {
    final last = data['last'];
    if (last is bool) return !last;

    final totalPages = data['totalPages'];
    final number = data['number'];
    if (totalPages is num && number is num) {
      return number.toInt() + 1 < totalPages.toInt();
    }
    return fetchedCount >= pageSize;
  }

  Future<void> assignmentsConfirmLoaded(Map<String, dynamic> body) async {
    await _dio.put<void>('/assignments/shipment-loaded', data: body);
  }

  Future<void> assignmentsConfirmInTransit(Map<String, dynamic> body) async {
    await _dio.put<void>('/assignments/shipment-in-transit', data: body);
  }

  Future<void> assignmentsConfirmArrived(Map<String, dynamic> body) async {
    await _dio.put<void>('/assignments/shipment-arrived', data: body);
  }

  Future<void> assignmentsConfirmOffloaded(Map<String, dynamic> body) async {
    await _dio.put<void>('/assignments/shipment-offloaded', data: body);
  }

  Future<void> assignmentsCancel(Map<String, dynamic> body) async {
    await _dio.put<void>('/assignments/cancel', data: body);
  }

  // --- driver negotiations ---
  Future<List<dynamic>> driverNegotiationsList() async {
    final r = await _dio.get<List<dynamic>>('/driver-negotiations');
    return r.data ?? [];
  }

  Future<Map<String, dynamic>> driverNegotiationLocation(
    String negotiationId,
  ) async {
    final r = await _dio.get<Map<String, dynamic>>(
      '/driver-negotiations/location/$negotiationId',
    );
    return r.data ?? {};
  }

  Future<void> driverNegotiationsDriverAccepts(
    Map<String, dynamic> body,
  ) async {
    await _dio.put<void>('/driver-negotiations/driver-accepts', data: body);
  }

  Future<void> driverNegotiationsDriverRejects(
    Map<String, dynamic> body,
  ) async {
    await _dio.put<void>('/driver-negotiations/driver-rejects', data: body);
  }

  Future<void> driverNegotiationsDriverCancel(Map<String, dynamic> body) async {
    await _dio.put<void>('/driver-negotiations/driver-cancel', data: body);
  }

  Future<void> driverNegotiationsDriverCounter(
    Map<String, dynamic> body,
  ) async {
    await _dio.post<void>('/driver-negotiations/dirver-counter', data: body);
  }

  // --- tracking ---
  /// POST body: assignmentId, latitude, longitude, accuracy, speed, recordedAt (ISO-8601).
  Future<void> trackingRecord(Map<String, dynamic> req) async {
    await _dio.post<void>('/tracking', data: req);
  }

  // --- grn / gdn (read — drivers view documents) ---
  Future<List<dynamic>> grnOfAssignment(String assignmentId) async {
    final r = await _dio.get<List<dynamic>>('/grn/assignment/$assignmentId');
    return r.data ?? [];
  }

  Future<Map<String, dynamic>> grnGet(String publicId) async {
    final r = await _dio.get<Map<String, dynamic>>('/grn/$publicId');
    return r.data ?? {};
  }

  Future<List<dynamic>> gdnOfAssignment(String assignmentId) async {
    final r = await _dio.get<List<dynamic>>('/gdn/assignment/$assignmentId');
    return r.data ?? [];
  }

  Future<Map<String, dynamic>> gdnGet(String publicId) async {
    final r = await _dio.get<Map<String, dynamic>>('/gdn/$publicId');
    return r.data ?? {};
  }

  // --- assignment finance (driver payouts visibility) ---
  Future<Map<String, dynamic>> assignmentFinance(String assignmentId) async {
    final r = await _dio.get<Map<String, dynamic>>(
      '/assignment-finance/$assignmentId',
    );
    return r.data ?? {};
  }

  Future<void> assignmentFinanceAddPayment(Map<String, dynamic> body) async {
    await _dio.post<void>('/assignment-finance', data: body);
  }

  // --- feedback ---
  Future<void> feedbackToPlatform() async {
    await _dio.post<void>('/feedback/to-platform');
  }

  Future<void> feedbackToConsignor(Map<String, dynamic> body) async {
    await _dio.post<void>('/feedback/to-consignor', data: body);
  }

  // --- notifications ---
  Future<int> notificationsUnreadCount() async {
    final r = await _dio.get<dynamic>('/notifications/unread-count');
    final v = r.data;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return 0;
  }

  Future<List<dynamic>> notificationsUnreadByType() async {
    final r = await _dio.get<List<dynamic>>('/notifications/unread-by-type');
    return r.data ?? [];
  }

  Future<List<dynamic>> notificationsLatest() async {
    final r = await _dio.get<List<dynamic>>('/notifications/latest');
    return r.data ?? [];
  }

  Future<Map<String, dynamic>> notificationsPage({
    int page = 0,
    int size = 10,
  }) async {
    final r = await _dio.get<Map<String, dynamic>>(
      '/notifications/page',
      queryParameters: {'page': page, 'size': size},
    );
    return r.data ?? {};
  }

  Future<void> notificationsMarkRead(String id) async {
    await _dio.post<void>('/notifications/$id/read');
  }

  // --- push notifications ---
  /// Registers (or updates) the device FCM token for the given user.
  /// Backend endpoint: POST /fcm-token { userId, fcmToken }
  Future<void> fcmTokenRegister({
    required String userId,
    required String fcmToken,
  }) async {
    await _dio.post<void>(
      '/fcm-token',
      data: {'userId': userId, 'fcmToken': fcmToken},
    );
  }

  // --- paged shipments by stage (optional UI) ---
  Future<Map<String, dynamic>> shipmentsByStage(
    String stage, {
    int page = 0,
    int size = 20,
  }) async {
    final r = await _dio.get<Map<String, dynamic>>(
      '/shipments/stage/$stage',
      queryParameters: {'page': page, 'size': size},
    );
    return r.data ?? {};
  }

  // --- object storage (presigned URLs) ---
  /// Body: `folder` (`shipment_payments` | `profile`), `fileName`, `contentType`.
  Future<Map<String, dynamic>> s3GeneratePresignedUrl({
    required String folder,
    required String fileName,
    required String contentType,
  }) async {
    final r = await _dio.post<Map<String, dynamic>>(
      '/s3/generate-presigned-url',
      data: {
        'folder': folder,
        'fileName': fileName,
        'contentType': contentType,
      },
    );
    return r.data ?? {};
  }

  /// Query: `folder`, `fileName`.
  Future<Map<String, dynamic>> s3PresignedDeleteUrl({
    required String folder,
    required String fileName,
  }) async {
    final r = await _dio.get<Map<String, dynamic>>(
      '/s3/presigned-delete-url',
      queryParameters: {'folder': folder, 'fileName': fileName},
    );
    return r.data ?? {};
  }
}
