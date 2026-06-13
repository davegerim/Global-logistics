import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';
import 'package:global_logistics_app/core/extensions/l10n_extension.dart';
import 'package:global_logistics_app/core/providers/backend_api_provider.dart';
import 'package:global_logistics_app/core/utils/assignment_display.dart';
import 'package:global_logistics_app/data/mappers/api_mappers.dart';
import 'package:global_logistics_app/data/models/shipment_model.dart';
import 'package:global_logistics_app/shared/widgets/status_chip.dart';

class ConsignorAssignmentPreview {
  const ConsignorAssignmentPreview({
    required this.assignmentId,
    required this.status,
    required this.sequenceNumber,
  });

  final String assignmentId;
  final String status;
  final int sequenceNumber;
}

sealed class ConsignorAssignmentPickerResult {}

final class ConsignorAssignmentPickerAssignmentSelected
    extends ConsignorAssignmentPickerResult {
  ConsignorAssignmentPickerAssignmentSelected(this.assignment);

  final ConsignorAssignmentPreview assignment;
}

final class ConsignorAssignmentPickerPaymentSelected
    extends ConsignorAssignmentPickerResult {}

const _assignedOrLaterStatuses = {
  'SELECTED',
  'ASSIGNED',
  'CONSIGNOR_ACCEPTED',
  'ADMIN_APPROVED',
  'DRIVER_ASSIGNED',
  'GDN_GENERATED',
  'LOADED',
  'IN_TRANSIT',
  'ARRIVED',
  'OFFLOADED',
  'GRN_GENERATED',
  'CONSIGNOR_RECEIVED',
  'COMPLETED',
};

bool consignorBookingPaymentEnabled(
  ShipmentModel shipment,
  List<ConsignorAssignmentPreview> assignments,
) {
  final bookingStatus = (shipment.apiStatusLabel ?? '').trim().toUpperCase();
  if (_assignedOrLaterStatuses.contains(bookingStatus)) return true;
  return assignments.any(
    (a) => _assignedOrLaterStatuses.contains(a.status.trim().toUpperCase()),
  );
}

String? _extractAssignmentId(Map<String, dynamic> row) {
  final id = row['assignmentId']?.toString().trim();
  if (id != null && id.isNotEmpty) return id;
  final publicId = row['publicId']?.toString().trim();
  if (publicId != null && publicId.isNotEmpty) return publicId;
  final fallback = row['id']?.toString().trim();
  if (fallback != null && fallback.isNotEmpty) return fallback;
  return null;
}

String _extractAssignmentStatus(Map<String, dynamic> row) {
  final status =
      row['status']?.toString() ??
      row['assignmentStatus']?.toString() ??
      row['currentStatus']?.toString() ??
      '';
  return status.trim().toUpperCase();
}

Future<List<ConsignorAssignmentPreview>> loadConsignorAssignmentPreviews(
  WidgetRef ref,
  ShipmentModel shipment,
) async {
  final api = ref.read(backendApiProvider);
  final shipmentPublicId = shipment.publicId.trim().isNotEmpty
      ? shipment.publicId.trim()
      : shipment.id.trim();
  List<dynamic> raw = const [];
  if (shipmentPublicId.isNotEmpty) {
    raw = await api.assignmentsConsignorOfShipment(shipmentPublicId);
  }
  final previews = <ConsignorAssignmentPreview>[];
  for (final row in raw) {
    if (row is! Map) continue;
    final m = row.cast<String, dynamic>();
    final assignmentId = _extractAssignmentId(m);
    if (assignmentId == null || assignmentId.isEmpty) continue;
    previews.add(
      ConsignorAssignmentPreview(
        assignmentId: assignmentId,
        status: _extractAssignmentStatus(m),
        sequenceNumber: previews.length + 1,
      ),
    );
  }
  return previews;
}

/// Bottom sheet listing assignments for a multi-assignment booking, with a
/// payment entry below the assignment list.
class ConsignorAssignmentPickerSheet extends StatelessWidget {
  const ConsignorAssignmentPickerSheet({
    super.key,
    required this.shipment,
    required this.assignments,
  });

  final ShipmentModel shipment;
  final List<ConsignorAssignmentPreview> assignments;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  shipment.displayId
                      .replaceAll('Booking ', context.l10n.bookingPrefix)
                      .replaceAll(
                        'Assignment ',
                        context.l10n.assignmentPrefix,
                      ),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  context.l10n.assignmentsTitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: assignments.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final item = assignments[i];
                    final mappedStatus = mapAssignmentStatus(item.status);
                    return _PickerRow(
                      icon: Icons.assignment_rounded,
                      title: AssignmentDisplay.sequenceLabel(
                        context.l10n.assignmentPrefix,
                        item.sequenceNumber,
                      ),
                      statusChip: StatusChip(
                        status: mappedStatus,
                        labelOverride: item.status,
                      ),
                      onTap: () => Navigator.of(context).pop(
                        ConsignorAssignmentPickerAssignmentSelected(item),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _PickerRow(
                  icon: Icons.payments_outlined,
                  title: context.l10n.payments,
                  onTap: () => Navigator.of(
                    context,
                  ).pop(ConsignorAssignmentPickerPaymentSelected()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.statusChip,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Widget? statusChip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (statusChip != null) ...[
                      const SizedBox(height: 6),
                      statusChip!,
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
