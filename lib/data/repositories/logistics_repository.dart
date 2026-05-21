import 'package:global_logistics_app/data/models/driver_offer_model.dart';
import 'package:global_logistics_app/data/models/shipment_model.dart';
import 'package:global_logistics_app/data/models/shipment_status.dart';

/// Contract for the existing backend. Replace [MockLogisticsRepository] with
/// HTTP/WebSocket implementations when API details are wired.
abstract class LogisticsRepository {
  Future<List<ShipmentModel>> fetchConsignorShipments();
  Future<ShipmentModel?> getShipment(String id);
  Future<List<DriverOfferModel>> fetchDriverOffers();
  Future<List<ShipmentModel>> fetchDriverAssignedShipments();
  Future<List<DocumentRef>> fetchDocumentsForAssignment(String assignmentId);
  Future<List<PaymentRecord>> fetchPayments();
  Future<List<DriverAssignmentFinance>> fetchDriverPayouts();
}

class MockLogisticsRepository implements LogisticsRepository {
  static final _now = DateTime(2026, 3, 31, 10, 30);

  static final _shipments = <ShipmentModel>[
    ShipmentModel(
      id: 's1',
      publicId: 'GLC-76403',
      status: ShipmentStatus.inTransit,
      loadingAddress: 'Industrial Zone 4, Addis Ababa',
      offloadingAddress: 'Port of Djibouti — Gate B',
      goodsDescription: 'Machinery parts — palletized',
      weightKg: 4200,
      volumeM3: 18.5,
      vehicleType: 'Flatbed 40t',
      timelineNote: 'ETA window: Mar 31 – Apr 2',
      placedAt: _now.subtract(const Duration(days: 3)),
      estimatedDelivery: _now.add(const Duration(hours: 17)),
      progress01: 0.62,
      paymentMethod: 'Bank transfer',
      priceOffer: 12850,
      driver: const DriverSummary(
        id: 'd1',
        name: 'Daniel Tadesse',
        rating: 4.8,
        phone: '+251 91 …',
        vehicleLabel: 'Volvo FH — Flatbed',
        plate: 'AA-3-48291',
      ),
    ),
    ShipmentModel(
      id: 's2',
      publicId: 'GLC-56938',
      status: ShipmentStatus.pendingReview,
      loadingAddress: 'Kality Warehouse, Addis Ababa',
      offloadingAddress: 'Bahir Dar Logistics Hub',
      goodsDescription: 'Consumer electronics — boxed',
      weightKg: 890,
      volumeM3: 6.2,
      vehicleType: 'Box truck 10t',
      timelineNote: 'Flexible — within 5 business days',
      placedAt: _now.subtract(const Duration(hours: 6)),
      estimatedDelivery: null,
      progress01: 0.08,
      paymentMethod: 'Mobile money',
    ),
    ShipmentModel(
      id: 's3',
      publicId: 'GLC-44102',
      status: ShipmentStatus.completed,
      loadingAddress: 'Mojo Dry Port',
      offloadingAddress: 'Hawassa Industrial Park',
      goodsDescription: 'Textile rolls',
      weightKg: 12000,
      volumeM3: 42,
      vehicleType: 'Curtain-side trailer',
      timelineNote: 'Delivered on schedule',
      placedAt: _now.subtract(const Duration(days: 21)),
      estimatedDelivery: _now.subtract(const Duration(days: 2)),
      progress01: 1,
      paymentMethod: 'Bank transfer',
      priceOffer: 45200,
      driver: const DriverSummary(
        id: 'd2',
        name: 'Hanna Bekele',
        rating: 4.9,
        phone: '+251 92 …',
        vehicleLabel: 'Mercedes Actros',
        plate: 'OR-8-10293',
      ),
    ),
  ];

  @override
  Future<List<ShipmentModel>> fetchConsignorShipments() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return List.from(_shipments);
  }

  @override
  Future<ShipmentModel?> getShipment(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    try {
      return _shipments.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<DriverOfferModel>> fetchDriverOffers() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return [
      DriverOfferModel(
        negotiationId: 'neg_demo_1',
        shipmentId: 's_offer_1',
        routeSummary: 'Addis Ababa → Dire Dawa',
        price: 18500,
        currency: 'ETB',
        distanceKm: 445,
        expiresAt: _now.add(const Duration(hours: 8)),
      ),
      DriverOfferModel(
        negotiationId: 'neg_demo_2',
        shipmentId: 's_offer_2',
        routeSummary: 'Modjo → Djibouti Port',
        price: 64200,
        currency: 'ETB',
        distanceKm: 930,
        expiresAt: _now.add(const Duration(hours: 20)),
      ),
    ];
  }

  @override
  Future<List<ShipmentModel>> fetchDriverAssignedShipments() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return _shipments
        .where(
          (s) =>
              s.status == ShipmentStatus.inTransit ||
              s.status == ShipmentStatus.loading ||
              s.status == ShipmentStatus.driverAssigned,
        )
        .toList();
  }

  @override
  Future<List<DocumentRef>> fetchDocumentsForAssignment(String assignmentId) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return [
      DocumentRef(
        id: 'gdn-$assignmentId',
        title: 'Goods Delivery Note',
        type: 'GDN',
        availableAt: _now.subtract(const Duration(days: 1)),
      ),
      DocumentRef(
        id: 'grn-$assignmentId',
        title: 'Goods Received Note',
        type: 'GRN',
        availableAt: _now,
      ),
    ];
  }

  @override
  Future<List<PaymentRecord>> fetchPayments() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return [
      PaymentRecord(
        id: 'p1',
        amount: 12850,
        currency: 'ETB',
        status: 'Verified',
        updatedAt: _now.subtract(const Duration(days: 1)),
      ),
    ];
  }

  @override
  Future<List<DriverAssignmentFinance>> fetchDriverPayouts() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return [
      DriverAssignmentFinance(
        publicId: 'fin_demo_1',
        assignmentId: 'asg_demo_1',
        agreedAmount: 18500,
        paidAmount: 18500,
        remainingAmount: 0,
        status: 'PAID',
        updatedAt: _now.subtract(const Duration(days: 2)),
        shipmentLabel: 'GLC-76403',
      ),
    ];
  }
}
