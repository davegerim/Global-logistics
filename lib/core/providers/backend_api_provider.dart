import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_logistics_app/core/providers/dio_provider.dart';
import 'package:global_logistics_app/data/api/backend_api.dart';

final backendApiProvider = Provider<BackendApi>((ref) {
  return BackendApi(ref.watch(dioProvider));
});
