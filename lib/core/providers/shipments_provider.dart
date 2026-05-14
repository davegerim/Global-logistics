import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_logistics_app/core/providers/repository_provider.dart';
import 'package:global_logistics_app/data/models/shipment_model.dart';
import 'package:global_logistics_app/data/models/shipment_status.dart';

final consignorShipmentsProvider = FutureProvider<List<ShipmentModel>>((ref) {
  final repo = ref.watch(logisticsRepositoryProvider);
  return repo.fetchConsignorShipments();
});

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
    data: (list) => AsyncValue.data(
      list.where(isDriverAssignmentActive).toList(),
    ),
    loading: () => const AsyncValue.loading(),
    error: AsyncValue.error,
  );
});

final shipmentDetailProvider = FutureProvider.family<ShipmentModel?, String>((ref, id) {
  final repo = ref.watch(logisticsRepositoryProvider);
  return repo.getShipment(id);
});
