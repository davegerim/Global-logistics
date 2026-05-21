import 'package:global_logistics_app/core/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';
import 'package:global_logistics_app/core/errors/user_facing_error.dart';
import 'package:global_logistics_app/core/providers/backend_api_provider.dart';
import 'package:global_logistics_app/core/providers/consignor_active_provider.dart';
import 'package:global_logistics_app/core/providers/shipments_provider.dart';
import 'package:global_logistics_app/data/models/shipment_model.dart';
import 'package:global_logistics_app/data/storage/assignment_feedback_preferences.dart';
import 'package:global_logistics_app/features/consignor/widgets/consignor_shipment_payment_section.dart';
import 'package:global_logistics_app/shared/widgets/assignment_feedback_sheet.dart';
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

  /// After one completed resolution (success or failure), do not auto-retry until refresh.
  bool _assignmentResolutionAttempted = false;
  bool _resolveAssignmentScheduled = false;

  void _scheduleAssignmentResolutionIfNeeded(
    ShipmentModel s, {
    required bool eligible,
  }) {
    if (!eligible || !mounted) return;
    if (_assignmentId != null ||
        _assignmentResolutionAttempted ||
        _resolvingAssignment ||
        _resolveAssignmentScheduled) {
      return;
    }
    _resolveAssignmentScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        _resolveAssignmentScheduled = false;
        return;
      }
      _resolveAssignmentScheduled = false;
      _resolveAssignmentIfNeeded(s);
    });
  }

  Future<void> _resolveAssignmentIfNeeded(ShipmentModel s) async {
    if (_resolvingAssignment ||
        _assignmentId != null ||
        !mounted ||
        _assignmentResolutionAttempted) {
      return;
    }
    setState(() => _resolvingAssignment = true);
    try {
      final api = ref.read(backendApiProvider);
      final candidates = <String>{
        s.id,
        s.publicId,
        if (s.bookingId != null && s.bookingId!.trim().isNotEmpty)
          s.bookingId!.trim(),
      };
      List<dynamic> assignments = const [];
      for (final candidate in candidates) {
        assignments = await api.assignmentsConsignorOfShipment(candidate);
        if (assignments.isNotEmpty) break;
      }
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
      found ??= await _assignmentIdFromActiveShipment(s);
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
      if (mounted) {
        setState(() {
          _resolvingAssignment = false;
          _assignmentResolutionAttempted = true;
        });
      }
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
          _gdnMessage = context.l10n.gdnAlreadyGeneratedLocked;
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
          _grnMessage = context.l10n.grnAlreadyCreated;
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

  Future<String?> _assignmentIdFromActiveShipment(ShipmentModel s) async {
    try {
      final payload = await ref.read(consignorActiveProvider.future);
      final active = _findActiveShipment(payload, s);
      if (active == null) return null;
      final selectedDrivers = active['selectedDrivers'];
      if (selectedDrivers is! List) return null;
      for (final item in selectedDrivers) {
        if (item is! Map) continue;
        final row = item.cast<String, dynamic>();
        final assignmentId =
            row['assignmentId']?.toString().trim() ??
            row['publicId']?.toString().trim() ??
            row['id']?.toString().trim();
        if (assignmentId != null && assignmentId.isNotEmpty) {
          return assignmentId;
        }
      }
    } catch (_) {}
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
  bool _feedbackToDriverSubmitted = false;
  String? _feedbackLoadedForAid;
  bool _loadingFeedbackState = false;

  Future<String?> _promptConfirmRemark() async {
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => const _ConsignorConfirmRemarkDialog(),
    );
    if (value == null) return null;
    if (value.isEmpty) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.remarkRequiredToConfirm)),
      );
      return null;
    }
    return value;
  }

  @override
  void didUpdateWidget(covariant ConsignorShipmentDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shipmentId != widget.shipmentId) {
      _assignmentResolutionAttempted = false;
      _resolveAssignmentScheduled = false;
      _assignmentId = null;
      _assignmentApiStatus = null;
      _feedbackLoadedForAid = null;
      _feedbackToDriverSubmitted = false;
    }
  }

  Future<void> _loadFeedbackToDriverState(String assignmentId) async {
    if (_loadingFeedbackState || _feedbackLoadedForAid == assignmentId) {
      return;
    }
    _loadingFeedbackState = true;
    try {
      final submitted = await AssignmentFeedbackPreferences.instance
          .hasSubmittedToDriver(assignmentId);
      if (!mounted) return;
      setState(() {
        _feedbackToDriverSubmitted = submitted;
        _feedbackLoadedForAid = assignmentId;
      });
    } finally {
      _loadingFeedbackState = false;
    }
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
        SnackBar(content: Text(context.l10n.consignorConfirmationCompleted)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(userFacingMessage(e))));
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
      backgroundColor: AppColors.backgroundWarm,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWarm,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          context.l10n.shipmentTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              _selectionResolvedForShipment = null;
              _assignmentResolutionAttempted = false;
              _resolveAssignmentScheduled = false;
              ref.invalidate(consignorShipmentsProvider);
              ref.invalidate(consignorActiveProvider);
            },
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      body: async.when(
        data: (shipments) {
          final s = _findShipment(shipments);
          if (s == null) {
            return Center(child: Text(context.l10n.shipmentNotFound));
          }
          _resolveDriverSelectionIfNeeded(s);
          final assignedByStatus = _isAssignedOrLater(s.apiStatusLabel);
          _scheduleAssignmentResolutionIfNeeded(
            s,
            eligible: _driverSelected || assignedByStatus,
          );
          final assignmentStatus =
              (_assignmentApiStatus ?? s.apiStatusLabel ?? '')
                  .trim()
                  .toUpperCase();
          final gdnControlEnabled =
              _driverSelected || (assignedByStatus && _assignmentId != null);
          final grnControlEnabled =
              _assignmentId != null && _canOpenGrnControl(assignmentStatus);
          if (_assignmentId != null && _feedbackLoadedForAid != _assignmentId) {
            _loadFeedbackToDriverState(_assignmentId!);
          }
          final canSendFeedbackToDriver =
              _assignmentId != null &&
              assignmentAllowsFeedback(assignmentStatus) &&
              !_feedbackToDriverSubmitted;
          final fmt = DateFormat.yMMMd(context.l10n.localeName);
          return ListView(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.displayId,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  context.translateDynamic(s.goodsDescription),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          StatusChip(
                            status: s.status,
                            labelOverride: s.apiStatusLabel,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _InfoCard(
                        title: context.l10n.shipmentDetails,
                        icon: Icons.inventory_2_outlined,
                        children: [
                          _kv(context.l10n.weightLabelCap, _formatMetric(s.weightKg)),
                          _docDivider(),
                          _kv(context.l10n.volumeLabelCap, _formatMetric(s.volumeM3)),
                          _docDivider(),
                          _kv(context.l10n.vehicleLabelCap, context.translateDynamic(s.vehicleType)),
                          _docDivider(),
                          _kv(context.l10n.createdLabelCap, fmt.format(s.placedAt)),
                          if (s.paymentMethod != null) ...[
                            _docDivider(),
                            _kv(context.l10n.priceTypeLabelCap, context.translateDynamic(s.paymentMethod!)),
                          ],
                          if (s.priceOffer != null) ...[
                            _docDivider(),
                            _kv(context.l10n.priceLabelCap, _formatPrice(s.priceOffer!)),
                          ],
                        ],
                      ),
                    ],
                  ),
                  Positioned(
                    right: -10,
                    top: 15,
                    child: IgnorePointer(
                      child: Hero(
                        tag: 'shipment_vehicle_${s.id}',
                        child: Image.asset(
                          'assets/images/huge_truck.png',
                          height: 110,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
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
                _InfoCard(
                  title: context.l10n.notes,
                  icon: Icons.note_alt_outlined,
                  children: [
                    Text(
                      s.timelineNote.trim(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ],
              if (s.driver != null) ...[
                const SizedBox(height: 16),
                _InfoCard(
                  title: context.l10n.driverDetails,
                  icon: Icons.person_pin_circle_outlined,
                  children: [
                    _DriverCard(
                      name: s.driver!.name,
                      vehicle: s.driver!.vehicleLabel ?? '—',
                      plate: s.driver!.plate ?? '—',
                      rating: s.driver!.rating,
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              ConsignorShipmentPaymentSection(
                shipmentId: s.id,
                enabled: _driverSelected || assignedByStatus,
              ),
              const SizedBox(height: 16),
              _InfoCard(
                title: context.l10n.gdnControl,
                icon: Icons.assignment_turned_in_outlined,
                children: [
                  if (_resolvingAssignment)
                    const LinearProgressIndicator()
                  else if (_resolvingDriverSelection)
                    const LinearProgressIndicator()
                  else if (!gdnControlEnabled)
                    Text(
                      context.l10n.gdnControlOnceAdminSelects,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    )
                  else if (_assignmentId == null)
                    Text(
                      context.l10n.waitingForDriverAssignment,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    )
                  else ...[
                    _kv(context.l10n.assignmentLabelCap, _assignmentId!),
                    _docDivider(),
                    if (_gdnMessage != null) ...[
                      _kv(context.l10n.statusLabelCap, _gdnMessage!),
                      const SizedBox(height: 12),
                    ],
                    GlPrimaryButton(
                      label: _gdnCreated ? context.l10n.viewGdnForm : context.l10n.openGdnForm,
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
                title: context.l10n.grnControl,
                icon: Icons.inventory_rounded,
                children: [
                  if (_resolvingAssignment)
                    const LinearProgressIndicator()
                  else if (_assignmentId == null)
                    Text(
                      context.l10n.grnControlAfterDriverAssignment,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    )
                  else if (!grnControlEnabled)
                    Text(
                      context.l10n.grnCreatedAfterOffload,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    )
                  else ...[
                    _kv(context.l10n.assignmentLabelCap, _assignmentId!),
                    _docDivider(),
                    if (_grnMessage != null) ...[
                      _kv(context.l10n.statusLabelCap, _grnMessage!),
                      const SizedBox(height: 12),
                    ],
                    GlPrimaryButton(
                      label: _grnCreated ? context.l10n.viewGrnForm : context.l10n.openGrnForm,
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
                  title: context.l10n.confirmHandover,
                  icon: Icons.task_alt_rounded,
                  children: [
                    if (_handoverConfirmed(assignmentStatus))
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.verified_rounded,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              context.l10n.handoverConfirmed,
                              style: const TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      Text(
                        context.l10n.afterGrnRecordedConfirm,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GlPrimaryButton(
                        label: context.l10n.confirmCompleted,
                        icon: Icons.task_alt_rounded,
                        onPressed: _confirmingHandover
                            ? null
                            : () => _confirmHandover(s.id),
                        useGoldAccent: true,
                      ),
                    ],
                  ],
                ),
              ],
              if (canSendFeedbackToDriver) ...[
                const SizedBox(height: 16),
                _InfoCard(
                  title: context.l10n.feedbackToDriver,
                  icon: Icons.chat_rounded,
                  children: [
                    Text(
                      context.l10n.shareDeliveryNotesOrRate,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GlPrimaryButton(
                      label: context.l10n.sendFeedback,
                      icon: Icons.star_rounded,
                      onPressed: () async {
                        final aid = _assignmentId!;
                        final messenger = ScaffoldMessenger.of(context);
                        final sentLabel = context.l10n.feedbackSent;
                        final result = await showAssignmentFeedbackSheet(
                          context,
                          title: context.l10n.feedbackToDriver,
                          subtitle:
                              'Your rating and comments help maintain '
                              'service quality.',
                          hint:
                              'Describe professionalism, timing, '
                              'vehicle condition, or appreciation...',
                        );
                        if (!mounted || result == null) return;
                        try {
                          await ref.read(backendApiProvider).feedbackToDriver({
                            'assignmentId': aid,
                            'comment': result.comment,
                            'rating': result.rating,
                          });
                          await AssignmentFeedbackPreferences.instance
                              .markSubmittedToDriver(aid);
                          if (!mounted) return;
                          setState(() => _feedbackToDriverSubmitted = true);
                          messenger.showSnackBar(
                            SnackBar(content: Text(sentLabel)),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          messenger.showSnackBar(
                            SnackBar(content: Text(userFacingMessage(e))),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GlPrimaryButton(
                      label: context.l10n.negotiationRoom,
                      icon: Icons.forum_rounded,
                      onPressed: () => context.push(
                        '/consignor/shipment/${s.id}/negotiation',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GlPrimaryButton(
                      label: context.l10n.liveTrackingMap,
                      icon: Icons.map_outlined,
                      useGoldAccent: true,
                      onPressed: _assignmentId == null
                          ? null
                          : () => context.push(
                              '/consignor/track/${s.id}?assignment=$_assignmentId',
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, stackTrace) => Center(child: Text(userFacingMessage(e))),
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

Widget _kv(String k, String v) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            k,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            v,
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
  return const Divider(color: AppColors.borderLight, height: 1, thickness: 1);
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children, this.title, this.icon});

  final List<Widget> children;
  final String? title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderLight, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null && icon != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    title!,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(
              height: 1,
              color: AppColors.borderLight,
              thickness: 1.5,
            ),
          ],
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderLight, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.alt_route_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  context.l10n.routeMap,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          const Divider(
            height: 1,
            color: AppColors.borderLight,
            thickness: 1.5,
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dotLine(
                  Icons.upload_rounded,
                  context.l10n.pickupLocationLabel,
                  context.translateDynamic(loading),
                  isStart: true,
                ),
                Container(
                  margin: const EdgeInsets.only(left: 17),
                  height: 24,
                  width: 2,
                  color: AppColors.borderLight,
                ),
                _dotLine(
                  Icons.flag_rounded,
                  context.l10n.deliveryDestinationLabel,
                  context.translateDynamic(offloading),
                  isStart: false,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHighlight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.placedOnLabel,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textTertiary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              placed,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: AppColors.borderLight,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              context.l10n.estArrivalLabel,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textTertiary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              eta,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dotLine(
    IconData icon,
    String label,
    String value, {
    required bool isStart,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isStart
                ? AppColors.surfaceMuted
                : AppColors.success.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 20,
            color: isStart ? AppColors.textSecondary : AppColors.success,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
              ),
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
      title: Text(context.l10n.confirmAssignment),
      content: TextField(
        controller: _ctrl,
        maxLines: 3,
        decoration: InputDecoration(
          labelText: 'Remark *',
          hintText: context.l10n.addConsignorConfirmationRemark,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.cancel),
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
          child: Text(context.l10n.confirm),
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
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.primarySoft,
          child: Text(
            name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      vehicle,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    plate,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (rating != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, color: AppColors.gold, size: 16),
                const SizedBox(width: 4),
                Text(
                  rating!.toStringAsFixed(1),
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
