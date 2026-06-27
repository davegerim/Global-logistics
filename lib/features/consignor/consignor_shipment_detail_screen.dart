import 'package:global_logistics_app/core/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';
import 'package:global_logistics_app/core/errors/user_facing_error.dart';
import 'package:global_logistics_app/core/providers/backend_api_provider.dart';
import 'package:global_logistics_app/core/providers/consignor_active_provider.dart';
import 'package:global_logistics_app/core/providers/payments_provider.dart';
import 'package:global_logistics_app/core/providers/shipments_provider.dart';
import 'package:global_logistics_app/core/utils/assignment_display.dart';
import 'package:global_logistics_app/core/utils/gdn_grn_utils.dart';
import 'package:global_logistics_app/data/models/shipment_model.dart';
import 'package:global_logistics_app/data/storage/assignment_feedback_preferences.dart';
import 'package:global_logistics_app/features/consignor/widgets/consignor_shipment_payment_section.dart';
import 'package:global_logistics_app/features/documents/gdn_grn_document_view_model.dart';
import 'package:global_logistics_app/shared/widgets/assignment_feedback_sheet.dart';
import 'package:global_logistics_app/shared/widgets/gl_primary_button.dart';
import 'package:global_logistics_app/shared/widgets/status_chip.dart';
import 'package:intl/intl.dart';

class ConsignorShipmentDetailScreen extends ConsumerStatefulWidget {
  const ConsignorShipmentDetailScreen({
    super.key,
    required this.shipmentId,
    this.initialAssignmentId,
  });

  final String shipmentId;
  final String? initialAssignmentId;

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

