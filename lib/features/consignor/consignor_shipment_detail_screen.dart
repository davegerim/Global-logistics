import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';
import 'package:global_logistics_app/core/providers/backend_api_provider.dart';
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
  String? _assignmentId;
  bool _resolvingAssignment = false;
  bool _gdnCreated = false;
  String? _gdnMessage;

  Future<void> _resolveAssignmentIfNeeded(ShipmentModel s) async {
    if (_resolvingAssignment || _assignmentId != null || !mounted) return;
    setState(() => _resolvingAssignment = true);
    try {
      final api = ref.read(backendApiProvider);
      final assignments = await api.assignmentsConsignorOfShipment(s.id);
      String? found;
      if (assignments.isNotEmpty && assignments.first is Map) {
        final row = (assignments.first as Map).cast<String, dynamic>();
        found =
            (row['assignmentId'] as String?) ??
            (row['publicId'] as String?) ??
            (row['id'] as String?);
      }
      if (!mounted) return;
      setState(() => _assignmentId = found);
      if (found != null) {
        await _refreshGdnState(found);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _resolvingAssignment = false);
    }
  }

  Future<void> _refreshGdnState(String assignmentId) async {
    try {
      final gdns = await ref.read(backendApiProvider).gdnOfAssignment(assignmentId);
      if (!mounted) return;
      setState(() {
        _gdnCreated = gdns.isNotEmpty;
        if (_gdnCreated) {
          _gdnMessage = 'GDN already generated and locked.';
        }
      });
    } catch (_) {}
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
            onPressed: () => ref.invalidate(consignorShipmentsProvider),
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
          _resolveAssignmentIfNeeded(s);
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
                      icon: _gdnCreated ? Icons.lock_rounded : Icons.description_outlined,
                      onPressed: () => context.push(
                        '/consignor/shipment/${s.id}/gdn?assignment=$_assignmentId&goods=${Uri.encodeQueryComponent(s.goodsDescription)}',
                      ),
                    ),
                  ],
                ],
              ),
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
                    : () => context.push('/consignor/track/${s.id}?assignment=$_assignmentId'),
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
