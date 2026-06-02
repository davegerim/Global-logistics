import 'package:global_logistics_app/core/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:global_logistics_app/core/providers/backend_api_provider.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';
import 'package:global_logistics_app/core/errors/user_facing_error.dart';
import 'package:global_logistics_app/core/providers/auth_provider.dart';
import 'package:global_logistics_app/core/providers/shipments_provider.dart';
import 'package:global_logistics_app/data/mappers/api_mappers.dart';
import 'package:global_logistics_app/data/models/shipment_model.dart';
import 'package:global_logistics_app/data/models/shipment_status.dart';
import 'package:global_logistics_app/shared/widgets/status_chip.dart';
import 'package:global_logistics_app/shared/widgets/shipment_card.dart';

class ConsignorShipmentsScreen extends ConsumerStatefulWidget {
  const ConsignorShipmentsScreen({super.key});

  @override
  ConsumerState<ConsignorShipmentsScreen> createState() =>
      _ConsignorShipmentsScreenState();
}

class _ConsignorShipmentsScreenState
    extends ConsumerState<ConsignorShipmentsScreen> {
  String _filter = 'all';
  final Map<String, List<_AssignmentPreview>> _assignmentPreviewsByShipment =
      {};
  final Set<String> _loadingAssignments = <String>{};
  final Set<String> _scheduledAssignmentLoads = <String>{};
  final Map<String, Future<void>> _assignmentLoadTasks = {};

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(consignorShipmentsProvider);
    final auth = ref.watch(authProvider);
    final awaitingApproval = !auth.canCreateConsignorBooking;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(context.l10n.myShipments)),
      body: async.when(
        data: (list) {
          final filtered = _applyFilter(list, _filter);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  children: [
                    _FilterChip(
                      label: context.l10n.all,
                      selected: _filter == 'all',
                      onTap: () => setState(() => _filter = 'all'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: context.l10n.inProgress,
                      selected: _filter == 'progress',
                      onTap: () => setState(() => _filter = 'progress'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: context.l10n.delivered,
                      selected: _filter == 'done',
                      onTap: () => setState(() => _filter = 'done'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? _ShipmentsEmptyState(awaitingApproval: awaitingApproval)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => SizedBox(height: 14),
                        itemBuilder: (context, i) {
                          final s = filtered[i];
                          _ensureAssignmentPreviewsLoaded(s);
                          final previews =
                              _assignmentPreviewsByShipment[s.id] ?? const [];
                          return ShipmentCard(
                            shipment: s,
                            assignmentStatuses: previews
                                .map((e) => e.status)
                                .where((e) => e.isNotEmpty)
                                .toList(),
                            assignmentsLoading: _loadingAssignments.contains(
                              s.id,
                            ),
                            onTap: () => _onShipmentTap(s),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(userFacingMessage(e))),
      ),
    );
  }

  List<ShipmentModel> _applyFilter(List<ShipmentModel> list, String filter) {
    bool inProgress(ShipmentStatus s) =>
        s != ShipmentStatus.completed && s != ShipmentStatus.cancelled;
    return switch (filter) {
      'progress' => list.where((s) => inProgress(s.status)).toList(),
      'done' =>
        list.where((s) => s.status == ShipmentStatus.completed).toList(),
      _ => list,
    };
  }

  void _ensureAssignmentPreviewsLoaded(ShipmentModel shipment) {
    if (_assignmentPreviewsByShipment.containsKey(shipment.id) ||
        _loadingAssignments.contains(shipment.id) ||
        _scheduledAssignmentLoads.contains(shipment.id)) {
      return;
    }
    _scheduledAssignmentLoads.add(shipment.id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scheduledAssignmentLoads.remove(shipment.id);
      if (_assignmentPreviewsByShipment.containsKey(shipment.id) ||
          _loadingAssignments.contains(shipment.id)) {
        return;
      }
      _loadAssignmentPreviews(shipment);
    });
  }

  Future<void> _loadAssignmentPreviews(ShipmentModel shipment) async {
    final existingTask = _assignmentLoadTasks[shipment.id];
    if (existingTask != null) {
      await existingTask;
      return;
    }
    final task = _performAssignmentPreviewLoad(shipment);
    _assignmentLoadTasks[shipment.id] = task;
    await task;
  }

  Future<void> _performAssignmentPreviewLoad(ShipmentModel shipment) async {
    if (_assignmentPreviewsByShipment.containsKey(shipment.id) ||
        _loadingAssignments.contains(shipment.id)) {
      return;
    }
    setState(() => _loadingAssignments.add(shipment.id));
    try {
      final api = ref.read(backendApiProvider);
      final candidates = <String>{
        shipment.id,
        shipment.publicId,
        if ((shipment.bookingId ?? '').trim().isNotEmpty)
          shipment.bookingId!.trim(),
      };
      List<dynamic> raw = const [];
      for (final candidate in candidates) {
        raw = await api.assignmentsConsignorOfShipment(candidate);
        if (raw.isNotEmpty) break;
      }
      final previews = <_AssignmentPreview>[];
      for (final row in raw) {
        if (row is! Map) continue;
        final m = row.cast<String, dynamic>();
        final assignmentId = _extractAssignmentId(m);
        if (assignmentId == null || assignmentId.isEmpty) continue;
        final status = _extractAssignmentStatus(m);
        previews.add(
          _AssignmentPreview(assignmentId: assignmentId, status: status),
        );
      }
      if (!mounted) return;
      setState(() {
        _assignmentPreviewsByShipment[shipment.id] = previews;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _assignmentPreviewsByShipment[shipment.id] = const [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingAssignments.remove(shipment.id);
          _assignmentLoadTasks.remove(shipment.id);
        });
      } else {
        _assignmentLoadTasks.remove(shipment.id);
      }
    }
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

  Future<void> _onShipmentTap(ShipmentModel shipment) async {
    final previews = await _ensureAndGetAssignmentPreviews(shipment);
    if (!mounted) return;
    if (previews.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.noAssignmentYet)));
      return;
    }
    final selected = await showModalBottomSheet<_AssignmentPreview>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) =>
          _AssignmentPickerSheet(shipment: shipment, assignments: previews),
    );
    if (!mounted || selected == null) return;
    context.push(
      '/consignor/shipment/${shipment.id}?assignment=${selected.assignmentId}',
    );
  }

  Future<List<_AssignmentPreview>> _ensureAndGetAssignmentPreviews(
    ShipmentModel shipment,
  ) async {
    final existing = _assignmentPreviewsByShipment[shipment.id];
    if (existing != null) return existing;
    await _loadAssignmentPreviews(shipment);
    return _assignmentPreviewsByShipment[shipment.id] ?? const [];
  }
}