  static const Set<String> _gdnGeneratedOrLaterStatuses = {
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
  String? _assignmentDriverName;
  String? _assignmentDriverPhone;
  String? _assignmentDriverPlate;
  List<_AssignmentOption> _assignments = const [];
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
  bool _resolvingShipmentFromAssignment = false;
  String? _shipmentIdFromAssignment;
  bool _shipmentFromAssignmentResolveScheduled = false;
  bool _detailSideEffectsScheduled = false;
  int _paymentRefreshSignal = 0;

  String? _normalizedInitialAssignmentId() {
    final raw = widget.initialAssignmentId?.trim();
    if (raw == null || raw.isEmpty) return null;
    return raw;
  }

  bool _isRouteAssignmentLocked() {
    final initial = _normalizedInitialAssignmentId();
    if (initial == null) return false;
    final selected = _assignmentId?.trim();
    if (selected == null || selected.isEmpty) return false;
    return selected == initial;
  }

  List<_AssignmentOption> _assignmentOptionsFromApi(List<dynamic> rows) {
    final out = <_AssignmentOption>[];
    for (final item in rows) {
      if (item is! Map) continue;
      final row = item.cast<String, dynamic>();
      final assignmentId =
          row['assignmentId']?.toString().trim().isNotEmpty == true
          ? row['assignmentId']!.toString().trim()
          : row['publicId']?.toString().trim().isNotEmpty == true
          ? row['publicId']!.toString().trim()
          : row['id']?.toString().trim();
      if (assignmentId == null || assignmentId.isEmpty) continue;
      final rawStatus =
          row['status']?.toString() ??
          row['assignmentStatus']?.toString() ??
          row['currentStatus']?.toString() ??
          '';
      final status = rawStatus.trim().toUpperCase();
      out.add(
        _AssignmentOption(
          assignmentId: assignmentId,
          status: status,
          sequenceNumber: out.length + 1,
        ),
      );
    }
    return out;
  }

  Future<void> _selectAssignment(String assignmentId, {String? status}) async {
    if (!mounted) return;
    setState(() {
      _assignmentId = assignmentId;
      _assignmentApiStatus = status;
      _gdnCreated = false;
      _grnCreated = false;
      _gdnMessage = null;
      _grnMessage = null;
      _assignmentDriverName = null;
      _assignmentDriverPhone = null;
      _assignmentDriverPlate = null;
      _feedbackLoadedForAid = null;
      _feedbackToDriverSubmitted = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadFeedbackToDriverState(assignmentId);
    });
    await _refreshGdnState(assignmentId);
    await _refreshGrnState(assignmentId);
  }

  Future<void> _resolveShipmentFromAssignmentIfNeeded() async {
    final assignmentId = _normalizedInitialAssignmentId();
    if (assignmentId == null || _resolvingShipmentFromAssignment) return;
    if (_shipmentIdFromAssignment != null) return;
    setState(() => _resolvingShipmentFromAssignment = true);
    try {
      final payload = await ref.read(consignorActiveProvider.future);
      if (payload is! List) return;
      for (final item in payload) {
        if (item is! Map) continue;
        final shipment = item.cast<String, dynamic>();
        final selectedDrivers = shipment['selectedDrivers'];
        if (selectedDrivers is! List) continue;
        for (final raw in selectedDrivers) {
          if (raw is! Map) continue;
          final row = raw.cast<String, dynamic>();
          final candidate =
              row['assignmentId']?.toString().trim().isNotEmpty == true
              ? row['assignmentId']!.toString().trim()
              : row['publicId']?.toString().trim().isNotEmpty == true
              ? row['publicId']!.toString().trim()
              : row['id']?.toString().trim();
          if (candidate == assignmentId) {
            final shipmentId = shipment['publicId']?.toString().trim();
            if (shipmentId != null && shipmentId.isNotEmpty && mounted) {
              setState(() => _shipmentIdFromAssignment = shipmentId);
            }
            return;
          }
        }
      }
    } finally {
      if (mounted) {
        setState(() => _resolvingShipmentFromAssignment = false);
      }
    }
  }

  void _scheduleShipmentFromAssignmentResolve() {
    if (_shipmentFromAssignmentResolveScheduled ||
        _shipmentIdFromAssignment != null ||
        _resolvingShipmentFromAssignment) {
      return;
    }
    _shipmentFromAssignmentResolveScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _shipmentFromAssignmentResolveScheduled = false;
      if (!mounted) return;
      _resolveShipmentFromAssignmentIfNeeded();
    });
  }

  void _scheduleDetailSideEffects(
    ShipmentModel s, {
    required bool assignmentEligible,
  }) {
    if (!mounted || _detailSideEffectsScheduled) return;
    _detailSideEffectsScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _detailSideEffectsScheduled = false;
      if (!mounted) return;
      _resolveDriverSelectionIfNeeded(s);
      _scheduleAssignmentResolutionIfNeeded(s, eligible: assignmentEligible);
    });
  }

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
      final shipmentPublicId = s.publicId.trim().isNotEmpty
          ? s.publicId.trim()
          : s.id.trim();
      List<dynamic> assignments = const [];
      if (shipmentPublicId.isNotEmpty) {
        assignments = await api.assignmentsConsignorOfShipment(
          shipmentPublicId,
        );
      }
      final options = _assignmentOptionsFromApi(assignments);
      String? found;
      String? resolvedAssignmentStatus;
      if (options.isNotEmpty) {
        final preferred = _normalizedInitialAssignmentId();
        _AssignmentOption selected = options.first;
        if (_assignmentId != null) {
          for (final option in options) {
            if (option.assignmentId == _assignmentId) {
              selected = option;
              break;
            }
          }
        } else if (preferred != null) {
          for (final option in options) {
            if (option.assignmentId == preferred) {
              selected = option;
              break;
            }
          }
        }
        found = selected.assignmentId;
        resolvedAssignmentStatus = selected.status;
      } else {
        found = await _assignmentIdFromActiveShipment(s);
      }
      if (!mounted) return;
      setState(() {
        _assignments = options;
      });
      if (found != null) {
        await _selectAssignment(found, status: resolvedAssignmentStatus);
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
      final hasActive = hasActiveGdnGrn(gdns);
      var driverName = _driverFieldFromGdnList(gdns, const [
        'driverName',
        'driver_name',
        'assignedDriverName',
      ]);
      var driverPhone = _driverFieldFromGdnList(gdns, const [
        'driverContact',
        'driver_contact',
        'driverPhone',
        'driver_phone',
        'phone',
      ]);
      var driverPlate = _driverFieldFromGdnList(gdns, const [
        'vehiclePlateNo',
        'vehicle_plate_no',
        'plateNumber',
        'plate_number',
        'vehiclePlate',
        'vehicle_plate',
        'plate',
      ]);
      if (driverName == null && driverPhone == null && driverPlate == null) {
        final fallback = await _driverInfoFromActiveAssignment(assignmentId);
        driverName = fallback?.$1;
        driverPhone = fallback?.$2;
        driverPlate = fallback?.$3;
      }
      setState(() {
        _gdnCreated = hasActive;
        _assignmentDriverName = driverName;
        _assignmentDriverPhone = driverPhone;
        _assignmentDriverPlate = driverPlate;
        if (hasActive) {
          _gdnMessage = context.l10n.gdnActiveLockedVoidToReplace;
        } else if (gdns.isNotEmpty) {
          _gdnMessage = context.l10n.gdnVoidedCreateNew;
        } else {
          _gdnMessage = null;
        }
      });
    } catch (_) {}
  }

  String? _driverFieldFromGdnList(List<dynamic> gdns, List<String> keys) {
    if (gdns.isEmpty) return null;
    final latest = pickLatestGdnGrnMap(gdns, const [
      'issuedAt',
      'createdAt',
      'updatedAt',
    ]);
    final value = gdnGrnPickString(latest, keys);
    return value.isEmpty ? null : value;
  }

  Future<(String?, String?, String?)?> _driverInfoFromActiveAssignment(
    String assignmentId,
  ) async {
    try {
      final payload = await ref.read(consignorActiveProvider.future);
      if (payload is! List) return null;
      for (final item in payload) {
        if (item is! Map) continue;
        final shipment = item.cast<String, dynamic>();
        final selectedDrivers = shipment['selectedDrivers'];
        if (selectedDrivers is! List) continue;
        for (final raw in selectedDrivers) {
          if (raw is! Map) continue;
          final row = raw.cast<String, dynamic>();
          final candidate =
              row['assignmentId']?.toString().trim().isNotEmpty == true
              ? row['assignmentId']!.toString().trim()
              : row['publicId']?.toString().trim().isNotEmpty == true
              ? row['publicId']!.toString().trim()
              : row['id']?.toString().trim();
          if (candidate != assignmentId) continue;
          final name = row['driverName']?.toString().trim();
          final phone =
              row['driverContact']?.toString().trim() ??
              row['phone']?.toString().trim();
          final plate =
              row['vehiclePlateNo']?.toString().trim() ??
              row['plate']?.toString().trim();
          return (
            name != null && name.isNotEmpty ? name : null,
            phone != null && phone.isNotEmpty ? phone : null,
            plate != null && plate.isNotEmpty ? plate : null,
          );
        }
      }
    } catch (_) {}
    return null;
  }

  bool _hasAssignmentDriverInfo() {
    return _assignmentDriverName?.trim().isNotEmpty == true ||
        _assignmentDriverPhone?.trim().isNotEmpty == true ||
        _assignmentDriverPlate?.trim().isNotEmpty == true;
  }

  Future<void> _refreshGrnState(String assignmentId) async {
    try {
      final grns = await ref
          .read(backendApiProvider)
          .grnOfAssignment(assignmentId);
      if (!mounted) return;
      final hasActive = hasActiveGdnGrn(grns);
      setState(() {
        _grnCreated = hasActive;
        if (hasActive) {
          _grnMessage = context.l10n.grnActiveLockedVoidToReplace;
        } else if (grns.isNotEmpty) {
          _grnMessage = context.l10n.grnVoidedCreateNew;
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

  bool _isGdnGeneratedOrLater(String assignmentStatus) {
    return _gdnGeneratedOrLaterStatuses.contains(
      assignmentStatus.trim().toUpperCase(),
    );
  }

  String? _effectiveDetailStatusLabel(ShipmentModel shipment) {
    final assignmentStatus = (_assignmentApiStatus ?? '').trim().toUpperCase();
    if (_assignmentId != null && assignmentStatus.isNotEmpty) {
      return assignmentStatus;
    }
    final bookingStatus = (shipment.apiStatusLabel ?? '').trim().toUpperCase();
    if (bookingStatus.isEmpty) return null;
    return bookingStatus;
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
    if (oldWidget.shipmentId != widget.shipmentId ||
        oldWidget.initialAssignmentId != widget.initialAssignmentId) {
      _assignmentResolutionAttempted = false;
      _resolveAssignmentScheduled = false;
      _assignmentId = null;
      _assignments = const [];
      _assignmentApiStatus = null;
      _assignmentDriverName = null;
      _assignmentDriverPhone = null;
      _assignmentDriverPlate = null;
      _feedbackLoadedForAid = null;
      _feedbackToDriverSubmitted = false;
      _shipmentIdFromAssignment = null;
      _resolvingShipmentFromAssignment = false;
      _shipmentFromAssignmentResolveScheduled = false;
      _detailSideEffectsScheduled = false;
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(userFacingMessage(e))));
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
              setState(() => _paymentRefreshSignal++);
              ref.invalidate(consignorShipmentsProvider);
              ref.invalidate(consignorActiveProvider);
              ref.invalidate(paymentsProvider);
            },
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      body: async.when(
        skipLoadingOnReload: true,
        data: (shipments) {
          final s = _findShipment(shipments);
          if (s == null) {
            _scheduleShipmentFromAssignmentResolve();
            if (_resolvingShipmentFromAssignment) {
              return const Center(child: CircularProgressIndicator());
            }
            return Center(child: Text(context.l10n.shipmentNotFound));
          }
          final assignedByStatus = _isAssignedOrLater(s.apiStatusLabel);
          _scheduleDetailSideEffects(
            s,
            assignmentEligible: _driverSelected || assignedByStatus,
          );
          final assignmentStatus =
              (_assignmentApiStatus ?? s.apiStatusLabel ?? '')
                  .trim()
                  .toUpperCase();
          final detailStatusLabel = _effectiveDetailStatusLabel(s);
          final gdnControlEnabled =
              _driverSelected || (assignedByStatus && _assignmentId != null);
          final grnControlEnabled =
              _assignmentId != null && _canOpenGrnControl(assignmentStatus);
          final canSendFeedbackToDriver =
              _assignmentId != null &&
              assignmentAllowsFeedback(assignmentStatus) &&
              !_feedbackToDriverSubmitted;
          final fmt = DateFormat.yMMMd(context.l10n.localeName);
          final showPaymentOnDetail =
              (!_resolvingAssignment || _assignments.isNotEmpty) &&
              _assignments.length <= 1;
          final showAssignmentDriver =
              _assignmentId != null && _hasAssignmentDriverInfo();
          final showNegotiationRoomAfterGdnControl =
              _isGdnGeneratedOrLater(assignmentStatus);
          return ListView(
            key: PageStorageKey<String>('consignor_shipment_detail_${s.id}'),
            padding: const EdgeInsets.all(20),
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            cacheExtent: double.infinity,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.displayId
                              .replaceAll(
                                'Booking ',
                                context.l10n.bookingPrefix,
                              )
                              .replaceAll(
                                'Assignment ',
                                context.l10n.assignmentPrefix,
                              ),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (s.hasDisplayableGoodsType) ...[
                          const SizedBox(height: 6),
                          Text(
                            context.translateDynamic(s.goodsDescription.trim()),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  StatusChip(
                    status: s.status,
                    labelOverride: detailStatusLabel,
                  ),
                ],
              ),
              if (showAssignmentDriver) ...[
                const SizedBox(height: 16),
                _AssignedDriverSummary(
                  name: _assignmentDriverName,
                  phone: _assignmentDriverPhone,
                  plate: _assignmentDriverPlate,
                ),
              ],
              const SizedBox(height: 16),
              if (!showNegotiationRoomAfterGdnControl) ...[
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
                const SizedBox(height: 16),
              ],
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
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: GlPrimaryButton(
                      label: context.l10n.openShipmentHistory,
                      icon: Icons.history_rounded,
                      onPressed: () => context.push(
                        '/consignor/shipment/${s.id}/history',
                      ),
                    ),
                  ),
                ],
              ),
              if (showPaymentOnDetail) ...[
                const SizedBox(height: 16),
                ConsignorShipmentPaymentSection(
                  shipmentId: s.id,
                  enabled: _driverSelected || assignedByStatus,
                  refreshSignal: _paymentRefreshSignal,
                ),
              ],
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
                    _assignmentSelector(context),
                    const SizedBox(height: 12),
                    if (_gdnMessage != null) ...[
                      _kv(context.l10n.statusLabelCap, _gdnMessage!),
                      const SizedBox(height: 12),
                    ],
                    GlPrimaryButton(
                      label: _gdnCreated
                          ? context.l10n.viewGdnForm
                          : context.l10n.openGdnForm,
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
              if (showNegotiationRoomAfterGdnControl) ...[
                const SizedBox(height: 16),
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
              ],
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
                    _assignmentSelector(context),
                    const SizedBox(height: 12),
                    if (_grnMessage != null) ...[
                      _kv(context.l10n.statusLabelCap, _grnMessage!),
                      const SizedBox(height: 12),
                    ],
                    GlPrimaryButton(
                      label: _grnCreated
                          ? context.l10n.viewGrnForm
                          : context.l10n.openGrnForm,
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
              const SizedBox(height: 16),
              _InfoCard(
                title: context.l10n.shipmentDetails,
                icon: Icons.inventory_2_outlined,
                children: [
                  _kv(context.l10n.weightLabelCap, _formatMetric(s.weightKg)),
                  _docDivider(),
                  _kv(context.l10n.volumeLabelCap, _formatMetric(s.volumeM3)),
                  _docDivider(),
                  _kv(
                    context.l10n.vehicleLabelCap,
                    context.translateDynamic(s.vehicleType),
                  ),
                  _docDivider(),
                  _kv(context.l10n.createdLabelCap, fmt.format(s.placedAt)),
                  if (s.paymentMethod != null) ...[
                    _docDivider(),
                    _kv(
                      context.l10n.priceTypeLabelCap,
                      context.translateDynamic(s.paymentMethod!),
                    ),
                  ],
                  if (s.priceOffer != null) ...[
                    _docDivider(),
                    _kv(
                      context.l10n.priceLabelCap,
                      _formatPrice(s.priceOffer!),
                    ),
                  ],
                ],
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
              _TimelineCard(
                loading: s.loadingAddress,
                offloading: s.offloadingAddress,
                placed: fmt.format(s.placedAt),
                eta: s.estimatedDelivery != null
                    ? fmt.format(s.estimatedDelivery!)
                    : 'TBD',
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
    final candidateShipmentId = _shipmentIdFromAssignment ?? widget.shipmentId;
    for (final s in shipments) {
      if (s.id == candidateShipmentId || s.publicId == candidateShipmentId) {
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

  Widget _assignmentSelector(BuildContext context) {
    if (_assignments.length <= 1 || _isRouteAssignmentLocked()) {
      return _kv(
        context.l10n.assignmentLabelCap,
        _assignmentId == null ? '—' : _assignmentDisplayLabel(_assignmentId!),
      );
    }
    return DropdownButtonFormField<String>(
      initialValue: _assignmentId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: context.l10n.assignmentsTitle,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: _assignments
          .map(
            (assignment) => DropdownMenuItem<String>(
              value: assignment.assignmentId,
              child: Text(
                _assignmentDisplayLabel(
                  assignment.assignmentId,
                  sequenceNumber: assignment.sequenceNumber,
                ),
              ),
            ),
          )
          .toList(),
      onChanged: (value) async {
        if (value == null || value == _assignmentId) return;
        String? status;
        for (final option in _assignments) {
          if (option.assignmentId == value) {
            status = option.status;
            break;
          }
        }
        await _selectAssignment(value, status: status);
      },
    );
  }

  String _assignmentDisplayLabel(String assignmentId, {int? sequenceNumber}) {
    final seq =
        sequenceNumber ??
        AssignmentDisplay.oneBasedIndexInOrder(
          _assignments.map((a) => a.assignmentId).toList(),
          assignmentId,
        );
    return AssignmentDisplay.sequenceLabel(context.l10n.assignmentPrefix, seq);
  }
}

class _AssignmentOption {
  const _AssignmentOption({
    required this.assignmentId,
    required this.status,
    required this.sequenceNumber,
  });

  final String assignmentId;
  final String status;
  final int sequenceNumber;
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
          labelText: context.l10n.remarkRequired,
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

class _AssignedDriverSummary extends StatelessWidget {
  const _AssignedDriverSummary({this.name, this.phone, this.plate});

  final String? name;
  final String? phone;
  final String? plate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final displayName = name?.trim();
    final displayPhone = phone?.trim();
    final displayPlate = plate?.trim();
    final initial = displayName != null && displayName.isNotEmpty
        ? displayName.substring(0, 1).toUpperCase()
        : '?';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primarySoft,
            child: Text(
              initial,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.driver,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.4,
                  ),
                ),
                if (displayName != null && displayName.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    context.translateDynamic(displayName),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
                if ((displayPhone != null && displayPhone.isNotEmpty) ||
                    (displayPlate != null && displayPlate.isNotEmpty)) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (displayPhone != null && displayPhone.isNotEmpty)
                        _AssignedDriverDetailChip(
                          icon: Icons.phone_outlined,
                          label: l10n.phoneLabel,
                          value: displayPhone,
                        ),
                      if (displayPlate != null && displayPlate.isNotEmpty)
                        _AssignedDriverDetailChip(
                          icon: Icons.directions_car_outlined,
                          label: l10n.platePrefix.replaceAll(':', '').trim(),
                          value: displayPlate,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignedDriverDetailChip extends StatelessWidget {
  const _AssignedDriverDetailChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
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
