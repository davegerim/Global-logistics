import 'package:global_logistics_app/data/models/driver_offer_model.dart';
import 'package:global_logistics_app/data/models/shipment_model.dart';
import 'package:global_logistics_app/data/models/shipment_status.dart';

DateTime? _parseDt(dynamic v) {
  if (v == null) return null;
  if (v is String) return DateTime.tryParse(v);
  return null;
}

/// Newest bookings first (placed date, then booking #, then public id).
int compareShipmentsNewestFirst(ShipmentModel a, ShipmentModel b) {
  final byPlaced = b.placedAt.compareTo(a.placedAt);
  if (byPlaced != 0) return byPlaced;
  final aBooking = int.tryParse(a.bookingId ?? '') ?? 0;
  final bBooking = int.tryParse(b.bookingId ?? '') ?? 0;
  if (aBooking != bBooking) return bBooking.compareTo(aBooking);
  return b.publicId.compareTo(a.publicId);
}

double? _parseDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

ShipmentStatus mapApiShipmentStatus(String? s) {
  switch (s) {
    case 'CREATED':
    case 'ADMIN_REQUESTED_CHANGE':
    case 'CONSIGNOR_COUNTERED':
      return ShipmentStatus.pendingReview;
    case 'ADMIN_REJECTED_OFFER':
    case 'CONSIGNOR_REJECTED_OFFER':
      return ShipmentStatus.cancelled;
    case 'CONSIGNOR_ACCEPTED':
    case 'ADMIN_APPROVED':
      return ShipmentStatus.awaitingDriver;
    case 'DRIVER_ASSIGNED':
      return ShipmentStatus.driverAssigned;
    case 'IN_TRANSIT':
      return ShipmentStatus.inTransit;
    case 'COMPLETED':
      return ShipmentStatus.completed;
    case 'CANCELLED_BY_CONSIGNOR':
    case 'CANCELLED_BY_ADMIN':
    case 'CANCELLED_SYSTEM':
      return ShipmentStatus.cancelled;
    default:
      return ShipmentStatus.pendingReview;
  }
}

ShipmentStatus mapAssignmentStatus(String? s) {
  switch (s) {
    case 'DRIVER_ASSIGNED':
      return ShipmentStatus.driverAssigned;
    case 'GDN_GENERATED':
      return ShipmentStatus.gdnIssued;
    case 'LOADED':
      return ShipmentStatus.loading;
    case 'IN_TRANSIT':
      return ShipmentStatus.inTransit;
    case 'ARRIVED':
      return ShipmentStatus.atDestination;
    case 'OFFLOADED':
      return ShipmentStatus.offloading;
    case 'GRN_GENERATED':
    case 'CONSIGNOR_RECEIVED':
      return ShipmentStatus.delivered;
    case 'CANCELLED':
    case 'REOPENED_BY_ADMIN':
      return ShipmentStatus.pendingReview;
    default:
      return ShipmentStatus.driverAssigned;
  }
}

ShipmentModel shipmentFromDto(Map<String, dynamic> j) {
  final publicId = j['publicId'] as String? ?? '';
  final status = mapApiShipmentStatus(j['currentStatus'] as String?);
  return ShipmentModel(
    id: publicId,
    publicId: publicId,
    bookingId: j['bookingId']?.toString(),
    apiStatusLabel: j['currentStatus'] as String?,
    assignmentId: null,
    status: status,
    loadingAddress: j['loadingLocation'] as String? ?? '—',
    offloadingAddress: j['offloadingLocation'] as String? ?? '—',
    goodsDescription: j['goodType'] as String? ?? 'Shipment',
    weightKg: _parseDouble(j['weight']) ?? 0,
    volumeM3: _parseDouble(j['volume']) ?? 0,
    vehicleType: j['requiredVehicleType'] as String? ?? '—',
    timelineNote: j['details'] as String? ?? '',
    placedAt: _parseDt(j['createdAt']) ?? DateTime.now(),
    estimatedDelivery: _parseDt(j['deliveryDate'] ?? j['loadingDate']),
    progress01: _progressForShipmentStatus(status),
    paymentMethod: j['priceType'] as String?,
    priceOffer: _parseDouble(j['priceAmount']),
  );
}

