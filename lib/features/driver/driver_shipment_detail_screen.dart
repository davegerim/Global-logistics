import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';
import 'package:global_logistics_app/core/providers/backend_api_provider.dart';
import 'package:global_logistics_app/core/providers/shipments_provider.dart';
import 'package:global_logistics_app/shared/widgets/gl_primary_button.dart';
import 'package:global_logistics_app/shared/widgets/status_chip.dart';

/// Driver assignment actions: `PUT /assignments/*` and `POST /tracking`.
class DriverShipmentDetailScreen extends ConsumerStatefulWidget {
  const DriverShipmentDetailScreen({super.key, required this.shipmentId});

  final String shipmentId;

  @override
  ConsumerState<DriverShipmentDetailScreen> createState() =>
      _DriverShipmentDetailScreenState();
}

class _DriverShipmentDetailScreenState
    extends ConsumerState<DriverShipmentDetailScreen> {
  bool _checkingGdn = false;
  bool _hasGdn = false;
  String? _gdnInfo;

  Future<String?> _prompt(BuildContext context, String title, String hint) {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: c,
          maxLines: 3,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> _putStatus(
    BuildContext context,
    WidgetRef ref,
    String assignmentId,
    Future<void> Function() call,
    String label,
  ) async {
    try {
      await call();
      ref.invalidate(shipmentDetailProvider(widget.shipmentId));
      ref.invalidate(driverAssignedShipmentsProvider);
      if (context.mounted) {
        await _refreshGdnState(assignmentId);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label — OK')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _refreshGdnState(String assignmentId) async {
    if (_checkingGdn) return;
    setState(() => _checkingGdn = true);
    try {
      final gdns = await ref.read(backendApiProvider).gdnOfAssignment(assignmentId);
      if (!mounted) return;
      setState(() {
        _hasGdn = gdns.isNotEmpty;
        _gdnInfo = _hasGdn ? 'GDN is ready' : 'Waiting for consignor to create GDN';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _gdnInfo = 'Unable to verify GDN right now. Please refresh.');
    } finally {
      if (mounted) setState(() => _checkingGdn = false);
    }
  }

  bool _canLoaded(String? apiStatus) =>
      _hasGdn && (apiStatus == 'DRIVER_ASSIGNED' || apiStatus == 'GDN_GENERATED');

  bool _canTransit(String? apiStatus) => apiStatus == 'LOADED';

  bool _canArrived(String? apiStatus) => apiStatus == 'IN_TRANSIT';

  bool _canOffloaded(String? apiStatus) => apiStatus == 'ARRIVED';

  int _currentStepIndex(String status) {
    switch (status) {
      case 'LOADED':
        return 1;
      case 'IN_TRANSIT':
        return 2;
      case 'ARRIVED':
        return 3;
      case 'OFFLOADED':
      case 'GRN_GENERATED':
      case 'CONSIGNOR_RECEIVED':
        return 4;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(shipmentDetailProvider(widget.shipmentId));
    final api = ref.read(backendApiProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Assignment'),
      ),
      body: async.when(
        data: (s) {
          if (s == null) {
            return const Center(child: Text('Not found'));
          }
          final aid = s.assignmentId;
          if (aid != null && !_checkingGdn && _gdnInfo == null) {
            _refreshGdnState(aid);
          }
          final status = (s.apiStatusLabel ?? '').trim().toUpperCase();
          final currentStep = _currentStepIndex(status);
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(s.publicId, style: Theme.of(context).textTheme.headlineSmall),
                  ),
                  StatusChip(
                    status: s.status,
                    labelOverride: s.apiStatusLabel,
                  ),
                ],
              ),
              if (aid != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('assignmentId: $aid', style: Theme.of(context).textTheme.bodySmall),
                ),
              const SizedBox(height: 12),
              Text(s.goodsDescription, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 20),
              _block('Pickup', s.loadingAddress, Icons.north_east),
              const SizedBox(height: 12),
              _block('Drop-off', s.offloadingAddress, Icons.south_west),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0E4A42), Color(0xFF0A5C52)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.18),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shipment progress',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _StepTracker(
                      steps: const [
                        _StepMeta('Assigned', Icons.assignment_ind_rounded),
                        _StepMeta('Loaded', Icons.inventory_2_rounded),
                        _StepMeta('Transit', Icons.local_shipping_rounded),
                        _StepMeta('Arrived', Icons.flag_rounded),
                        _StepMeta('Offloaded', Icons.unarchive_rounded),
                      ],
                      currentIndex: currentStep,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text('Assignment actions', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 10),
              if (aid == null)
                const Text('Assignment id missing — open again after assignment is created.')
              else ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _hasGdn
                        ? AppColors.success.withValues(alpha: 0.08)
                        : AppColors.warning.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _hasGdn ? Icons.verified_rounded : Icons.pending_actions_rounded,
                        color: _hasGdn ? AppColors.success : AppColors.warning,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _checkingGdn ? 'Checking GDN...' : (_gdnInfo ?? 'Checking GDN...'),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _ActionTile(
                  title: 'Confirm loaded',
                  subtitle: 'Confirm cargo has been loaded.',
                  icon: Icons.inventory_2_rounded,
                  enabled: _canLoaded(status),
                  onTap: () => _putStatus(
                    context,
                    ref,
                    aid,
                    () => api.assignmentsConfirmLoaded({'assignmentId': aid}),
                    'Loaded confirmed',
                  ),
                ),
                const SizedBox(height: 8),
                _ActionTile(
                  title: 'Confirm in transit',
                  subtitle: 'Start route tracking to destination.',
                  icon: Icons.local_shipping_rounded,
                  enabled: _canTransit(status),
                  onTap: () => _putStatus(
                    context,
                    ref,
                    aid,
                    () => api.assignmentsConfirmInTransit({'assignmentId': aid}),
                    'In transit confirmed',
                  ),
                ),
                const SizedBox(height: 8),
                _ActionTile(
                  title: 'Confirm arrived',
                  subtitle: 'Mark when vehicle reaches destination.',
                  icon: Icons.flag_rounded,
                  enabled: _canArrived(status),
                  onTap: () => _putStatus(
                    context,
                    ref,
                    aid,
                    () => api.assignmentsConfirmArrived({'assignmentId': aid}),
                    'Arrival confirmed',
                  ),
                ),
                const SizedBox(height: 8),
                _ActionTile(
                  title: 'Confirm offloaded',
                  subtitle: 'Finish unloading and complete handover.',
                  icon: Icons.unarchive_rounded,
                  enabled: _canOffloaded(status),
                  onTap: () => _putStatus(
                    context,
                    ref,
                    aid,
                    () => api.assignmentsConfirmOffloaded({'assignmentId': aid}),
                    'Offload confirmed',
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () async {
                    final remark = await _prompt(context, 'Cancel assignment', 'Reason (optional)');
                    if (!context.mounted) return;
                    await _putStatus(
                      context,
                      ref,
                      aid,
                      () => api.assignmentsCancel({
                        'assignmentId': aid,
                        if (remark != null && remark.isNotEmpty) 'remark': remark,
                      }),
                      'Assignment cancelled',
                    );
                  },
                  child: const Text('Cancel assignment'),
                ),
                const SizedBox(height: 20),
                GlPrimaryButton(
                  label: 'Record GPS',
                  onPressed: () async {
                    try {
                      await api.trackingRecord({
                        'assignmentId': aid,
                        'latitude': 9.03,
                        'longitude': 38.75,
                        'accuracy': 12.0,
                        'speed': 0.0,
                        'recordedAt': DateTime.now().toUtc().toIso8601String(),
                      });
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('GPS location recorded.')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                      }
                    }
                  },
                ),
              ],
              const SizedBox(height: 16),
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: () async {
                  if (aid == null) return;
                  final comment = await _prompt(context, 'Feedback to consignor', 'Comment *');
                  if (!context.mounted || comment == null || comment.isEmpty) return;
                  try {
                    await api.feedbackToConsignor({
                      'assignmentId': aid,
                      'comment': comment,
                      'rating': 4,
                    });
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Feedback sent.')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                    }
                  }
                },
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Feedback to consignor'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }

  Widget _block(String title, String body, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepMeta {
  const _StepMeta(this.label, this.icon);
  final String label;
  final IconData icon;
}

class _StepTracker extends StatelessWidget {
  const _StepTracker({required this.steps, required this.currentIndex});

  final List<_StepMeta> steps;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(steps.length, (i) {
        final active = i <= currentIndex;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: active
                          ? AppColors.gold
                          : Colors.white.withValues(alpha: 0.22),
                      child: Icon(
                        steps[i].icon,
                        size: 16,
                        color: active ? AppColors.primaryDark : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      steps[i].label,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (i < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 20),
                    color: i < currentIndex
                        ? AppColors.gold
                        : Colors.white.withValues(alpha: 0.22),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: enabled ? AppColors.surface : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: enabled
                  ? AppColors.primary.withValues(alpha: 0.14)
                  : AppColors.textTertiary.withValues(alpha: 0.14),
              child: Icon(
                icon,
                color: enabled ? AppColors.primary : AppColors.textTertiary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(
              enabled ? Icons.arrow_forward_ios_rounded : Icons.lock_outline_rounded,
              size: 16,
              color: enabled ? AppColors.primary : AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
