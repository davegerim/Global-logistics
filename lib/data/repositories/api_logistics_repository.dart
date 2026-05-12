import 'package:global_logistics_app/core/providers/auth_provider.dart';
import 'package:global_logistics_app/data/api/backend_api.dart';
import 'package:global_logistics_app/data/mappers/api_mappers.dart';
import 'package:global_logistics_app/data/models/driver_offer_model.dart';
import 'package:global_logistics_app/data/models/shipment_model.dart';
import 'package:global_logistics_app/data/repositories/logistics_repository.dart';

class ApiLogisticsRepository implements LogisticsRepository {
  ApiLogisticsRepository({
    required BackendApi api,
    required AppRole? role,
  })  : _api = api,
        _role = role;

  final BackendApi _api;
  final AppRole? _role;

  @override
  Future<List<ShipmentModel>> fetchConsignorShipments() async {
    final raw = await _api.shipmentsConsignor();
    final out = <ShipmentModel>[];
    for (final e in raw) {
      if (e is Map) {
        out.add(shipmentFromDto(e.cast<String, dynamic>()));
      }
    }
    return out;
  }

  @override
  Future<ShipmentModel?> getShipment(String id) async {
    if (_role == AppRole.driver) {
      final assigned = await fetchDriverAssignedShipments();
      for (final shipment in assigned) {
        if (shipment.id == id || shipment.publicId == id) {
          return shipment;
        }
      }
      return null;
    }
    final shipments = await fetchConsignorShipments();
    for (final shipment in shipments) {
      if (shipment.id == id || shipment.publicId == id) {
        return shipment;
      }
    }
    return null;
  }

  @override
  Future<List<DriverOfferModel>> fetchDriverOffers() async {
    final raw = await _api.driverNegotiationsList();
    return driverOffersFromApi(raw);
  }

  @override
  Future<List<ShipmentModel>> fetchDriverAssignedShipments() async {
    final results = await Future.wait([
      _api.assignmentsDriver(),
      _api.driverNegotiationsList().catchError((_) => <dynamic>[]),
    ]);
    final raw = results[0];
    final negotiations = results[1];

    final negByShipment = <String, Map<String, dynamic>>{};
    for (final n in negotiations) {
      if (n is! Map) continue;
      final m = n.cast<String, dynamic>();
      final sid = m['shipmentId']?.toString();
      if (sid != null && sid.isNotEmpty) {
        negByShipment[sid] = m;
      }
    }

    final out = <ShipmentModel>[];
    for (final e in raw) {
      if (e is Map) {
        final j = e.cast<String, dynamic>();
        final sid = j['shipmentId']?.toString() ?? '';
        out.add(shipmentFromAssignmentDriverView(
          j,
          negotiationData: negByShipment[sid],
        ));
      }
    }
    return out;
  }

  @override
  Future<List<DocumentRef>> fetchDocumentsForAssignment(String assignmentId) async {
    final grns = await _api.grnOfAssignment(assignmentId);
    final gdns = await _api.gdnOfAssignment(assignmentId);
    final out = <DocumentRef>[];
    DateTime parse(dynamic v) => DateTime.tryParse(v as String? ?? '') ?? DateTime.now();

    for (final e in gdns) {
      if (e is! Map) continue;
      final m = e.cast<String, dynamic>();
      final pid = m['publicId'] as String? ?? '';
      out.add(
        DocumentRef(
          id: pid,
          title: 'Goods Delivery Note',
          type: 'GDN',
          availableAt: parse(m['issuedAt']),
          documentNumber: m['documentNumber'] as String?,
          qrCodeValue: m['qrCodeValue'] as String?,
          status: m['status'] as String?,
        ),
      );
    }
    for (final e in grns) {
      if (e is! Map) continue;
      final m = e.cast<String, dynamic>();
      final pid = m['publicId'] as String? ?? '';
      out.add(
        DocumentRef(
          id: pid,
          title: 'Goods Received Note',
          type: 'GRN',
          availableAt: parse(m['issuedAt'] ?? m['receivedAt']),
          documentNumber: m['documentNumber'] as String?,
          qrCodeValue: m['qrCodeValue'] as String?,
          status: m['status'] as String?,
        ),
      );
    }
    return out;
  }

  @override
  Future<List<PaymentRecord>> fetchPayments() async {
    final shipments = await fetchConsignorShipments();
    final out = <PaymentRecord>[];
    final limit = shipments.length > 6 ? 6 : shipments.length;
    for (var i = 0; i < limit; i++) {
      final sid = shipments[i].id;
      try {
        final fin = await _api.shipmentFinanceByShipment(sid);
        final payments = (fin['payments'] as List?) ?? const [];
        for (final p in payments) {
          if (p is! Map) continue;
          final m = p.cast<String, dynamic>();
          out.add(
            PaymentRecord(
              id: m['publicId'] as String? ?? '',
              amount: (m['amount'] as num?)?.toDouble() ?? 0,
              currency: (fin['priceCurrency'] as String?) ?? 'ETB',
              status: m['status'] as String? ?? '—',
              updatedAt: DateTime.tryParse(m['paidAt'] as String? ?? '') ?? DateTime.now(),
              referenceNo: m['referenceNo'] as String?,
              slipUrl: m['slipUrl'] as String?,
            ),
          );
        }
      } catch (_) {}
    }
    return out;
  }
}
