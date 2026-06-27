import 'package:flutter/foundation.dart';
import 'package:global_logistics_app/core/services/device_location_service.dart';
import 'package:global_logistics_app/core/utils/gdn_grn_utils.dart';
import 'package:global_logistics_app/data/api/backend_api.dart';

String? assignmentIdFromMap(Map<String, dynamic> assignment) {
  final id =
      assignment['publicId']?.toString() ??
      assignment['assignmentId']?.toString() ??
      assignment['id']?.toString();
  if (id == null || id.trim().isEmpty) return null;
  return id;
}

String? assignmentStatusFromMap(Map<String, dynamic> assignment) =>
    assignment['status']?.toString() ??
    assignment['currentStatus']?.toString();

bool assignmentHasActiveGdn(List<dynamic> gdns) => gdns.any(
  (e) => e is Map && !isGdnGrnVoidedMap(Map<String, dynamic>.from(e)),
);

Future<bool> sendDriverTrackingRecord(
  BackendApi api,
  String assignmentId, {
  required String reason,
}) async {
  try {
    final location = await DeviceLocationService.current();
    final recordedAt = DateTime.fromMillisecondsSinceEpoch(
      DateTime.now().toUtc().millisecondsSinceEpoch,
      isUtc: true,
    ).toIso8601String();
    await api.trackingRecord({
      'assignmentId': assignmentId,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'accuracy': location.accuracy,
      'speed': location.speed,
      'recordedAt': recordedAt,
    });
    debugPrint('[TRACKING] sent ($reason) for assignment=$assignmentId');
    return true;
  } catch (e) {
    debugPrint('[TRACKING] failed ($reason): $e');
    return false;
  }
}
