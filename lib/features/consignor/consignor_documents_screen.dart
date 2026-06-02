import 'package:global_logistics_app/core/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';
import 'package:global_logistics_app/core/errors/user_facing_error.dart';
import 'package:global_logistics_app/core/providers/backend_api_provider.dart';
import 'package:global_logistics_app/core/providers/repository_provider.dart';
import 'package:global_logistics_app/core/providers/shipments_provider.dart';
import 'package:global_logistics_app/data/models/shipment_model.dart';
import 'package:global_logistics_app/features/documents/gdn_grn_document_sheet.dart';
import 'package:intl/intl.dart';

/// Loads `GET /grn/assignment/{assignment-id}` and `GET /gdn/assignment/{assignment-id}`.
class ConsignorDocumentsScreen extends ConsumerStatefulWidget {
  const ConsignorDocumentsScreen({super.key});

  @override
  ConsumerState<ConsignorDocumentsScreen> createState() =>
      _ConsignorDocumentsScreenState();
}

class _ConsignorDocumentsScreenState
    extends ConsumerState<ConsignorDocumentsScreen> {
  String? _assignmentId;
  String? _shipmentId;
  List<String> _assignments = const [];
  bool _loadingAssignment = false;
  String _selectedType = 'ALL';
  Future<List<DocumentRef>>? _documentsFuture;

  Future<void> _resolveAssignment(String shipmentPublicId) async {
    setState(() {
      _loadingAssignment = true;
      _shipmentId = shipmentPublicId;
      _assignments = const [];
      _assignmentId = null;
      _documentsFuture = null;
    });
    try {
      final list = await ref
          .read(backendApiProvider)
          .assignmentsConsignorOfShipment(shipmentPublicId);
      final assignments = <String>[];
      for (final item in list) {
        if (item is! Map) continue;
        final row = item.cast<String, dynamic>();
        final assignmentId =
            row['assignmentId']?.toString().trim().isNotEmpty == true
            ? row['assignmentId']!.toString().trim()
            : row['publicId']?.toString().trim().isNotEmpty == true
            ? row['publicId']!.toString().trim()
            : row['id']?.toString().trim();
        if (assignmentId == null || assignmentId.isEmpty) continue;
        assignments.add(assignmentId);
      }
      final aid = assignments.isEmpty ? null : assignments.first;
      if (mounted) {
        setState(() {
          _assignments = assignments;
          _assignmentId = aid;
          _documentsFuture = aid == null
              ? null
              : ref
                    .read(logisticsRepositoryProvider)
                    .fetchDocumentsForAssignment(aid);
          _loadingAssignment = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingAssignment = false);
    }
  }

  void _selectAssignment(String assignmentId) {
    setState(() {
      _assignmentId = assignmentId;
      _documentsFuture = ref
          .read(logisticsRepositoryProvider)
          .fetchDocumentsForAssignment(assignmentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(consignorShipmentsProvider, (p, n) {
      n.whenData((list) {
        if (list.isNotEmpty && _shipmentId == null && mounted) {
          _resolveAssignment(list.first.id);
        }
      });
    });

    final shipmentsAsync = ref.watch(consignorShipmentsProvider);
    final fmt = DateFormat.yMMMd(context.l10n.localeName);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(context.l10n.documents)),
      body: shipmentsAsync.when(
        data: (List<ShipmentModel> shipments) {
          if (shipments.isEmpty) {
            return Center(
              child: Text(context.l10n.noShipmentsCreateBookingFirst),
            );
          }
          ShipmentModel selected = shipments.first;
          if (_shipmentId != null) {
            for (final s in shipments) {
              if (s.id == _shipmentId) {
                selected = s;
                break;
              }
            }
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0E4A42), Color(0xFF135C52)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.description_rounded,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                context.l10n.gdnGrnHub,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.only(right: 90),
                          child: Text(
                            context.l10n.viewAllShippingDocumentsDesc,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  height: 1.4,
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
                        'assets/images/boxes-3d-icon-png-download-4504985.webp',
                        width: 130,
                        height: 130,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderLight, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.03),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.local_shipping_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        key: ValueKey(selected.id),
                        initialValue: selected.id,
                        isExpanded: true,
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.primary,
                        ),
                        decoration: InputDecoration(
                          labelText: context.l10n.selectShipment,
                          labelStyle: const TextStyle(
                            color: AppColors.textTertiary,
                            fontWeight: FontWeight.w600,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        items: shipments
                            .map(
                              (s) => DropdownMenuItem(
                                value: s.id,
                                child: Text(
                                  s.displayId
                                      .replaceAll(
                                        'Booking #',
                                        context.l10n.bookingPrefix,
                                      )
                                      .replaceAll(
                                        'Assignment #',
                                        context.l10n.assignmentPrefix,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) _resolveAssignment(v);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              if (_assignments.length > 1) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.borderLight,
                      width: 1.5,
                    ),
                  ),
                  child: DropdownButtonFormField<String>(
                    initialValue: _assignmentId,
                    isExpanded: true,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.primary,
                    ),
                    decoration: InputDecoration(
                      labelText: context.l10n.assignmentsTitle,
                      labelStyle: const TextStyle(
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    items: _assignments
                        .map(
                          (assignmentId) => DropdownMenuItem<String>(
                            value: assignmentId,
                            child: Text(
                              '${context.l10n.assignmentPrefix}$assignmentId',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null || value == _assignmentId) return;
                      _selectAssignment(value);
                    },
                  ),
                ),
              ],
              const SizedBox(height: 18),
              if (_loadingAssignment)
                const LinearProgressIndicator()
              else if (_assignmentId == null)
                _emptyStateCard(
                  context: context,
                  title: context.l10n.noAssignmentYet,
                  subtitle: context.l10n.noGdnGrnForShipment,
                  icon: Icons.assignment_late_outlined,
                )
              else
                FutureBuilder(
                  future: _documentsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final docs = snapshot.data ?? [];
                    final filtered = _selectedType == 'ALL'
                        ? docs
                        : docs.where((d) => d.type == _selectedType).toList();
                    if (docs.isEmpty) {
                      return _emptyStateCard(
                        context: context,
                        title: context.l10n.noDocumentsFound,
                        subtitle: context.l10n.noGdnGrnRecordsReturned,
                        icon: Icons.folder_open_outlined,
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _typeChip(context, 'ALL', docs.length),
                            _typeChip(
                              context,
                              'GDN',
                              docs.where((d) => d.type == 'GDN').length,
                            ),
                            _typeChip(
                              context,
                              'GRN',
                              docs.where((d) => d.type == 'GRN').length,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (filtered.isEmpty)
                          _emptyStateCard(
                            context: context,
                            title: context.l10n.noTypeDocuments(
                              _filterLabel(context, _selectedType),
                            ),
                            subtitle: context.l10n.trySwitchingFilter,
                            icon: Icons.filter_alt_off_outlined,
                          )
                        else
                          ...filtered.map(
                            (d) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _documentCard(context, d, fmt),
                            ),
                          ),
                      ],
                    );
                  },
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(userFacingMessage(e))),
      ),
    );
  }

  String _filterLabel(BuildContext context, String type) {
    switch (type) {
      case 'ALL':
        return context.l10n.allFilter;
      case 'GDN':
        return context.l10n.gdnFilter;
      case 'GRN':
        return context.l10n.grnFilter;
      default:
        return type;
    }
  }

  Widget _typeChip(BuildContext context, String type, int count) {
    final selected = _selectedType == type;
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => setState(() => _selectedType = type),
      label: Text('${_filterLabel(context, type)} ($count)'),
      selectedColor: AppColors.primary.withValues(alpha: 0.12),
      backgroundColor: AppColors.surface,
      labelStyle: TextStyle(
        color: selected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.border,
        ),
      ),
    );
  }

  Widget _documentCard(BuildContext context, DocumentRef d, DateFormat fmt) {
    final isGdn = d.type == 'GDN';
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () =>
            showGdnGrnDocumentSheet(context, documentRef: d, dateFmt: fmt),
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderLight, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.03),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isGdn
                      ? AppColors.gold.withValues(alpha: 0.15)
                      : AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isGdn
                        ? AppColors.gold.withValues(alpha: 0.3)
                        : AppColors.primary.withValues(alpha: 0.1),
                  ),
                ),
                child: Icon(
                  isGdn ? Icons.outbox_rounded : Icons.inbox_rounded,
                  color: isGdn ? AppColors.goldMuted : AppColors.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isGdn
                          ? context.l10n.goodsDeliveryNote
                          : context.l10n.goodsReceivedNote,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${isGdn ? context.l10n.gdnFilter : context.l10n.grnFilter} • ${fmt.format(d.availableAt)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if ((d.documentNumber ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${context.l10n.documentNoPrefix} ${d.documentNumber}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textTertiary,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceMuted,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.textSecondary,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyStateCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderLight, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.1),
                width: 2,
              ),
            ),
            child: Icon(icon, color: AppColors.primary, size: 32),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