/// OpenAPI `ShipmentWorkspaceResponse` has header+overview but no shipment UUID at root;
/// We require caller to pass [shipmentPublicId].
ShipmentModel shipmentFromWorkspaceWithId(
  Map<String, dynamic> w,
  String shipmentPublicId,
) {
  final header = (w['header'] as Map?)?.cast<String, dynamic>() ?? {};
  final overview = (w['overview'] as Map?)?.cast<String, dynamic>() ?? {};
  final status = mapApiShipmentStatus(header['status'] as String?);
  return ShipmentModel(
    id: shipmentPublicId,
    publicId: shipmentPublicId,
    apiStatusLabel: header['status'] as String?,
    assignmentId: null,
    status: status,
    loadingAddress:
        header['loadingLocation'] as String? ??
        overview['loadingLocation'] as String? ??
        '—',
    offloadingAddress:
        header['offloadingLocation'] as String? ??
        overview['offloadingLocation'] as String? ??
        '—',
    goodsDescription:
        overview['goodType'] as String? ?? header['goodType'] as String? ?? '—',
    weightKg: _parseDouble(overview['weight']) ?? 0,
    volumeM3: _parseDouble(overview['volume']) ?? 0,
    vehicleType: overview['requiredVehicleType'] as String? ?? '—',
    timelineNote: overview['details'] as String? ?? '',
    placedAt: _parseDt(header['createdAt']) ?? DateTime.now(),
    estimatedDelivery: _parseDt(
      overview['deliveryDate'] ?? overview['loadingDate'],
    ),
    progress01: _progressForShipmentStatus(status),
    paymentMethod: overview['priceType'] as String?,
    priceOffer: _parseDouble(header['priceAmount'] ?? overview['priceAmount']),
  );
}

ShipmentModel shipmentFromDriverWorkspace(
  Map<String, dynamic> w, {
  required String shipmentId,
  String? assignmentPublicId,
}) {
  final negotiations = (w['negotiations'] as List?) ?? const [];
  Map<String, dynamic>? first;
  if (negotiations.isNotEmpty) {
    first = (negotiations.first as Map).cast<String, dynamic>();
  }
  final selected = (w['selectedDrivers'] as List?) ?? const [];
  Map<String, dynamic>? sel;
  if (selected.isNotEmpty) {
    sel = (selected.first as Map).cast<String, dynamic>();
  }
  final loading = first?['loadingLocation'] as String? ?? '—';
  final off = first?['offloadingLocation'] as String? ?? '—';
  final good = first?['goodType'] as String? ?? 'Assignment';
  final price = _parseDouble(first?['priceAmount'] ?? sel?['agreedPrice']);
  return ShipmentModel(
    id: shipmentId,
    publicId: shipmentId,
    apiStatusLabel: first?['status'] as String?,
    assignmentId: assignmentPublicId,
    status: ShipmentStatus.driverAssigned,
    loadingAddress: loading,
    offloadingAddress: off,
    goodsDescription: good,
    weightKg: _parseDouble(first?['weight']) ?? 0,
    volumeM3: _parseDouble(first?['volume']) ?? 0,
    vehicleType:
        first?['requiredVehicleType'] as String? ??
        sel?['vehicleType'] as String? ??
        '—',
    timelineNote: first?['details'] as String? ?? '',
    placedAt: _parseDt(first?['updatedAt']) ?? DateTime.now(),
    estimatedDelivery: null,
    progress01: 0.25,
    paymentMethod: first?['priceType'] as String?,
    priceOffer: price,
    driver: sel == null
        ? null
        : DriverSummary(
            id: sel['driverId'] as String? ?? '',
            name: sel['driverName'] as String? ?? 'Driver',
            phone: sel['phone'] as String?,
            vehicleLabel: sel['vehicleType'] as String?,
            plate: null,
            rating: null,
          ),
  );
}

