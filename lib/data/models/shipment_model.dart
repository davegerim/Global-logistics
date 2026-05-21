import 'package:global_logistics_app/data/models/shipment_status.dart';

class DriverSummary {
  const DriverSummary({
    required this.id,
    required this.name,
    this.rating,
    this.phone,
    this.vehicleLabel,
    this.plate,
  });

  final String id;
  final String name;
  final double? rating;
  final String? phone;
  final String? vehicleLabel;
  final String? plate;
}

class ShipmentModel {
  const ShipmentModel({
    required this.id,
    required this.publicId,
    required this.status,
    required this.loadingAddress,
    required this.offloadingAddress,
    required this.goodsDescription,
    required this.weightKg,
    required this.volumeM3,
    required this.vehicleType,
    required this.timelineNote,
    required this.placedAt,
    required this.estimatedDelivery,
    this.driver,
    this.progress01,
    this.paymentMethod,
    this.priceOffer,
    this.apiStatusLabel,
    this.assignmentId,
    this.assignmentDisplayId,
    this.bookingId,
  });

  final String id;
  final String publicId;
  final String? bookingId;
  final ShipmentStatus status;

  /// Raw `currentStatus` / assignment status from API (for debugging / tooltips).
  final String? apiStatusLabel;

  /// Assignment public UUID when known (driver flows, tracking).
  final String? assignmentId;
  final String? assignmentDisplayId;
  final String loadingAddress;
  final String offloadingAddress;
  final String goodsDescription;
  final double weightKg;
  final double volumeM3;
  final String vehicleType;
  final String timelineNote;
  final DateTime placedAt;
  final DateTime? estimatedDelivery;
  final DriverSummary? driver;
  final double? progress01;
  final String? paymentMethod;
  final double? priceOffer;

  String get displayId {
    final normalized = bookingId?.trim();
    if (normalized != null && normalized.isNotEmpty) {
      return 'Booking #$normalized'; // Actually, we should localize this. Let's just leave it if it's not a widget, or use an extension? Wait, `displayId` is a getter, no context here.
    }
    final normalizedAssignment = assignmentDisplayId?.trim();
    if (normalizedAssignment != null && normalizedAssignment.isNotEmpty) {
      return 'Assignment #$normalizedAssignment';
    }
    return publicId;
  }

  String get assignmentLabel {
    final normalized = assignmentDisplayId?.trim();
    if (normalized != null && normalized.isNotEmpty) {
      return 'Assignment #$normalized';
    }
    return 'assignmentId: ${assignmentId ?? publicId}';
  }
}

class DocumentRef {
  const DocumentRef({
    required this.id,
    required this.title,
    required this.type,
    required this.availableAt,
    this.documentNumber,
    this.qrCodeValue,
    this.status,
  });

  final String id;
  final String title;
  final String type;
  final DateTime availableAt;
  final String? documentNumber;
  final String? qrCodeValue;
  final String? status;
}

class PaymentRecord {
  const PaymentRecord({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    required this.updatedAt,
    this.referenceNo,
    this.slipUrl,
  });

  final String id;
  final double amount;
  final String currency;
  final String status;
  final DateTime updatedAt;
  final String? referenceNo;
  final String? slipUrl;
}

/// Assignment finance summary from GET /assignment-finance/{assignmentId}.
class DriverAssignmentFinance {
  const DriverAssignmentFinance({
    required this.publicId,
    required this.assignmentId,
    required this.agreedAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.status,
    required this.updatedAt,
    required this.shipmentLabel,
    this.currency = 'ETB',
    this.payments = const [],
  });

  final String publicId;
  final String assignmentId;
  final double agreedAmount;
  final double paidAmount;
  final double remainingAmount;
  final String status;
  final DateTime updatedAt;
  final String shipmentLabel;
  final String currency;
  final List<PaymentRecord> payments;
}
