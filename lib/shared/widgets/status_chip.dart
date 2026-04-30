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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: fg.withValues(alpha: 0.12)),
      ),
      child: Text(
        labelOverride ?? status.label,
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
