import 'package:global_logistics_app/core/utils/assignment_display.dart';
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
    this.assignmentSequenceNumber,
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

  /// 1-based index within a booking when known (UI label only).
  final int? assignmentSequenceNumber;
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

  ShipmentModel copyWith({int? assignmentSequenceNumber}) {
    return ShipmentModel(
      id: id,
      publicId: publicId,
      status: status,
      loadingAddress: loadingAddress,
      offloadingAddress: offloadingAddress,
      goodsDescription: goodsDescription,
      weightKg: weightKg,
      volumeM3: volumeM3,
      vehicleType: vehicleType,
      timelineNote: timelineNote,
      placedAt: placedAt,
      estimatedDelivery: estimatedDelivery,
      driver: driver,
      progress01: progress01,
      paymentMethod: paymentMethod,
      priceOffer: priceOffer,
      apiStatusLabel: apiStatusLabel,
      assignmentId: assignmentId,
      assignmentDisplayId: assignmentDisplayId,
      assignmentSequenceNumber:
          assignmentSequenceNumber ?? this.assignmentSequenceNumber,
      bookingId: bookingId,
    );
  }

  String get displayId {
    final normalized = bookingId?.trim();
    if (normalized != null && normalized.isNotEmpty) {
      return 'Booking #$normalized'; // Actually, we should localize this. Let's just leave it if it's not a widget, or use an extension? Wait, `displayId` is a getter, no context here.
    }
    final seq = assignmentSequenceNumber;
    if (seq != null && seq >= 1) {
      return 'Assignment #$seq';
    }
    final normalizedAssignment = assignmentDisplayId?.trim();
    if (normalizedAssignment != null &&
        normalizedAssignment.isNotEmpty &&
        !AssignmentDisplay.isUuidLike(normalizedAssignment)) {
      return 'Assignment #$normalizedAssignment';
    }
    if (assignmentId != null ||
        (normalizedAssignment != null && normalizedAssignment.isNotEmpty)) {
      return 'Assignment #1';
    }
    return publicId;
  }

  String get assignmentLabel {
    final seq = assignmentSequenceNumber;
    if (seq != null && seq >= 1) {
      return 'Assignment #$seq';
    }
    final normalized = assignmentDisplayId?.trim();
    if (normalized != null &&
        normalized.isNotEmpty &&
        !AssignmentDisplay.isUuidLike(normalized)) {
      return 'Assignment #$normalized';
    }
    if (assignmentId != null) {
      return 'Assignment #1';
    }
    return 'assignmentId: $publicId';
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

  bool get isVoided {
    final s = status?.trim().toUpperCase();
    return s == 'VOID' || s == 'VOIDED';
  }
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
