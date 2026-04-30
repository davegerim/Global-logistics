import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_logistics_app/core/providers/repository_provider.dart';
import 'package:global_logistics_app/data/models/shipment_model.dart';

final paymentsProvider = FutureProvider<List<PaymentRecord>>((ref) {
  final repo = ref.watch(logisticsRepositoryProvider);
  return repo.fetchPayments();
});
