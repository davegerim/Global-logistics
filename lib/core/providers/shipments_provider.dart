import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_logistics_app/core/providers/notifications_provider.dart';
import 'package:global_logistics_app/core/providers/repository_provider.dart';
import 'package:global_logistics_app/core/utils/assignment_display.dart';
import 'package:global_logistics_app/data/mappers/api_mappers.dart';
import 'package:global_logistics_app/data/models/shipment_model.dart';
import 'package:global_logistics_app/data/models/shipment_status.dart';

Future<void> refreshDriverHomeData(WidgetRef ref) async {
  ref.invalidate(unreadNotificationsCountProvider);
  ref.invalidate(driverAssignedShipmentsProvider);
  await ref.read(driverAssignedShipmentsProvider.future);
}

Future<void> refreshDriverAssignmentDetailData(WidgetRef ref) async {
  ref.invalidate(driverAssignedShipmentsProvider);
  await ref.read(driverAssignedShipmentsProvider.future);
}

ShipmentModel? findDriverAssignmentById(List<ShipmentModel> list, String id) {
  for (final s in list) {
    if (s.id == id || s.publicId == id || s.assignmentId == id) {
      return s;
    }
  }
  return null;
}

final driverAssignedShipmentsProvider = FutureProvider<List<ShipmentModel>>((ref) {
  final repo = ref.watch(logisticsRepositoryProvider);
  return repo.fetchDriverAssignedShipments();
});

/// Driver home / stats: hide finished assignments (e.g. consignor received).
bool isDriverAssignmentActive(ShipmentModel s) {
  final api = (s.apiStatusLabel ?? '').trim().toUpperCase();
  if (api == 'CONSIGNOR_RECEIVED') return false;
  if (s.status == ShipmentStatus.completed) return false;
  return true;
}

final driverActiveAssignmentsProvider = Provider<AsyncValue<List<ShipmentModel>>>((ref) {
  final all = ref.watch(driverAssignedShipmentsProvider);
  return all.when(
    skipLoadingOnReload: true,
    data: (list) {
      final active = list.where(isDriverAssignmentActive).toList()
        ..sort(compareShipmentsNewestFirst);
      return AsyncValue.data(
        AssignmentDisplay.withDriverListSequences(active),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: AsyncValue.error,
  );
});

/// Driver assignment detail — derived from [driverAssignedShipmentsProvider]
/// so status stays in sync with the home list after admin or consignor updates.
final driverAssignmentDetailProvider =
    Provider.autoDispose.family<AsyncValue<ShipmentModel?>, String>((ref, id) {
  final all = ref.watch(driverAssignedShipmentsProvider);
  return all.when(
    skipLoadingOnReload: true,
    data: (list) => AsyncValue.data(findDriverAssignmentById(list, id)),
    loading: () => const AsyncValue.loading(),
    error: AsyncValue.error,
  );
});
