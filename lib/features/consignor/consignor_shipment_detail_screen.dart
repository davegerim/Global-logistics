import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';
import 'package:global_logistics_app/core/providers/backend_api_provider.dart';
import 'package:global_logistics_app/core/providers/consignor_active_provider.dart';
import 'package:global_logistics_app/core/providers/shipments_provider.dart';
import 'package:global_logistics_app/data/models/shipment_model.dart';
import 'package:global_logistics_app/shared/widgets/gl_primary_button.dart';
import 'package:global_logistics_app/shared/widgets/status_chip.dart';
import 'package:intl/intl.dart';

class ConsignorShipmentDetailScreen extends ConsumerStatefulWidget {
  const ConsignorShipmentDetailScreen({super.key, required this.shipmentId});

  final String shipmentId;

  @override
  ConsumerState<ConsignorShipmentDetailScreen> createState() =>
      _ConsignorShipmentDetailScreenState();
}

class _ConsignorShipmentDetailScreenState
    extends ConsumerState<ConsignorShipmentDetailScreen> {
  static const Set<String> _assignedOrLaterStatuses = {
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

  String? _assignmentId;
  bool _resolvingAssignment = false;
  bool _gdnCreated = false;
  String? _gdnMessage;
  bool _grnCreated = false;
  String? _grnMessage;
  String? _assignmentApiStatus;
  bool _resolvingDriverSelection = false;
  bool _driverSelected = false;
  String? _selectionResolvedForShipment;

  Future<void> _resolveAssignmentIfNeeded(ShipmentModel s) async {
    if (_resolvingAssignment || _assignmentId != null || !mounted) return;
    setState(() => _resolvingAssignment = true);
    try {
      final api = ref.read(backendApiProvider);
      final assignments = await api.assignmentsConsignorOfShipment(s.id);
      String? found;
      String? resolvedAssignmentStatus;
      if (assignments.isNotEmpty && assignments.first is Map) {
        final row = (assignments.first as Map).cast<String, dynamic>();
        found =
            (row['assignmentId'] as String?) ??
            (row['publicId'] as String?) ??
            (row['id'] as String?);
        final rawStatus =
            row['status'] ?? row['assignmentStatus'] ?? row['currentStatus'];
        if (rawStatus is String && rawStatus.trim().isNotEmpty) {
          resolvedAssignmentStatus = rawStatus.trim().toUpperCase();
        }
      }
      if (!mounted) return;
      setState(() {
        _assignmentId = found;
        _assignmentApiStatus = resolvedAssignmentStatus;
      });
      if (found != null) {
        await _refreshGdnState(found);
        await _refreshGrnState(found);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _resolvingAssignment = false);
    }
  }

  Future<void> _refreshGdnState(String assignmentId) async {
    try {
      final gdns = await ref
          .read(backendApiProvider)
          .gdnOfAssignment(assignmentId);
      if (!mounted) return;
      setState(() {
        _gdnCreated = gdns.isNotEmpty;
        if (_gdnCreated) {
          _gdnMessage = 'GDN already generated and locked.';
        }
      });
    } catch (_) {}
  }

  Future<void> _refreshGrnState(String assignmentId) async {
    try {
      final grns = await ref
          .read(backendApiProvider)
          .grnOfAssignment(assignmentId);
      if (!mounted) return;
      setState(() {
        _grnCreated = grns.isNotEmpty;
        if (_grnCreated) {
          _grnMessage = 'GRN already generated.';
        } else {
          _grnMessage = null;
        }
      });
    } catch (_) {}
  }

  Future<void> _resolveDriverSelectionIfNeeded(ShipmentModel s) async {
    if (_resolvingDriverSelection || !mounted) return;
    if (_selectionResolvedForShipment == s.id) return;
    setState(() => _resolvingDriverSelection = true);
    try {
      final payload = await ref.read(consignorActiveProvider.future);
      final active = _findActiveShipment(payload, s);
      final selected = _hasSelectedDriver(active);
      if (!mounted) return;
      setState(() {
        _driverSelected = selected;
        _selectionResolvedForShipment = s.id;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _driverSelected = false;
        _selectionResolvedForShipment = s.id;
      });
    } finally {
      if (mounted) setState(() => _resolvingDriverSelection = false);
    }
  }

  Map<String, dynamic>? _findActiveShipment(dynamic payload, ShipmentModel s) {
    if (payload is! List) return null;
    for (final item in payload) {
      if (item is! Map) continue;
      final map = item.cast<String, dynamic>();
      final publicId = map['publicId']?.toString();
      if (publicId == s.publicId || publicId == s.id) {
        return map;
      }
    }
    return null;
  }

  bool _hasSelectedDriver(Map<String, dynamic>? shipment) {
    if (shipment == null) return false;
    final selectedDrivers = shipment['selectedDrivers'];
    if (selectedDrivers is! List || selectedDrivers.isEmpty) return false;
    for (final item in selectedDrivers) {
      if (item is! Map) continue;
      final row = item.cast<String, dynamic>();
      final status = (row['status']?.toString() ?? '').trim().toUpperCase();
      if (status == 'SELECTED' ||
          status == 'ASSIGNED' ||
          status == 'DRIVER_ASSIGNED') {
        return true;
      }
    }
    return false;
  }

  bool _isAssignedOrLater(String? apiStatusLabel) {
    final status = (apiStatusLabel ?? '').trim().toUpperCase();
    return _assignedOrLaterStatuses.contains(status);
  }

  bool _canOpenGrnControl(String assignmentStatus) {
    switch (assignmentStatus) {
      case 'OFFLOADED':
      case 'GRN_GENERATED':
      case 'CONSIGNOR_RECEIVED':
      case 'COMPLETED':
        return true;
      default:
        return false;
    }
  }

  bool _handoverConfirmed(String assignmentStatus) {
    switch (assignmentStatus) {
      case 'CONSIGNOR_RECEIVED':
      case 'COMPLETED':
        return true;
      default:
        return false;
    }
  }

  bool _confirmingHandover = false;

  Future<String?> _promptConfirmRemark() async {
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => const _ConsignorConfirmRemarkDialog(),
    );
    if (value == null) return null;
    if (value.isEmpty) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Remark is required to confirm.')),
      );
      return null;
    }
    return value;
  }

  Future<void> _confirmHandover(String shipmentId) async {
    if (_confirmingHandover || _assignmentId == null) return;
    final remark = await _promptConfirmRemark();
    if (!mounted || remark == null) return;
    setState(() => _confirmingHandover = true);
    try {
      await ref.read(backendApiProvider).assignmentsConsignorConfirm({
        'assignmentId': _assignmentId!,
        'remark': remark,
      });
      if (!mounted) return;
      setState(() {
        _assignmentApiStatus = 'CONSIGNOR_RECEIVED';
        _confirmingHandover = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.invalidate(consignorShipmentsProvider);
        ref.invalidate(shipmentDetailProvider(shipmentId));
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Consignor confirmation completed.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted && _confirmingHandover) {
        setState(() => _confirmingHandover = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(consignorShipmentsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Shipment'),
        actions: [
          IconButton(
            onPressed: () {
              _selectionResolvedForShipment = null;
              ref.invalidate(consignorShipmentsProvider);
              ref.invalidate(consignorActiveProvider);
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: async.when(
        data: (shipments) {
          final s = _findShipment(shipments);
          if (s == null) {
            return const Center(child: Text('Shipment not found'));
          }
          _resolveDriverSelectionIfNeeded(s);
          final assignedByStatus = _isAssignedOrLater(s.apiStatusLabel);
          if (_driverSelected || assignedByStatus) {
            _resolveAssignmentIfNeeded(s);
          }
          final assignmentStatus =
              (_assignmentApiStatus ?? s.apiStatusLabel ?? '')
                  .trim()
                  .toUpperCase();
          final gdnControlEnabled =
              _driverSelected || (assignedByStatus && _assignmentId != null);
          final grnControlEnabled =
              _assignmentId != null && _canOpenGrnControl(assignmentStatus);
          final fmt = DateFormat.yMMMd();
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      s.publicId,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  StatusChip(status: s.status, labelOverride: s.apiStatusLabel),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                s.goodsDescription,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              _ProgressCard(progress: s.progress01 ?? 0.0),
              const SizedBox(height: 20),
              _InfoCard(
                children: [
                  _kv('Weight', _formatMetric(s.weightKg)),
                  _kv('Volume', _formatMetric(s.volumeM3)),
                  _kv('Vehicle', s.vehicleType),
                  _kv('Created', fmt.format(s.placedAt)),
                  if (s.paymentMethod != null)
                    _kv('Price type', s.paymentMethod!),
                  if (s.priceOffer != null)
                    _kv('Price', _formatPrice(s.priceOffer!)),
                ],
              ),
              const SizedBox(height: 16),
              _TimelineCard(
                loading: s.loadingAddress,
                offloading: s.offloadingAddress,
                placed: fmt.format(s.placedAt),
                eta: s.estimatedDelivery != null
                    ? fmt.format(s.estimatedDelivery!)
                    : 'TBD',
              ),
              if (s.timelineNote.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                _InfoCard(children: [_kv('Notes', s.timelineNote.trim())]),
              ],
              if (s.driver != null) ...[
                const SizedBox(height: 16),
                _DriverCard(
                  name: s.driver!.name,
                  vehicle: s.driver!.vehicleLabel ?? '—',
                  plate: s.driver!.plate ?? '—',
                  rating: s.driver!.rating,
                ),
              ],
              const SizedBox(height: 16),
              _InfoCard(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.assignment_turned_in_outlined,
                        color: AppColors.primary.withValues(alpha: 0.85),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'GDN Control',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_resolvingAssignment)
                    const LinearProgressIndicator()
                  else if (_resolvingDriverSelection)
                    const LinearProgressIndicator()
                  else if (!gdnControlEnabled)
                    const Text(
                      'GDN control becomes available once admin selects and assigns a driver.',
                    )
                  else if (_assignmentId == null)
                    const Text(
                      'Waiting for driver assignment. Once assigned, create GDN before driver can continue status updates.',
                    )
                  else ...[
                    _kv('Assignment', _assignmentId!),
                    if (_gdnMessage != null) _kv('Status', _gdnMessage!),
                    const SizedBox(height: 12),
                    GlPrimaryButton(
                      label: _gdnCreated ? 'View GDN form' : 'Open GDN form',
                      icon: _gdnCreated
                          ? Icons.lock_rounded
                          : Icons.description_outlined,
                      onPressed: () async {
                        await context.push(
                          '/consignor/shipment/${s.id}/gdn?assignment=$_assignmentId&goods=${Uri.encodeQueryComponent(s.goodsDescription)}',
                        );
                        if (_assignmentId != null) {
                          await _refreshGdnState(_assignmentId!);
                        }
                      },
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              _InfoCard(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        color: AppColors.primary.withValues(alpha: 0.85),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'GRN Control',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_resolvingAssignment)
                    const LinearProgressIndicator()
                  else if (_assignmentId == null)
                    const Text(
                      'GRN control becomes available after driver assignment is active.',
                    )
                  else if (!grnControlEnabled)
                    const Text(
                      'GRN can be created after the driver confirms offloaded status.',
                    )
                  else ...[
                    _kv('Assignment', _assignmentId!),
                    if (_grnMessage != null) _kv('Status', _grnMessage!),
                    const SizedBox(height: 12),
                    GlPrimaryButton(
                      label: _grnCreated ? 'View GRN form' : 'Open GRN form',
                      icon: _grnCreated
                          ? Icons.lock_rounded
                          : Icons.inventory_rounded,
                      onPressed: () async {
                        await context.push(
                          '/consignor/shipment/${s.id}/grn?assignment=$_assignmentId&status=$assignmentStatus',
                        );
                        if (_assignmentId != null) {
                          await _refreshGrnState(_assignmentId!);
                        }
                        ref.invalidate(consignorShipmentsProvider);
                        ref.invalidate(shipmentDetailProvider(s.id));
                      },
                    ),
                  ],
                ],
              ),
              if (_grnCreated && _assignmentId != null) ...[
                const SizedBox(height: 16),
                _InfoCard(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.task_alt_rounded,
                          color: AppColors.primary.withValues(alpha: 0.85),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Confirm handover',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_handoverConfirmed(assignmentStatus))
                      Text(
                        'Handover confirmed.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else ...[
                      Text(
                        'After GRN is recorded, confirm final receipt here.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GlPrimaryButton(
                        label: 'Confirm completed',
                        icon: Icons.task_alt_rounded,
                        onPressed: _confirmingHandover
                            ? null
                            : () => _confirmHandover(s.id),
                      ),
                    ],
                  ],
                ),
              ],
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This page shows your shipment details and current progress.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GlPrimaryButton(
                label: 'Open negotiation room',
                icon: Icons.forum_rounded,
                onPressed: () =>
                    context.push('/consignor/shipment/${s.id}/negotiation'),
              ),
              const SizedBox(height: 10),
              GlPrimaryButton(
                label: 'Open live tracking map',
                icon: Icons.map_outlined,
                onPressed: _assignmentId == null
                    ? null
                    : () => context.push(
                        '/consignor/track/${s.id}?assignment=$_assignmentId',
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, stackTrace) => Center(child: Text('$e')),
      ),
    );
  }

  ShipmentModel? _findShipment(List<ShipmentModel> shipments) {
    for (final s in shipments) {
      if (s.id == widget.shipmentId || s.publicId == widget.shipmentId) {
        return s;
      }
    }
    return null;
  }

  String _formatMetric(double value) {
    if (value == 0) return '—';
    if (value % 1 == 0) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }

  String _formatPrice(double value) {
    if (value % 1 == 0) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    final label = '${(clamped * 100).round()}%';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Progress',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: clamped,
              minHeight: 9,
              backgroundColor: AppColors.borderLight,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _kv(String k, String v) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            k,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(v, style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
      ],
    ),
  );
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({
    required this.loading,
    required this.offloading,
    required this.placed,
    required this.eta,
  });

  final String loading;
  final String offloading;
  final String placed;
  final String eta;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Route', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          _dotLine(Icons.trending_flat, 'Pickup', loading),
          const SizedBox(height: 10),
          _dotLine(Icons.flag, 'Delivery', offloading),
          const Divider(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Placed $placed',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text('Est. $eta', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dotLine(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(value),
            ],
          ),
        ),
      ],
    );
  }
}

/// Owns [TextEditingController] lifecycle so it is not disposed while the
/// dialog route is still tearing down (avoids framework assertion failures).
class _ConsignorConfirmRemarkDialog extends StatefulWidget {
  const _ConsignorConfirmRemarkDialog();

  @override
  State<_ConsignorConfirmRemarkDialog> createState() =>
      _ConsignorConfirmRemarkDialogState();
}

class _ConsignorConfirmRemarkDialogState
    extends State<_ConsignorConfirmRemarkDialog> {
  late final TextEditingController _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirm Assignment'),
      content: TextField(
        controller: _ctrl,
        maxLines: 3,
        decoration: const InputDecoration(
          labelText: 'Remark *',
          hintText: 'Add consignor confirmation remark',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final remark = _ctrl.text.trim();
            if (remark.isEmpty) {
              Navigator.of(context).pop('');
              return;
            }
            Navigator.of(context).pop(remark);
          },
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({
    required this.name,
    required this.vehicle,
    required this.plate,
    this.rating,
  });

  final String name;
  final String vehicle;
  final String plate;
  final double? rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Text(
              name.isNotEmpty ? name.substring(0, 1) : '?',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 22,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleSmall),
                Text(
                  '$vehicle · $plate',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (rating != null)
                  Text(
                    '${rating!.toStringAsFixed(1)} ★',
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: AppColors.gold),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
