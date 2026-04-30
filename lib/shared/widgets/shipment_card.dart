import 'package:flutter/material.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';
import 'package:global_logistics_app/data/models/shipment_model.dart';
import 'package:global_logistics_app/data/models/shipment_status.dart';
import 'package:global_logistics_app/shared/widgets/status_chip.dart';
import 'package:intl/intl.dart';

class ShipmentCard extends StatelessWidget {
  const ShipmentCard({
    super.key,
    required this.shipment,
    this.onTap,
    this.showTimeline = true,
  });

  final ShipmentModel shipment;
  final VoidCallback? onTap;
  final bool showTimeline;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final dateFmt = DateFormat.MMMd();
    return Material(
      color: AppColors.surface,
      elevation: 0,
      shadowColor: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.06),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        shipment.publicId,
                        style: t.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    StatusChip(
                      status: shipment.status,
                      labelOverride: shipment.apiStatusLabel,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _row(
                  context,
                  Icons.upload_rounded,
                  'From',
                  shipment.loadingAddress,
                ),
                const SizedBox(height: 10),
                _row(
                  context,
                  Icons.download_rounded,
                  'To',
                  shipment.offloadingAddress,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Placed ${dateFmt.format(shipment.placedAt)}',
                      style: t.bodyMedium,
                    ),
                    if (shipment.estimatedDelivery != null) ...[
                      const SizedBox(width: 12),
                      Icon(
                        Icons.flag_outlined,
                        size: 16,
                        color: AppColors.gold,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Est. ${dateFmt.format(shipment.estimatedDelivery!)}',
                        style: t.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
                if (showTimeline) ...[
                  const SizedBox(height: 18),
                  _ProgressStrip(
                    progress:
                        shipment.progress01 ??
                        _fallbackProgress(shipment.status),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, IconData icon, String label, String value) {
    final t = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: t.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: t.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static double _fallbackProgress(ShipmentStatus s) => switch (s) {
    ShipmentStatus.completed => 1,
    ShipmentStatus.inTransit => 0.55,
    ShipmentStatus.pendingReview => 0.1,
    _ => 0.35,
  };
}

class _ProgressStrip extends StatelessWidget {
  const _ProgressStrip({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: t.labelMedium?.copyWith(color: AppColors.textSecondary),
            ),
            Text(
              '${(progress * 100).round()}%',
              style: t.labelLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: progress.clamp(0, 1),
            minHeight: 10,
            backgroundColor: AppColors.surfaceMuted,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}
