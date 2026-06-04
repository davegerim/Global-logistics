import 'package:global_logistics_app/core/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:global_logistics_app/core/providers/backend_api_provider.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';
import 'package:global_logistics_app/core/utils/consignor_account_status_utils.dart';
import 'package:global_logistics_app/data/mappers/api_mappers.dart';
import 'package:global_logistics_app/core/providers/auth_provider.dart';
import 'package:global_logistics_app/core/providers/notifications_provider.dart';
import 'package:global_logistics_app/core/providers/shipments_provider.dart';
import 'package:global_logistics_app/data/models/shipment_model.dart';
import 'package:global_logistics_app/data/models/shipment_status.dart';
import 'package:global_logistics_app/shared/widgets/section_header.dart';
import 'package:global_logistics_app/shared/widgets/status_chip.dart';
import 'package:global_logistics_app/shared/widgets/shipment_card.dart';
import 'package:global_logistics_app/shared/widgets/gl_primary_button.dart';

class ConsignorHomeScreen extends ConsumerStatefulWidget {
  const ConsignorHomeScreen({super.key});

  @override
  ConsumerState<ConsignorHomeScreen> createState() =>
      _ConsignorHomeScreenState();
}

class _ConsignorHomeScreenState extends ConsumerState<ConsignorHomeScreen> {
  final Map<String, List<_AssignmentPreview>> _assignmentPreviewsByShipment =
      {};
  final Set<String> _loadingAssignments = <String>{};
  final Set<String> _scheduledAssignmentLoads = <String>{};
  final Map<String, Future<void>> _assignmentLoadTasks = {};

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final canBook = auth.canCreateConsignorBooking;
    final accountStatusLabel =
        ConsignorAccountStatusUtils.homeDisplayLabel(auth, context.l10n);
    final shipments = ref.watch(consignorShipmentsProvider);
    final unreadAsync = ref.watch(unreadNotificationsCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.surface,
            toolbarHeight: 82,
            title: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primarySoft,
                  child: Text(
                    (auth.displayName ?? 'G').substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.l10n.welcomeBack,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        auth.displayName ?? context.l10n.consignor,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => context.push('/consignor/notifications'),
                  icon: unreadAsync.when(
                    data: (n) => Badge(
                      isLabelVisible: n > 0,
                      label: Text('$n'),
                      child: const Icon(Icons.notifications_outlined),
                    ),
                    loading: () => const Icon(Icons.notifications_outlined),
                    error: (error, stackTrace) =>
                        const Icon(Icons.notifications_outlined),
                  ),
                ),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: AppColors.heroCardGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(99),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Text(
                                context.l10n.quickAction,
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                      color: AppColors.goldMuted,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              context.l10n.createBooking,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            if (accountStatusLabel != null) ...[
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.22),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.pending_actions_rounded,
                                      size: 18,
                                      color: Colors.white.withValues(alpha: 0.9),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${context.l10n.statusPrefix}$accountStatusLabel · ${context.l10n.bookingUnlocksAfterAdminApproval}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Colors.white.withValues(
                                                alpha: 0.9,
                                              ),
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: SizedBox(
                                width: 190,
                                child: GlPrimaryButton(
                                  useGoldAccent: true,
                                  showShadow: false,
                                  label: context.l10n.newBooking,
                                  icon: Icons.arrow_forward_rounded,
                                  onPressed: canBook
                                      ? () => context.push('/consignor/create')
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        right: -10,
                        bottom: -15,
                        child: IgnorePointer(
                          child: Image.asset(
                            'assets/images/huge_truck.png',
                            width: 150,
                            height: 150,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
            sliver: SliverToBoxAdapter(
              child: SectionHeader(
                title: context.l10n.activeAndRecent,
                actionLabel: context.l10n.viewAll,
                onAction: () => context.go('/consignor/shipments'),
              ),
            ),
          ),
          shipments.when(
            data: (list) {
              final featured = list
                  .where(
                    (s) =>
                        s.status != ShipmentStatus.completed &&
                        s.status != ShipmentStatus.cancelled,
                  )
                  .take(2)
                  .toList();
              if (featured.isEmpty) {
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      context.l10n.noActiveShipmentsCreateBookingToGetStarted,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.separated(
                  itemCount: featured.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 14),
                  itemBuilder: (context, i) {
                    final s = featured[i];
                    _ensureAssignmentPreviewsLoaded(s);
                    final previews =
                        _assignmentPreviewsByShipment[s.id] ?? const [];
                    return ShipmentCard(
                      shipment: s,
                      assignmentStatuses: previews
                          .map((e) => e.status)
                          .where((e) => e.isNotEmpty)
                          .toList(),
                      assignmentsLoading: _loadingAssignments.contains(s.id),
                      onTap: () => _onShipmentTap(s),
                    );
                  },
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(child: Text('${context.l10n.errorPrefix}: $e')),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
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
