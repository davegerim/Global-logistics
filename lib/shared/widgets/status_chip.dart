import 'package:global_logistics_app/core/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';
import 'package:global_logistics_app/data/models/shipment_status.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.status,
    this.labelOverride,
  });

  final ShipmentStatus status;
  /// When set (e.g. raw API enum), shown instead of [status.label].
  final String? labelOverride;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors(status);
    String labelToDisplay = labelOverride ?? _localizeStatus(context, status);
    // Try to localize known API override labels as well
    if (labelOverride != null) {
      if (labelOverride == 'APPROVED') labelToDisplay = context.l10n.approvedLabel;
      if (labelOverride == 'COMPLETED') labelToDisplay = context.l10n.completedLabel;
      if (labelOverride == 'CANCELLED') labelToDisplay = context.l10n.cancelledLabel;
      if (labelOverride == 'IN TRANSIT') labelToDisplay = context.l10n.inTransitLabel;
      if (labelOverride == 'ARRIVED') labelToDisplay = context.l10n.arrivedLabel;
      if (labelOverride == 'OFFLOADED') labelToDisplay = context.l10n.offloadedLabel;
      if (labelOverride == 'LOADED') labelToDisplay = context.l10n.loadedLabel;
      if (labelOverride == 'GDN GENERATED') labelToDisplay = context.l10n.gdnGeneratedLabel;
      if (labelOverride == 'GRN GENERATED') labelToDisplay = context.l10n.grnGeneratedLabel;
      if (labelOverride == 'CONSIGNOR ACCEPTED') labelToDisplay = context.l10n.consignorAcceptedLabel;
      if (labelOverride == 'DRIVER ASSIGNED') labelToDisplay = context.l10n.driverAssignedLabel;
      if (labelOverride == 'SELECTED') labelToDisplay = context.l10n.selectedLabel;
      if (labelOverride == 'CONSIGNOR RECEIVED') labelToDisplay = context.l10n.consignorReceivedLabel;
      if (labelOverride == 'ADMIN APPROVED') labelToDisplay = context.l10n.adminApprovedLabel;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: fg.withValues(alpha: 0.12)),
      ),
      child: Text(
        labelToDisplay,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

(Color bg, Color fg) _colors(ShipmentStatus s) {
  return switch (s) {
    ShipmentStatus.completed => (AppColors.success.withValues(alpha: 0.12), AppColors.success),
    ShipmentStatus.inTransit ||
    ShipmentStatus.loading ||
    ShipmentStatus.atDestination ||
    ShipmentStatus.offloading =>
      (AppColors.goldLight, const Color(0xFF6B5A2E)),
    ShipmentStatus.cancelled => (AppColors.error.withValues(alpha: 0.1), AppColors.error),
    _ => (AppColors.primary.withValues(alpha: 0.1), AppColors.primary),
  };
}

String _localizeStatus(BuildContext context, ShipmentStatus s) {
  return switch (s) {
    ShipmentStatus.pendingReview => context.l10n.statusPendingReview,
    ShipmentStatus.awaitingDriver => context.l10n.statusAwaitingDriver,
    ShipmentStatus.driverAssigned => context.l10n.statusDriverAssigned,
    ShipmentStatus.gdnIssued => context.l10n.statusGdnIssued,
    ShipmentStatus.loading => context.l10n.statusLoading,
    ShipmentStatus.inTransit => context.l10n.statusInTransit,
    ShipmentStatus.atDestination => context.l10n.statusAtDestination,
    ShipmentStatus.offloading => context.l10n.statusOffloading,
    ShipmentStatus.delivered => context.l10n.statusDelivered,
    ShipmentStatus.completed => context.l10n.statusCompleted,
    ShipmentStatus.cancelled => context.l10n.statusCancelled,
  };
}
