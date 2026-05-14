import 'package:dio/dio.dart';
import 'package:global_logistics_app/data/api/backend_api.dart';

/// Backend allows exactly these folder names for presigned uploads.
abstract final class S3Folder {
  static const String shipmentPayments = 'shipment_payments';
  static const String profile = 'profile';
}

class PresignedStorageException implements Exception {
  PresignedStorageException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Backend may return camelCase `presignedUrl` or `preSignedUrl` (see API JSON).
String? readPresignedPutUrlFromBody(Map<String, dynamic> raw) {
  for (final key in <String>[
    'presignedUrl',
    'preSignedUrl',
    'PreSignedUrl',
    'presigned_put_url',
  ]) {
    final v = raw[key];
    if (v is String && v.trim().isNotEmpty) return v.trim();
  }
  return null;
}

String? readPublicUrlFromBody(Map<String, dynamic> raw) {
  for (final key in <String>['publicUrl', 'PublicUrl', 'public_url']) {
    final v = raw[key];
    if (v is String && v.trim().isNotEmpty) return v.trim();
  }
  return null;
}

/// Uploads and deletes objects via presigned URLs from [BackendApi].
/// Uses a standalone [Dio] for PUT/DELETE to the storage host so auth headers
/// from the app API client are never sent to DigitalOcean Spaces.
class PresignedStorageService {
  PresignedStorageService(this._api);

  final BackendApi _api;

  /// Upload [bytes] and return the permanent `publicUrl` from the presign step.
  Future<String> uploadBytes({
    required List<int> bytes,
    required String fileName,
    required String contentType,
    required String folder,
  }) async {
    final raw = await _api.s3GeneratePresignedUrl(
      folder: folder,
      fileName: fileName,
      contentType: contentType,
    );
    final presignedUrl = readPresignedPutUrlFromBody(raw);
    final publicUrl = readPublicUrlFromBody(raw);
    if (presignedUrl == null ||
        presignedUrl.isEmpty ||
        publicUrl == null ||
        publicUrl.isEmpty) {
      throw PresignedStorageException(
        'Could not get upload URL from the server.',
      );
    }

    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(minutes: 3),
        receiveTimeout: const Duration(seconds: 60),
        validateStatus: (_) => true,
      ),
    );

    final resp = await dio.put<void>(
      presignedUrl,
      data: bytes,
      options: Options(
        headers: {
          'Content-Type': contentType,
          'x-amz-acl': 'public-read',
        },
      ),
    );

    final code = resp.statusCode ?? 0;
    if (code != 200 && code != 204) {
      throw PresignedStorageException(
        'Upload failed (${resp.statusCode}). Please try again.',
      );
    }
    return publicUrl;
  }

  /// Deletes an object using a presigned DELETE URL from the API.
  Future<void> deleteWithPresignedFlow({
    required String folder,
    required String fileName,
  }) async {
    final raw = await _api.s3PresignedDeleteUrl(
      folder: folder,
      fileName: fileName,
    );
    final presignedUrl = readPresignedPutUrlFromBody(raw);
    if (presignedUrl == null || presignedUrl.isEmpty) {
      throw PresignedStorageException(
        'Could not get delete URL from the server.',
      );
    }

    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 45),
        receiveTimeout: const Duration(seconds: 45),
        validateStatus: (_) => true,
      ),
    );

    final resp = await dio.delete<void>(presignedUrl);
    final code = resp.statusCode ?? 0;
    if (code != 204 && code != 200) {
      throw PresignedStorageException(
        'Could not remove the old file (${resp.statusCode}).',
      );
    }
  }

  /// Last path segment of [publicUrl], for use with [deleteWithPresignedFlow].
  static String? fileNameFromPublicUrl(String publicUrl) {
    try {
      final u = Uri.parse(publicUrl.trim());
      final segments = u.pathSegments.where((s) => s.isNotEmpty).toList();
      if (segments.isEmpty) return null;
      return segments.last;
    } catch (_) {
      return null;
    }
  }

  /// Convenience when replacing a profile image: delete the previous object.
  Future<void> deletePublicObject({
    required String publicUrl,
    required String folder,
  }) async {
    final name = fileNameFromPublicUrl(publicUrl);
    if (name == null || name.isEmpty) {
      throw PresignedStorageException('Invalid file URL.');
    }
    await deleteWithPresignedFlow(folder: folder, fileName: name);
  }
}
