import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';
import 'package:global_logistics_app/core/providers/backend_api_provider.dart';
import 'package:global_logistics_app/core/providers/repository_provider.dart';
import 'package:global_logistics_app/core/providers/shipments_provider.dart';
import 'package:global_logistics_app/core/services/device_location_service.dart';
import 'package:global_logistics_app/data/models/shipment_model.dart';
import 'package:global_logistics_app/shared/widgets/status_chip.dart';
import 'package:intl/intl.dart';

/// Driver assignment actions: `PUT /assignments/*` and `POST /tracking`.
class DriverShipmentDetailScreen extends ConsumerStatefulWidget {
  const DriverShipmentDetailScreen({super.key, required this.shipmentId});

  final String shipmentId;

  @override
  ConsumerState<DriverShipmentDetailScreen> createState() =>
      _DriverShipmentDetailScreenState();
}

class _DriverShipmentDetailScreenState
    extends ConsumerState<DriverShipmentDetailScreen>
    with WidgetsBindingObserver {
  static const Duration _trackingInterval = Duration(minutes: 15);

  bool _checkingGdn = false;
  bool _hasGdn = false;
  String? _gdnInfo;
  List<DocumentRef>? _assignmentDocuments;
  String? _documentsLoadedForAid;
  bool _loadingDocuments = false;
  Timer? _trackingTimer;
  String? _trackedAssignmentId;
  bool _trackingInFlight = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _trackingTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _trackingTimer?.cancel();
      _trackingTimer = null;
      return;
    }
    if (state == AppLifecycleState.resumed && _trackedAssignmentId != null) {
      _startTrackingLoop(_trackedAssignmentId!);
    }
  }

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
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, c.text.trim()),
            child: const Text('OK'),
          ),
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
      await _recordTracking(
        assignmentId,
        reason: 'status:$label',
        throwOnFailure: false,
      );
      ref.invalidate(shipmentDetailProvider(widget.shipmentId));
      ref.invalidate(driverAssignedShipmentsProvider);
      if (context.mounted) {
        await _refreshGdnState(assignmentId);
      }
      if (context.mounted) {
        await _refreshAssignmentDocuments(assignmentId, force: true);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$label — OK')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  void _startTrackingLoop(String assignmentId) {
    if (_trackedAssignmentId != assignmentId || _trackingTimer == null) {
      _trackingTimer?.cancel();
      _trackedAssignmentId = assignmentId;
      _trackingTimer = Timer.periodic(_trackingInterval, (_) {
        _recordTracking(
          assignmentId,
          reason: 'periodic-15m',
          throwOnFailure: false,
        );
      });
      _recordTracking(
        assignmentId,
        reason: 'tracking-loop-start',
        throwOnFailure: false,
      );
    }
  }

  void _stopTrackingLoop() {
    _trackingTimer?.cancel();
    _trackingTimer = null;
    _trackedAssignmentId = null;
  }

  Future<void> _recordTracking(
    String assignmentId, {
    required String reason,
    required bool throwOnFailure,
  }) async {
    if (_trackingInFlight) return;
    _trackingInFlight = true;
    try {
      final location = await DeviceLocationService.current();
      final recordedAt = DateTime.fromMillisecondsSinceEpoch(
        DateTime.now().toUtc().millisecondsSinceEpoch,
        isUtc: true,
      ).toIso8601String();
      await ref.read(backendApiProvider).trackingRecord({
        'assignmentId': assignmentId,
        'latitude': location.latitude,
        'longitude': location.longitude,
        'accuracy': location.accuracy,
        'speed': location.speed,
        'recordedAt': recordedAt,
      });
      // Tag app-level tracking events; full payload/response is already logged by GL_API interceptor.
      debugPrint('[TRACKING] sent ($reason) for assignment=$assignmentId');
    } catch (e) {
      debugPrint('[TRACKING] failed ($reason): $e');
      if (throwOnFailure) rethrow;
    } finally {
      _trackingInFlight = false;
    }
  }

  Future<void> _refreshGdnState(String assignmentId) async {
    if (_checkingGdn) return;
    setState(() => _checkingGdn = true);
    try {
      final gdns = await ref
          .read(backendApiProvider)
          .gdnOfAssignment(assignmentId);
      if (!mounted) return;
      setState(() {
        _hasGdn = gdns.isNotEmpty;
        _gdnInfo = _hasGdn
            ? 'GDN is ready'
            : 'Waiting for consignor to create GDN';
      });
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _gdnInfo = 'Unable to verify GDN right now. Please refresh.',
      );
    } finally {
      if (mounted) setState(() => _checkingGdn = false);
    }
  }

  Future<void> _refreshAssignmentDocuments(
    String assignmentId, {
    bool force = false,
  }) async {
    if (_loadingDocuments && !force) return;
    setState(() => _loadingDocuments = true);
    try {
      final docs = await ref
          .read(logisticsRepositoryProvider)
          .fetchDocumentsForAssignment(assignmentId);
      if (!mounted) return;
      setState(() {
        _assignmentDocuments = docs;
        _documentsLoadedForAid = assignmentId;
        _loadingDocuments = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingDocuments = false);
    }
  }

  bool _canLoaded(String? apiStatus) =>
      _hasGdn &&
      (apiStatus == 'DRIVER_ASSIGNED' || apiStatus == 'GDN_GENERATED');

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
    final fmt = DateFormat.yMMMd();

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
          final status = (s.apiStatusLabel ?? '').trim().toUpperCase();
          final shouldTrackInBackground =
              status == 'IN_TRANSIT' || status == 'ARRIVED';
          if (aid == null) {
            _stopTrackingLoop();
          } else if (!_checkingGdn && _gdnInfo == null) {
            _refreshGdnState(aid);
            if (shouldTrackInBackground) {
              _startTrackingLoop(aid);
            } else {
              _stopTrackingLoop();
            }
          } else {
            if (shouldTrackInBackground) {
              _startTrackingLoop(aid);
            } else {
              _stopTrackingLoop();
            }
          }
          if (aid != null &&
              _documentsLoadedForAid != aid &&
              !_loadingDocuments) {
            _refreshAssignmentDocuments(aid);
          }
          final currentStep = _currentStepIndex(status);
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      s.publicId,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  StatusChip(status: s.status, labelOverride: s.apiStatusLabel),
                ],
              ),
              if (aid != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'assignmentId: $aid',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                s.goodsDescription,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              _block('Pickup', s.loadingAddress, Icons.north_east),
              const SizedBox(height: 12),
              _block('Drop-off', s.offloadingAddress, Icons.south_west),
              const SizedBox(height: 20),
              if (aid != null)
                _DriverGdnGrnSection(
                  loading: _loadingDocuments,
                  documents: _assignmentDocuments,
                  dateFmt: fmt,
                  onOpenDetail: (d) =>
                      _showDriverDocumentSheet(context, d, fmt),
                ),
              if (aid != null) const SizedBox(height: 20),
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
              Text(
                'Assignment actions',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 10),
              if (aid == null)
                const Text(
                  'Assignment id missing — open again after assignment is created.',
                )
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
                        _hasGdn
                            ? Icons.verified_rounded
                            : Icons.pending_actions_rounded,
                        color: _hasGdn ? AppColors.success : AppColors.warning,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _checkingGdn
                              ? 'Checking GDN...'
                              : (_gdnInfo ?? 'Checking GDN...'),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600),
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
                    () =>
                        api.assignmentsConfirmInTransit({'assignmentId': aid}),
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
                    () =>
                        api.assignmentsConfirmOffloaded({'assignmentId': aid}),
                    'Offload confirmed',
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () async {
                    final remark = await _prompt(
                      context,
                      'Cancel assignment',
                      'Reason (optional)',
                    );
                    if (!context.mounted) return;
                    await _putStatus(
                      context,
                      ref,
                      aid,
                      () => api.assignmentsCancel({
                        'assignmentId': aid,
                        if (remark != null && remark.isNotEmpty)
                          'remark': remark,
                      }),
                      'Assignment cancelled',
                    );
                  },
                  child: const Text('Cancel assignment'),
                ),
              ],
              const SizedBox(height: 16),
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: () async {
                  if (aid == null) return;
                  final comment = await _prompt(
                    context,
                    'Feedback to consignor',
                    'Comment *',
                  );
                  if (!context.mounted || comment == null || comment.isEmpty) {
                    return;
                  }
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
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('$e')));
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

  Future<void> _showDriverDocumentSheet(
    BuildContext context,
    DocumentRef d,
    DateFormat fmt,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          decoration: const BoxDecoration(
            color: AppColors.backgroundWarm,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.06),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    d.title.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                      color: AppColors.primaryDark,
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
                                  ),
                                  child: Text(
                                    (d.status ?? 'ISSUED').toUpperCase(),
                                    style: const TextStyle(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 10,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            _docField('DOCUMENT TYPE', d.type),
                            _docDivider(),
                            _docField('DOCUMENT NUMBER', d.documentNumber ?? 'N/A'),
                            _docDivider(),
                            _docField('DATE OF ISSUE', fmt.format(d.availableAt)),
                            _docDivider(),
                            _docField('REFERENCE ID', d.id),
                            if ((d.qrCodeValue ?? '').isNotEmpty) ...[
                              _docDivider(),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceHighlight,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.borderLight),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppColors.borderLight),
                                      ),
                                      child: const Icon(Icons.qr_code_2_rounded, size: 32, color: AppColors.textPrimary),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'VERIFICATION LINK',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.textTertiary,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            d.qrCodeValue!,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => Navigator.of(ctx).pop(),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Done', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _docField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.textTertiary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _docDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Divider(
        color: AppColors.borderLight,
        height: 1,
        thickness: 1,
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

