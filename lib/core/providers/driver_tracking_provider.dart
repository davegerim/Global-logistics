import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_logistics_app/core/providers/auth_provider.dart';
import 'package:global_logistics_app/core/providers/backend_api_provider.dart';
import 'package:global_logistics_app/core/tracking/driver_location_tracking.dart';

/// Driver location tracking while the app is open.
///
/// Periodic path: if the driver has any active assignment(s), send location
/// every [_pingInterval]. Does not require GDN or movement statuses.
/// Status-click pings from the shipment detail screen are separate and still
/// use [sendTrackingPing] with their own GDN/status rules.
class DriverTrackingController extends Notifier<void> {
  static const Duration _pollInterval = Duration(minutes: 2);
  static const Duration _pingInterval = Duration(minutes: 5);

  Timer? _pollTimer;
  bool _tickInFlight = false;
  bool _sendInFlight = false;
  bool _appInForeground = true;
  final Map<String, DateTime> _lastPingAt = {};

  @override
  void build() {
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.isAuthenticated && next.role == AppRole.driver) {
        _ensurePollTimer();
      } else {
        _stopPollTimer();
        _clearState();
      }
    }, fireImmediately: true);
    ref.onDispose(() {
      _stopPollTimer();
      _clearState();
    });
  }

  void setAppInForeground(bool value) {
    if (_appInForeground == value) return;
    _appInForeground = value;
    if (value) {
      unawaited(_tick());
    }
  }

  Future<void> sendTrackingPing(
    String assignmentId, {
    required String reason,
  }) async {
    if (_sendInFlight) return;
    _sendInFlight = true;
    try {
      final api = ref.read(backendApiProvider);
      final sent = await sendDriverTrackingRecord(
        api,
        assignmentId,
        reason: reason,
      );
      if (sent) {
        _lastPingAt[assignmentId] = DateTime.now().toUtc();
      }
    } finally {
      _sendInFlight = false;
    }
  }

  void _ensurePollTimer() {
    if (_pollTimer != null) return;
    _pollTimer = Timer.periodic(_pollInterval, (_) => unawaited(_tick()));
    unawaited(_tick());
  }

  void _stopPollTimer() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void _clearState() {
    _lastPingAt.clear();
  }

  Future<void> _tick() async {
    if (_tickInFlight || !_appInForeground) return;
    final auth = ref.read(authProvider);
    if (!auth.isAuthenticated || auth.role != AppRole.driver) return;

    _tickInFlight = true;
    try {
      final api = ref.read(backendApiProvider);
      // Prefer server-side ACTIVE bucket; keep client filter as safety net.
      final assignments = await api.assignmentsDriver(status: 'ACTIVE');
      final seenAssignmentIds = <String>{};

      for (final raw in assignments) {
        if (raw is! Map) continue;
        final assignment = raw.cast<String, dynamic>();
        final assignmentId = assignmentIdFromMap(assignment);
        if (assignmentId == null) continue;

        seenAssignmentIds.add(assignmentId);
        final status = assignmentStatusFromMap(assignment);
        if (!isActiveDriverAssignmentStatus(status)) {
          _lastPingAt.remove(assignmentId);
          continue;
        }

        final lastPing = _lastPingAt[assignmentId];
        final dueForPeriodic =
            lastPing == null ||
            DateTime.now().toUtc().difference(lastPing) >= _pingInterval;

        if (dueForPeriodic) {
          final reason =
              lastPing == null ? 'active-assignment-start' : 'periodic-5m';
          await sendTrackingPing(assignmentId, reason: reason);
        }
      }

      _lastPingAt.removeWhere((id, _) => !seenAssignmentIds.contains(id));
    } catch (e) {
      debugPrint('[TRACKING] poll failed: $e');
    } finally {
      _tickInFlight = false;
    }
  }
}

final driverTrackingControllerProvider =
    NotifierProvider<DriverTrackingController, void>(
      DriverTrackingController.new,
    );