class _AssignmentPreview {
  const _AssignmentPreview({required this.assignmentId, required this.status});

  final String assignmentId;
  final String status;
}

class _AssignmentPickerSheet extends StatelessWidget {
  const _AssignmentPickerSheet({
    required this.shipment,
    required this.assignments,
  });

  final ShipmentModel shipment;
  final List<_AssignmentPreview> assignments;

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
                    .replaceAll('Booking #', context.l10n.bookingPrefix)
                    .replaceAll('Assignment #', context.l10n.assignmentPrefix),
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
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.58,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: assignments.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final item = assignments[i];
                    final mappedStatus = mapAssignmentStatus(item.status);
                    return Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => Navigator.of(context).pop(item),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.borderLight),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(
                                  alpha: 0.04,
                                ),
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
                                child: const Icon(
                                  Icons.assignment_rounded,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${context.l10n.assignmentPrefix}${item.assignmentId}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    StatusChip(
                                      status: mappedStatus,
                                      labelOverride: item.status,
                                    ),
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
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShipmentsEmptyState extends StatelessWidget {
  const _ShipmentsEmptyState({required this.awaitingApproval});

  final bool awaitingApproval;

  @override
  Widget build(BuildContext context) {
    final title = awaitingApproval
        ? 'Account approval pending'
        : 'No shipments yet';
    final subtitle = awaitingApproval
        ? 'Your account is verified but not yet approved by admin. Shipments will appear here after approval.'
        : 'You do not have shipments for this filter yet.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              awaitingApproval ? Icons.lock_clock_rounded : Icons.inbox_rounded,
              size: 36,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.surface,
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
