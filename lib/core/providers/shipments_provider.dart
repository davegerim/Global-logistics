import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_logistics_app/core/providers/notifications_provider.dart';
import 'package:global_logistics_app/core/providers/repository_provider.dart';
import 'package:global_logistics_app/core/utils/assignment_display.dart';
import 'package:global_logistics_app/data/mappers/api_mappers.dart';
import 'package:global_logistics_app/data/models/shipment_model.dart';
import 'package:global_logistics_app/data/models/shipment_status.dart';

/// Backend `/assignments/driver/pages` status bucket for in-progress work.
const kDriverAssignmentStatusActive = 'ACTIVE';

Future<void> refreshDriverHomeData(WidgetRef ref) async {
  ref.invalidate(unreadNotificationsCountProvider);
  ref.invalidate(driverActiveAssignmentsProvider);
  ref.invalidate(driverAssignedShipmentsProvider);
  await ref.read(driverActiveAssignmentsProvider.future);
}

Future<void> refreshDriverAssignmentDetailData(WidgetRef ref) async {
  ref.invalidate(driverAssignedShipmentsProvider);
  ref.invalidate(driverActiveAssignmentsProvider);
  await Future.wait([
    ref.read(driverAssignedShipmentsProvider.future),
    ref.read(driverActiveAssignmentsProvider.future),
  ]);
}

ShipmentModel? findDriverAssignmentById(List<ShipmentModel> list, String id) {
  for (final s in list) {
    if (s.id == id || s.publicId == id || s.assignmentId == id) {
      return s;
    }
  }
  return null;
}

/// Full driver assignment list (all status buckets). Used by History / detail.
final driverAssignedShipmentsProvider = FutureProvider<List<ShipmentModel>>((ref) {
  final repo = ref.watch(logisticsRepositoryProvider);
  return repo.fetchDriverAssignedShipments();
});

/// Driver home / stats: hide finished or cancelled assignments.
/// Kept as a defensive client filter even when the API is called with
/// [kDriverAssignmentStatusActive].
bool isDriverAssignmentActive(ShipmentModel s) {
  final api = (s.apiStatusLabel ?? '').trim().toUpperCase();
  if (api == 'CONSIGNOR_RECEIVED' || api == 'COMPLETED') return false;
  if (api.contains('CANCELLED')) return false;
  if (s.status == ShipmentStatus.completed ||
      s.status == ShipmentStatus.cancelled) {
    return false;
  }
  return true;
}

/// Home / profile active list — requests `status=ACTIVE` from the API, then
/// applies [isDriverAssignmentActive] as a safety net.
final driverActiveAssignmentsProvider =
    FutureProvider<List<ShipmentModel>>((ref) async {
  final repo = ref.watch(logisticsRepositoryProvider);
  final list = await repo.fetchDriverAssignedShipments(
    status: kDriverAssignmentStatusActive,
  );
  final active = list.where(isDriverAssignmentActive).toList()
    ..sort(compareShipmentsNewestFirst);
  return AssignmentDisplay.withDriverListSequences(active);
});

/// Driver assignment detail — derived from [driverAssignedShipmentsProvider]
/// so History / cancelled / completed rows remain resolvable by id.
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
