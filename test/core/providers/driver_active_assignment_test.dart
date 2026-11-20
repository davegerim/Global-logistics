import 'package:flutter_test/flutter_test.dart';
import 'package:global_logistics_app/core/providers/shipments_provider.dart';
import 'package:global_logistics_app/core/tracking/driver_location_tracking.dart';
import 'package:global_logistics_app/data/mappers/api_mappers.dart';
import 'package:global_logistics_app/data/models/shipment_model.dart';
import 'package:global_logistics_app/data/models/shipment_status.dart';

ShipmentModel _assignment({
  required String apiStatus,
  required ShipmentStatus status,
}) {
  return ShipmentModel(
    id: 'a1',
    publicId: 'a1',
    status: status,
    loadingAddress: 'A',
    offloadingAddress: 'B',
    goodsDescription: 'goods',
    weightKg: 1,
    volumeM3: 1,
    vehicleType: 'truck',
    timelineNote: '',
    placedAt: DateTime.utc(2026, 1, 1),
    estimatedDelivery: null,
    apiStatusLabel: apiStatus,
  );
}

void main() {
  test('ACTIVE status constant matches API docs', () {
    expect(kDriverAssignmentStatusActive, 'ACTIVE');
  });

  group('isDriverAssignmentActive', () {
    test('keeps in-progress assignment statuses', () {
      expect(
        isDriverAssignmentActive(
          _assignment(
            apiStatus: 'DRIVER_ASSIGNED',
            status: ShipmentStatus.driverAssigned,
          ),
        ),
        isTrue,
      );
      expect(
        isDriverAssignmentActive(
          _assignment(
            apiStatus: 'IN_TRANSIT',
            status: ShipmentStatus.inTransit,
          ),
        ),
        isTrue,
      );
    });

    test('hides cancelled and finished assignments', () {
      expect(
        isDriverAssignmentActive(
          _assignment(
            apiStatus: 'CANCELLED',
            status: ShipmentStatus.cancelled,
          ),
        ),
        isFalse,
      );
      expect(
        isDriverAssignmentActive(
          _assignment(
            apiStatus: 'CANCELLED_BY_ADMIN',
            status: ShipmentStatus.cancelled,
          ),
        ),
        isFalse,
      );
      expect(
        isDriverAssignmentActive(
          _assignment(
            apiStatus: 'CONSIGNOR_RECEIVED',
            status: ShipmentStatus.delivered,
          ),
        ),
        isFalse,
      );
      expect(
        isDriverAssignmentActive(
          _assignment(
            apiStatus: 'COMPLETED',
            status: ShipmentStatus.completed,
          ),
        ),
        isFalse,
      );
    });
  });

  group('isActiveDriverAssignmentStatus', () {
    test('treats cancelled as inactive for tracking selection', () {
      expect(isActiveDriverAssignmentStatus('CANCELLED'), isFalse);
      expect(isActiveDriverAssignmentStatus('CANCELLED_BY_CONSIGNOR'), isFalse);
      expect(isActiveDriverAssignmentStatus('IN_TRANSIT'), isTrue);
      expect(isActiveDriverAssignmentStatus('DRIVER_ASSIGNED'), isTrue);
    });
  });

  group('mapAssignmentStatus', () {
    test('maps CANCELLED to cancelled enum', () {
      expect(mapAssignmentStatus('CANCELLED'), ShipmentStatus.cancelled);
      expect(
        mapAssignmentStatus('REOPENED_BY_ADMIN'),
        ShipmentStatus.pendingReview,
      );
    });
  });
}
