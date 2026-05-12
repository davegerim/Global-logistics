class DriverOfferModel {
  const DriverOfferModel({
    required this.negotiationId,
    required this.routeSummary,
    required this.price,
    required this.currency,
    required this.distanceKm,
    required this.expiresAt,
    this.shipmentId,
    this.publicId,
    this.apiStatus,
    this.goodType,
    this.rounds = const [],
  });

  final String negotiationId;
  final String? publicId;
  final String? shipmentId;
  final String routeSummary;
  final double price;
  final String currency;
  final double distanceKm;
  final DateTime expiresAt;
  final String? apiStatus;
  final String? goodType;
  final List<DriverNegotiationRound> rounds;

  String get apiNegotiationId {
    final normalized = publicId?.trim();
    if (normalized != null && normalized.isNotEmpty) return normalized;
    return negotiationId;
  }

  String get displayNegotiationId {
    final normalized = negotiationId.trim();
    if (normalized.isEmpty) return '—';
    return normalized;
  }
}

class DriverNegotiationRound {
  const DriverNegotiationRound({
    this.round,
    this.actorType,
    this.status,
    this.priceAmount,
    this.reason,
    this.offeredAt,
    this.loadingDate,
    this.deliveryDate,
    this.requiredVehicleType,
    this.requiredVehicleNumber,
  });

  final int? round;
  final String? actorType;
  final String? status;
  final double? priceAmount;
  final String? reason;
  final DateTime? offeredAt;
  final DateTime? loadingDate;
  final DateTime? deliveryDate;
  final String? requiredVehicleType;
  final int? requiredVehicleNumber;
}
