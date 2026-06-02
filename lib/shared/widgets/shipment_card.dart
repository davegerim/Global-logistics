import 'package:global_logistics_app/core/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';
import 'package:global_logistics_app/data/models/shipment_model.dart';
import 'package:global_logistics_app/shared/widgets/status_chip.dart';
import 'package:intl/intl.dart';

class ShipmentCard extends StatelessWidget {
  const ShipmentCard({
    super.key,
    required this.shipment,
    this.onTap,
    this.assignmentStatuses = const [],
    this.assignmentsLoading = false,
  });

  final ShipmentModel shipment;
  final VoidCallback? onTap;
  final List<String> assignmentStatuses;
  final bool assignmentsLoading;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final dateFmt = DateFormat.MMMd(context.l10n.localeName);
    return Material(
      color: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            shipment.displayId
                                .replaceAll(
                                  'Booking #',
                                  context.l10n.bookingPrefix,
                                )
                                .replaceAll(
                                  'Assignment #',
                                  context.l10n.assignmentPrefix,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusChip(
                          status: shipment.status,
                          labelOverride: shipment.apiStatusLabel,
                        ),
                      ],
                    ),
                    if (assignmentsLoading ||
                        assignmentStatuses.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _assignmentStatusSection(context),
                    ],
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.only(right: 110),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _row(
                            context,
                            Icons.upload_rounded,
                            context.l10n.fromLabel,
                            context.translateDynamic(shipment.loadingAddress),
                          ),
                          const SizedBox(height: 10),
                          _row(
                            context,
                            Icons.download_rounded,
                            context.l10n.toLabel,
                            context.translateDynamic(
                              shipment.offloadingAddress,
                            ),
                          ),
                        ],
                      ),
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
                          '${context.l10n.placedPrefix}${dateFmt.format(shipment.placedAt)}',
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
                            '${context.l10n.estPrefix}${dateFmt.format(shipment.estimatedDelivery!)}',
                            style: t.bodyMedium?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                right: -15,
                top: 60,
                child: IgnorePointer(
                  child: Image.asset(
                    'assets/images/boxes-3d-icon-png-download-4504985.webp',
                    width: 135,
                    height: 135,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _assignmentStatusSection(BuildContext context) {
    if (assignmentsLoading) {
      return const LinearProgressIndicator(minHeight: 4);
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: assignmentStatuses.map((status) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Text(
              context.translateDynamic(status),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        }).toList(),
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
}