/// Gradient-framed section aligned with consignor Documents hub; lists GDN/GRN for this assignment.
class _DriverGdnGrnSection extends StatelessWidget {
  const _DriverGdnGrnSection({
    required this.loading,
    required this.documents,
    required this.dateFmt,
    required this.onOpenDetail,
  });

  final bool loading;
  final List<DocumentRef>? documents;
  final DateFormat dateFmt;
  final void Function(DocumentRef d) onOpenDetail;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF0E4A42), Color(0xFF135C52)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.folder_special_outlined,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GDN & GRN',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Documents issued for this assignment',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.88),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: Material(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: loading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: LinearProgressIndicator()),
                      )
                    : _buildInner(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInner(BuildContext context) {
    final docs = documents ?? [];
    if (docs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.folder_open_outlined,
              color: AppColors.textTertiary.withValues(alpha: 0.9),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No GDN or GRN yet. They appear when the consignor creates them.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      );
    }
    final gdn = docs.where((d) => d.type == 'GDN').toList();
    final grn = docs.where((d) => d.type == 'GRN').toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (gdn.isNotEmpty) ...[
          _DriverDocTypeHeader(label: 'Goods Delivery Note', count: gdn.length),
          ...gdn.map(
            (d) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _DriverDocTile(
                doc: d,
                dateFmt: dateFmt,
                onTap: () => onOpenDetail(d),
              ),
            ),
          ),
        ],
        if (grn.isNotEmpty) ...[
          if (gdn.isNotEmpty) const SizedBox(height: 4),
          _DriverDocTypeHeader(label: 'Goods Received Note', count: grn.length),
          ...grn.map(
            (d) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _DriverDocTile(
                doc: d,
                dateFmt: dateFmt,
                onTap: () => onOpenDetail(d),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _DriverDocTypeHeader extends StatelessWidget {
  const _DriverDocTypeHeader({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        '$label ($count)',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _DriverDocTile extends StatelessWidget {
  const _DriverDocTile({
    required this.doc,
    required this.dateFmt,
    required this.onTap,
  });

  final DocumentRef doc;
  final DateFormat dateFmt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isGdn = doc.type == 'GDN';
    return Material(
      color: AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isGdn
                      ? AppColors.gold.withValues(alpha: 0.18)
                      : AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isGdn ? Icons.outbox_rounded : Icons.inbox_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.title,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${doc.type} • ${dateFmt.format(doc.availableAt)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if ((doc.documentNumber ?? '').isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'No: ${doc.documentNumber}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textTertiary,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.visibility_outlined,
                color: AppColors.primary,
                size: 22,
              ),
            ],
          ),
        ),
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
                      color: enabled
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Icon(
              enabled
                  ? Icons.arrow_forward_ios_rounded
                  : Icons.lock_outline_rounded,
              size: 16,
              color: enabled ? AppColors.primary : AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
