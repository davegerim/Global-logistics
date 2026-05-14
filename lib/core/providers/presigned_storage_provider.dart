import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_logistics_app/core/providers/backend_api_provider.dart';
import 'package:global_logistics_app/core/services/presigned_storage_service.dart';

final presignedStorageServiceProvider = Provider<PresignedStorageService>((ref) {
  return PresignedStorageService(ref.watch(backendApiProvider));
});
