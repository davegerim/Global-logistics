import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_logistics_app/core/providers/repository_provider.dart';
import 'package:global_logistics_app/data/models/driver_offer_model.dart';

final driverOffersProvider = FutureProvider<List<DriverOfferModel>>((ref) {
  final repo = ref.watch(logisticsRepositoryProvider);
  return repo.fetchDriverOffers();
});