/// Build a [ShipmentModel] from the `/assignments/driver` DTO, optionally
/// enriched with negotiation data that carries the shipment locations.
ShipmentModel shipmentFromAssignmentDriverView(
  Map<String, dynamic> j, {
  Map<String, dynamic>? negotiationData,
}) {
  final shipmentId = j['shipmentId']?.toString() ?? '';
  final assignmentPid = j['publicId']?.toString();
  final assignmentDisplayId = j['assignmentId']?.toString();
  final st = mapAssignmentStatus(j['status'] as String?);

  final n = negotiationData;
  final loading = _nonDash(j['loadingLocation']) ??
      _nonDash(n?['loadingLocation']) ??
      '—';
  final off = _nonDash(j['offloadingLocation']) ??
      _nonDash(n?['offloadingLocation']) ??
      '—';
  final good = _nonDash(j['goodType']) ??
      _nonDash(n?['goodType']) ??
      'Assignment';
  final weight = _parseDouble(j['weight']) ?? _parseDouble(n?['weight']) ?? 0;
  final volume = _parseDouble(j['volume']) ?? _parseDouble(n?['volume']) ?? 0;
  final vehicle = _nonDash(j['requiredVehicleType']) ??
      _nonDash(n?['requiredVehicleType']) ??
      '—';

  return ShipmentModel(
    id: shipmentId,
    publicId: shipmentId,
    apiStatusLabel: j['status'] as String?,
    assignmentId: assignmentPid ?? assignmentDisplayId,
    assignmentDisplayId: assignmentDisplayId,
    bookingId: j['bookingId']?.toString(),
    status: st,
    loadingAddress: loading,
    offloadingAddress: off,
    goodsDescription: good,
    weightKg: weight.toDouble(),
    volumeM3: volume.toDouble(),
    vehicleType: vehicle,
    timelineNote: j['details'] as String? ?? '',
    placedAt: _parseDt(j['assignedAt']) ?? DateTime.now(),
    estimatedDelivery: _parseDt(j['completedAt']),
    progress01: _progressForAssignmentStatus(st),
    paymentMethod: n?['priceType'] as String?,
    priceOffer: _parseDouble(j['agreedPrice']) ??
        _parseDouble(n?['priceAmount']),
  );
}

String? _nonDash(dynamic v) {
  if (v is String) {
    final t = v.trim();
    if (t.isNotEmpty && t != '—') return t;
  }
  return null;
}

double _progressForShipmentStatus(ShipmentStatus s) => switch (s) {
  ShipmentStatus.completed => 1.0,
  ShipmentStatus.inTransit => 0.55,
  ShipmentStatus.pendingReview => 0.12,
  _ => 0.35,
};

double _progressForAssignmentStatus(ShipmentStatus s) => switch (s) {
  ShipmentStatus.delivered => 1.0,
  ShipmentStatus.completed => 1.0,
  ShipmentStatus.inTransit => 0.6,
  ShipmentStatus.loading => 0.35,
  ShipmentStatus.gdnIssued => 0.35,
  _ => 0.2,
};

List<DriverOfferModel> driverOffersFromApi(List<dynamic> list) {
  final out = <DriverOfferModel>[];
  for (final e in list) {
    if (e is! Map) continue;
    final m = e.cast<String, dynamic>();
    final id = m['negotiationId']?.toString() ?? '';
    final load = m['loadingLocation'] as String? ?? '';
    final off = m['offloadingLocation'] as String? ?? '';
    final route = '$load → $off'.trim();
    final price = _parseDouble(m['priceAmount']) ?? 0;
    final cur = m['priceCurrency'] as String? ?? 'ETB';
    final updated = _parseDt(m['updatedAt']) ?? DateTime.now();
    final rounds = _driverRoundsFromApi(m);
    out.add(
      DriverOfferModel(
        negotiationId: id,
        publicId: m['publicId']?.toString(),
        shipmentId: m['shipmentId']?.toString(),
        routeSummary: route.isEmpty ? 'Offer' : route,
        price: price,
        currency: cur,
        distanceKm: 0,
        expiresAt: updated.add(const Duration(hours: 24)),
        apiStatus: m['status'] as String?,
        goodType: m['goodType'] as String?,
        rounds: rounds,
      ),
    );
  }
  return out;
}

List<DriverNegotiationRound> _driverRoundsFromApi(Map<String, dynamic> m) {
  final raw = m['offers'];
  final out = <DriverNegotiationRound>[];
  if (raw is! List) return out;
  for (final item in raw) {
    if (item is! Map) continue;
    final offer = item.cast<String, dynamic>();
    out.add(
      DriverNegotiationRound(
        round: _parseInt(offer['round']),
        actorType: offer['actorType'] as String?,
        status: offer['status'] as String?,
        priceAmount: _parseDouble(offer['priceAmount']),
        reason: offer['reason'] as String?,
        offeredAt: _parseDt(offer['offeredAt']),
        loadingDate: _parseDt(offer['loadingDate']),
        deliveryDate: _parseDt(offer['deliveryDate']),
        requiredVehicleType: offer['requiredVehicleType'] as String?,
        requiredVehicleNumber: _parseInt(offer['requiredVehicleNumber']),
      ),
    );
  }
  out.sort((a, b) {
    final ar = a.round ?? 1 << 30;
    final br = b.round ?? 1 << 30;
    final byRound = ar.compareTo(br);
    if (byRound != 0) return byRound;
    final at = a.offeredAt?.millisecondsSinceEpoch ?? 0;
    final bt = b.offeredAt?.millisecondsSinceEpoch ?? 0;
    return at.compareTo(bt);
  });
  return out;
}

int? _parseInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}
