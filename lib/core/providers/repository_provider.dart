import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_logistics_app/core/providers/auth_provider.dart';
import 'package:global_logistics_app/core/providers/backend_api_provider.dart';
import 'package:global_logistics_app/data/repositories/api_logistics_repository.dart';
import 'package:global_logistics_app/data/repositories/logistics_repository.dart';

final logisticsRepositoryProvider = Provider<LogisticsRepository>((ref) {
  final api = ref.watch(backendApiProvider);
  final role = ref.watch(authProvider.select((a) => a.role));
  return ApiLogisticsRepository(api: api, role: role);
});
