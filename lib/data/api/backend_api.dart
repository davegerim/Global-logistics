import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Non-admin endpoints from OpenAPI (mobile: consignor + driver).
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

  Future<void> authLogout(String refreshToken) async {
    await _dio.post<void>('/logout', data: {'refreshToken': refreshToken});
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

  // --- consignor profile ---
  Future<void> consignorsCreate({
    String? businessName,
    String? tradeLicence,
  }) async {
    final payload = {
      if (businessName != null) 'businessName': businessName,
      if (tradeLicence != null) 'tradeLicence': tradeLicence,
    };
    debugPrint('[CONSIGNORS_CREATE] request payload: $payload');
    final response = await _dio.post<dynamic>(
      '/consignors/create',
      data: payload,
    );
    debugPrint(
      '[CONSIGNORS_CREATE] response: status=${response.statusCode}, data=${response.data}',
    );
  }

  // --- driver profile ---
  Future<void> driversCreate({
    String? profilePic,
    String? nationalId,
    String? licenceNumber,
    String? licenceDocument,
    String? preferredLanes,
  }) async {
    await _dio.post<void>(
      '/drivers/create',
      data: {
        if (profilePic != null) 'profilePic': profilePic,
        if (nationalId != null) 'nationalId': nationalId,
        if (licenceNumber != null) 'licenceNumber': licenceNumber,
        if (licenceDocument != null) 'licenceDocument': licenceDocument,
        if (preferredLanes != null) 'preferredLanes': preferredLanes,
      },
    );
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

  // --- shipments (consignor) ---
  Future<List<dynamic>> shipmentsConsignor() async {
    final r = await _dio.get<List<dynamic>>('/shipments/consignor');
    return r.data ?? [];
  }

  Future<dynamic> shipmentsConsignorActive() async {
    final r = await _dio.get<dynamic>('/shipments/consignor/active');
    return r.data;
  }

  Future<Map<String, dynamic>> shipmentsCreate(
    Map<String, dynamic> body,
  ) async {
    final r = await _dio.post<dynamic>('/shipments/create', data: body);
    final d = r.data;
    if (d is Map<String, dynamic>) return d;
    return {'id': d};
  }

  Future<void> shipmentsConsignorRejectOffer(Map<String, dynamic> body) async {
    await _dio.post<void>('/shipments/consignor-reject-offer', data: body);
  }

  Future<void> shipmentsConsignorCounterOffer(Map<String, dynamic> body) async {
    await _dio.post<void>('/shipments/consignor-counter-offer', data: body);
  }

  Future<void> shipmentsConsignorCancel(Map<String, dynamic> body) async {
    await _dio.post<void>('/shipments/consignor-cancel', data: body);
  }

  Future<void> shipmentsConsignorAcceptOffer(String shipmentId) async {
    await _dio.post<void>('/shipments/consignor-accept-offer/$shipmentId');
  }

  // --- assignments ---
  Future<List<dynamic>> assignmentsDriver() async {
    final r = await _dio.get<List<dynamic>>('/assignments/driver');
    return r.data ?? [];
  }

  Future<List<dynamic>> assignmentsConsignorOfShipment(
    String shipmentId,
  ) async {
    final r = await _dio.get<List<dynamic>>(
      '/assignments/consignor/$shipmentId',
    );
    return r.data ?? [];
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

  Future<void> assignmentsConfirmConsignorReceived(
    Map<String, dynamic> body,
  ) async {
    await _dio.put<void>('/assignments/consignor-received', data: body);
  }

  Future<void> assignmentsConsignorConfirm(Map<String, dynamic> body) async {
    await _dio.put<void>('/assignments/consignor-confirm', data: body);
  }

  Future<void> assignmentsCancel(Map<String, dynamic> body) async {
    await _dio.put<void>('/assignments/cancel', data: body);
  }

  // --- driver negotiations ---
  Future<List<dynamic>> driverNegotiationsList() async {
    final r = await _dio.get<List<dynamic>>(
      '/driver-negotiations/driver-negotiations',
    );
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

  Future<List<dynamic>> trackingRoute(String assignmentId) async {
    final r = await _dio.get<List<dynamic>>('/tracking/$assignmentId');
    return r.data ?? [];
  }

  Future<Map<String, dynamic>> trackingLatest(String assignmentId) async {
    final r = await _dio.get<Map<String, dynamic>>(
      '/tracking/$assignmentId/latest',
    );
    return r.data ?? {};
  }

  // --- grn / gdn ---
  Future<Map<String, dynamic>> grnCreate(Map<String, dynamic> body) async {
    final r = await _dio.post<Map<String, dynamic>>('/grn', data: body);
    return r.data ?? {};
  }

  Future<List<dynamic>> grnOfAssignment(String assignmentId) async {
    final r = await _dio.get<List<dynamic>>('/grn/assignment/$assignmentId');
    return r.data ?? [];
  }

  Future<Map<String, dynamic>> grnGet(String publicId) async {
    final r = await _dio.get<Map<String, dynamic>>('/grn/$publicId');
    return r.data ?? {};
  }

  Future<Map<String, dynamic>> gdnCreate(Map<String, dynamic> body) async {
    final r = await _dio.post<Map<String, dynamic>>('/gdn', data: body);
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

  // --- shipment finance ---
  Future<Map<String, dynamic>> shipmentFinanceByShipment(
    String shipmentId,
  ) async {
    final r = await _dio.get<Map<String, dynamic>>(
      '/shipment-finance/shipment/$shipmentId',
    );
    return r.data ?? {};
  }

  Future<Map<String, dynamic>> shipmentFinanceLoad(String publicId) async {
    final r = await _dio.get<Map<String, dynamic>>(
      '/shipment-finance/$publicId',
    );
    return r.data ?? {};
  }

  Future<void> shipmentFinanceCreatePayment(Map<String, dynamic> body) async {
    await _dio.post<void>('/shipment-finance', data: body);
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

  Future<void> feedbackToDriver(Map<String, dynamic> body) async {
    await _dio.post<void>('/feedback/to-driver', data: body);
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

  Future<Map<String, dynamic>> notificationsPage({int page = 0, int size = 10}) async {
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
}
