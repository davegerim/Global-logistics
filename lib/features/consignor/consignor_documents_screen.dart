import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';
import 'package:global_logistics_app/core/providers/backend_api_provider.dart';
import 'package:global_logistics_app/core/providers/repository_provider.dart';
import 'package:global_logistics_app/core/providers/shipments_provider.dart';
import 'package:global_logistics_app/data/models/shipment_model.dart';
import 'package:intl/intl.dart';

/// Loads `GET /grn/assignment/{assignment-id}` and `GET /gdn/assignment/{assignment-id}`.
class ConsignorDocumentsScreen extends ConsumerStatefulWidget {
  const ConsignorDocumentsScreen({super.key});

  @override
  ConsumerState<ConsignorDocumentsScreen> createState() => _ConsignorDocumentsScreenState();
}

class _ConsignorDocumentsScreenState extends ConsumerState<ConsignorDocumentsScreen> {
  String? _assignmentId;
  String? _shipmentId;
  bool _loadingAssignment = false;
  String _selectedType = 'ALL';
  Future<List<DocumentRef>>? _documentsFuture;

  Future<void> _resolveAssignment(String shipmentPublicId) async {
    setState(() {
      _loadingAssignment = true;
      _shipmentId = shipmentPublicId;
    });
    try {
      final list =
          await ref.read(backendApiProvider).assignmentsConsignorOfShipment(shipmentPublicId);
      String? aid;
      if (list.isNotEmpty && list.first is Map) {
        aid = ((list.first as Map)['assignmentId'] as String?);
      }
      if (mounted) {
        setState(() {
          _assignmentId = aid;
          _documentsFuture = aid == null
              ? null
              : ref.read(logisticsRepositoryProvider).fetchDocumentsForAssignment(aid);
          _loadingAssignment = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingAssignment = false);
    }
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
    final fmt = DateFormat.yMMMd();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Documents'),
      ),
      body: shipmentsAsync.when(
        data: (List<ShipmentModel> shipments) {
          if (shipments.isEmpty) {
            return const Center(child: Text('No shipments — create a booking first.'));
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
              Container(
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
                          child: const Icon(Icons.description_outlined, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'GDN & GRN Hub',
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'View all shipping documents for the selected shipment assignment.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: DropdownButtonFormField<String>(
                  initialValue: selected.id,
                  isExpanded: true,
                  items: shipments
                      .map(
                        (s) => DropdownMenuItem(
                          value: s.id,
                          child: Text(
                            s.publicId,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) _resolveAssignment(v);
                  },
                  decoration: const InputDecoration(
                    labelText: 'Shipment',
                    prefixIcon: Icon(Icons.local_shipping_outlined),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              if (_loadingAssignment)
                const LinearProgressIndicator()
              else if (_assignmentId == null)
                _emptyStateCard(
                  context: context,
                  title: 'No assignment yet',
                  subtitle: 'This shipment has no active assignment, so no GDN/GRN is available yet.',
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
                        title: 'No documents found',
                        subtitle: 'No GDN or GRN records were returned for this assignment.',
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
                            _typeChip('ALL', docs.length),
                            _typeChip('GDN', docs.where((d) => d.type == 'GDN').length),
                            _typeChip('GRN', docs.where((d) => d.type == 'GRN').length),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (filtered.isEmpty)
                          _emptyStateCard(
                            context: context,
                            title: 'No ${_selectedType.toUpperCase()} documents',
                            subtitle: 'Try switching the filter to see all available documents.',
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
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }

  Widget _typeChip(String type, int count) {
    final selected = _selectedType == type;
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => setState(() => _selectedType = type),
      label: Text('$type ($count)'),
      selectedColor: AppColors.primary.withValues(alpha: 0.12),
      backgroundColor: AppColors.surface,
      labelStyle: TextStyle(
        color: selected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border,
        ),
      ),
    );
  }

  Widget _documentCard(BuildContext context, DocumentRef d, DateFormat fmt) {
    final isGdn = d.type == 'GDN';
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => _showDocumentViewer(context, d, fmt),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isGdn
                      ? AppColors.gold.withValues(alpha: 0.16)
                      : AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isGdn ? Icons.outbox_outlined : Icons.inbox_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.title, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 3),
                    Text(
                      '${d.type} • ${fmt.format(d.availableAt)}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                    ),
                    if ((d.documentNumber ?? '').isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'No: ${d.documentNumber}',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.visibility_outlined, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDocumentViewer(BuildContext context, DocumentRef d, DateFormat fmt) async {
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

  Widget _emptyStateCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
