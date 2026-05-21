/// Helpers for assignment-finance and shipment-finance API payloads.
abstract final class FinanceApiUtils {
  static Map<String, dynamic> unwrapPayload(Map<String, dynamic> raw) {
    final data = raw['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return raw;
  }

  /// Finance record public id used as `shipmentFinanceId` on POST /shipment-finance.
  static String? financePublicId(Map<String, dynamic> raw) {
    final id = unwrapPayload(raw)['publicId']?.toString().trim();
    if (id == null || id.isEmpty) return null;
    return id;
  }
}
