import 'package:global_logistics_app/core/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';
import 'package:global_logistics_app/core/errors/user_facing_error.dart';
import 'package:global_logistics_app/core/providers/backend_api_provider.dart';
import 'package:global_logistics_app/core/providers/shipments_provider.dart';
import 'package:global_logistics_app/core/utils/gdn_grn_utils.dart';
import 'package:global_logistics_app/data/models/shipment_model.dart';
import 'package:global_logistics_app/features/documents/gdn_grn_document_sheet.dart';
import 'package:global_logistics_app/core/utils/form_field_utils.dart';
import 'package:global_logistics_app/shared/widgets/gl_primary_button.dart';
import 'package:intl/intl.dart';

class ConsignorGdnFormScreen extends ConsumerStatefulWidget {
  const ConsignorGdnFormScreen({
    super.key,
    required this.shipmentId,
    required this.assignmentId,
    required this.goodsDescription,
  });

  final String shipmentId;
  final String assignmentId;
  final String goodsDescription;

  @override
  ConsumerState<ConsignorGdnFormScreen> createState() =>
      _ConsignorGdnFormScreenState();
}

class _ConsignorGdnFormScreenState extends ConsumerState<ConsignorGdnFormScreen> {
  final _issuerCtrl = TextEditingController();
  final _consigneeCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _volumeCtrl = TextEditingController();
  final _packagingCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();

  bool _creating = false;
  bool _voiding = false;
  bool _loadingState = true;
  bool _locked = false;
  String? _stateMessage;
  String? _activePublicId;
  List<Map<String, dynamic>> _history = const [];
  final Map<String, String?> _fieldErrors = {};

  void _clearFieldError(String key) {
    if (_fieldErrors.containsKey(key)) {
      setState(() => _fieldErrors.remove(key));
    }
  }

  static const _dateKeys = ['issuedAt', 'createdAt'];

  @override
  void initState() {
    super.initState();
    _quantityCtrl.text = '1';
    _packagingCtrl.text = 'Normal';
    _loadGdnState();
  }

  @override
  void dispose() {
    _issuerCtrl.dispose();
    _consigneeCtrl.dispose();
    _contactCtrl.dispose();
    _quantityCtrl.dispose();
    _weightCtrl.dispose();
    _volumeCtrl.dispose();
    _packagingCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  String _pickStr(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return '';
  }

  void _applyGdnFields(Map<String, dynamic> m) {
    _issuerCtrl.text = _pickStr(m, [
      'issuersName',
      'issuerName',
      'issuers_name',
    ]);
    _consigneeCtrl.text = _pickStr(m, ['consigneeName', 'consignee_name']);
    _contactCtrl.text = _pickStr(m, [
      'consigneeContact',
      'consignee_contact',
      'contact',
    ]);
    final q = _pickStr(m, ['quantity']);
    if (q.isNotEmpty) _quantityCtrl.text = q;
    final w = _pickStr(m, ['weight']);
    if (w.isNotEmpty) _weightCtrl.text = w;
    final vol = _pickStr(m, ['volume']);
    if (vol.isNotEmpty) _volumeCtrl.text = vol;
    final pkg = _pickStr(m, [
      'packagingType',
      'packaging_type',
      'packaging',
    ]);
    if (pkg.isNotEmpty) _packagingCtrl.text = pkg;
    _remarksCtrl.text = _pickStr(m, ['remarks', 'remark']);
  }

  void _resetFormForNewEntry() {
    _issuerCtrl.clear();
    _consigneeCtrl.clear();
    _contactCtrl.clear();
    _quantityCtrl.text = '1';
    _weightCtrl.clear();
    _volumeCtrl.clear();
    _packagingCtrl.text = 'Normal';
    _remarksCtrl.clear();
  }

  Future<void> _loadGdnState() async {
    setState(() => _loadingState = true);
    try {
      final gdns = await ref
          .read(backendApiProvider)
          .gdnOfAssignment(widget.assignmentId);
      if (!mounted) return;

      final history = sortGdnGrnHistory(gdns, _dateKeys);
      final activeSummary = pickLatestActiveGdnGrnMap(gdns, _dateKeys);

      Map<String, dynamic>? resolved;
      String? activePid;
      if (activeSummary != null) {
        activePid = gdnGrnPublicId(activeSummary);
        if (activePid.isNotEmpty) {
          try {
            resolved = await ref.read(backendApiProvider).gdnGet(activePid);
          } catch (_) {
            resolved = activeSummary;
          }
        } else {
          resolved = activeSummary;
        }
      }

      if (!mounted) return;
      setState(() {
        _history = history;
        _locked = activeSummary != null;
        _activePublicId = activePid?.isNotEmpty == true ? activePid : null;
        if (_locked) {
          _stateMessage = context.l10n.gdnActiveLockedVoidToReplace;
        } else if (history.any(isGdnGrnVoidedMap)) {
          _stateMessage = context.l10n.gdnVoidedCreateNew;
          _resetFormForNewEntry();
        } else {
          _stateMessage = context.l10n.fillFormToCreateGdn;
        }
        if (resolved != null && _locked) {
          _applyGdnFields(resolved);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _stateMessage = userFacingMessage(e));
    } finally {
      if (mounted) setState(() => _loadingState = false);
    }
  }

  bool _validateGdnForm() {
    final l10n = context.l10n;
    final errors = <String, String?>{};

    if (isFormFieldEmpty(_issuerCtrl.text)) {
      errors['issuer'] = l10n.fieldIsRequired(l10n.issuerNameStar.replaceAll(' *', ''));
    }
    if (isFormFieldEmpty(_consigneeCtrl.text)) {
      errors['consignee'] =
          l10n.fieldIsRequired(l10n.consigneeNameStar.replaceAll(' *', ''));
    }
    if (isFormFieldEmpty(_contactCtrl.text)) {
      errors['contact'] =
          l10n.fieldIsRequired(l10n.consigneeContactStar.replaceAll(' *', ''));
    }
    if (isFormFieldEmpty(_quantityCtrl.text)) {
      errors['quantity'] = l10n.fieldIsRequired(l10n.quantityStar.replaceAll(' *', ''));
    }

    setState(() {
      _fieldErrors
        ..clear()
        ..addAll(errors);
    });
    return errors.isEmpty;
  }

  Map<String, dynamic> _gdnCreateBodyFromForm() {
    return buildGdnCreateBody(
      assignmentId: widget.assignmentId,
      issuersName: _issuerCtrl.text.trim(),
      consigneeName: _consigneeCtrl.text.trim(),
      consigneeContact: _contactCtrl.text.trim(),
      quantityText: _quantityCtrl.text.trim(),
      goodsDescription: widget.goodsDescription,
      weight: _weightCtrl.text.trim(),
      volume: _volumeCtrl.text.trim(),
      packagingType: _packagingCtrl.text.trim(),
      remarks: _remarksCtrl.text.trim(),
    );
  }

  Future<void> _voidActiveGdn() async {
    final pid = _activePublicId;
    if (_voiding || pid == null || pid.isEmpty) return;
    if (!_validateGdnForm()) return;
    final reason = await showVoidGdnGrnReasonDialog(
      context,
      title: context.l10n.voidGdnTitle,
      message: context.l10n.voidGdnMessage,
      reasonLabel: context.l10n.voidDocumentReasonHint,
      cancelLabel: context.l10n.cancel,
      confirmLabel: context.l10n.voidDocumentConfirm,
    );
    if (reason == null || !mounted) return;

    final createBody = _gdnCreateBodyFromForm();
    setState(() => _voiding = true);
    try {
      final api = ref.read(backendApiProvider);
      await api.gdnVoid(
        publicId: pid,
        reason: reason.isEmpty ? null : reason,
      );
      try {
        await api.gdnCreate(createBody);
        if (!mounted) return;
        ref.invalidate(consignorShipmentsProvider);
        ref.invalidate(shipmentDetailProvider(widget.shipmentId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.documentVoidAndReplacedSuccess)),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.documentVoidedCreateFailed)),
        );
      }
      await _loadGdnState();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFacingMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _voiding = false);
    }
  }

  Future<void> _createGdn() async {
    if (_creating || _locked) return;
    if (!_validateGdnForm()) return;    setState(() => _creating = true);
    try {
      await ref.read(backendApiProvider).gdnCreate(_gdnCreateBodyFromForm());
      if (!mounted) return;
      ref.invalidate(consignorShipmentsProvider);
      ref.invalidate(shipmentDetailProvider(widget.shipmentId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.gdnCreatedSuccess)),
      );
      await _loadGdnState();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFacingMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  void _openHistoryDocument(Map<String, dynamic> m) {
    final pid = gdnGrnPublicId(m);
    if (pid.isEmpty) return;
    final fmt = DateFormat.yMMMd(context.l10n.localeName);
    final at = DateTime.tryParse(
          m['issuedAt']?.toString() ?? m['createdAt']?.toString() ?? '',
        ) ??
        DateTime.now();
    showGdnGrnDocumentSheet(
      context,
      documentRef: DocumentRef(
        id: pid,
        title: context.l10n.goodsDeliveryNote,
        type: 'GDN',
        availableAt: at,
        documentNumber: m['documentNumber'] as String?,
        qrCodeValue: m['qrCodeValue'] as String?,
        status: m['status'] as String?,
      ),
      dateFmt: fmt,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(context.l10n.createGdn),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.assignment_turned_in_outlined,
                      color: AppColors.primary.withValues(alpha: 0.85),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.l10n.gdnForm,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text('${context.l10n.assignment}: ${widget.assignmentId}'),
                const SizedBox(height: 8),
                if (_loadingState)
                  const LinearProgressIndicator()
                else if (_stateMessage != null)
                  Text(
                    _stateMessage!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _locked ? AppColors.success : AppColors.textSecondary,
                    ),
                  ),
                if (!_loadingState && _history.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    context.l10n.gdnGrnDocumentHistory,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ..._history.map(
                    (m) => GdnGrnHistoryTile(
                      map: m,
                      typeLabel: context.l10n.gdnFilter,
                      dateKeys: _dateKeys,
                      onTap: () => _openHistoryDocument(m),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: _issuerCtrl,
                  enabled: !_locked,
                  onChanged: (_) => _clearFieldError('issuer'),
                  decoration: InputDecoration(
                    labelText: context.l10n.issuerNameStar,
                    errorText: _fieldErrors['issuer'],
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _consigneeCtrl,
                  enabled: !_locked,
                  onChanged: (_) => _clearFieldError('consignee'),
                  decoration: InputDecoration(
                    labelText: context.l10n.consigneeNameStar,
                    errorText: _fieldErrors['consignee'],
                    prefixIcon: const Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _contactCtrl,
                  enabled: !_locked,
                  onChanged: (_) => _clearFieldError('contact'),
                  decoration: InputDecoration(
                    labelText: context.l10n.consigneeContactStar,
                    errorText: _fieldErrors['contact'],
                    prefixIcon: const Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _quantityCtrl,
                        enabled: !_locked,
                        onChanged: (_) => _clearFieldError('quantity'),
                        decoration: InputDecoration(
                          labelText: context.l10n.quantityStar,
                          errorText: _fieldErrors['quantity'],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _packagingCtrl,
                        enabled: !_locked,
                        decoration: InputDecoration(
                          labelText: context.l10n.packaging,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _weightCtrl,
                        enabled: !_locked,
                        decoration: InputDecoration(
                          labelText: context.l10n.weight,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _volumeCtrl,
                        enabled: !_locked,
                        decoration: InputDecoration(
                          labelText: context.l10n.volume,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _remarksCtrl,
                  enabled: !_locked,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: context.l10n.remarks,
                    prefixIcon: const Icon(Icons.note_alt_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                if (_locked && _activePublicId != null) ...[
                  OutlinedButton.icon(
                    onPressed: (_voiding || _creating || _loadingState)
                        ? null
                        : _voidActiveGdn,
                    icon: _voiding
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.block_flipped),
                    label: Text(context.l10n.voidGdn),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(
                        color: AppColors.error.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                GlPrimaryButton(
                  label: _locked
                      ? context.l10n.gdnAlreadyCreated
                      : context.l10n.createGdn,
                  icon: _locked ? Icons.lock_rounded : Icons.description_outlined,
                  onPressed: (_locked || _creating || _loadingState)
                      ? null
                      : _createGdn,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GdnGrnHistoryTile extends StatelessWidget {
  const GdnGrnHistoryTile({
    super.key,
    required this.map,
    required this.typeLabel,
    required this.dateKeys,
    required this.onTap,
  });

  final Map<String, dynamic> map;
  final String typeLabel;
  final List<String> dateKeys;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final voided = isGdnGrnVoidedMap(map);
    final docNo = map['documentNumber']?.toString().trim();
    DateTime? at;
    for (final k in dateKeys) {
      at = DateTime.tryParse(map[k]?.toString() ?? '');
      if (at != null) break;
    }
    final dateLabel = at != null
        ? DateFormat.yMMMd(context.l10n.localeName).format(at)
        : '—';

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        docNo?.isNotEmpty == true
                            ? '${context.l10n.documentNoPrefix} $docNo'
                            : typeLabel,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              decoration: voided
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: voided
                                  ? AppColors.textTertiary
                                  : AppColors.textPrimary,
                            ),
                      ),
                      Text(
                        dateLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                DocStatusChip(
                  voided: voided,
                  issuedLabel: context.l10n.documentStatusIssued,
                  voidLabel: context.l10n.documentStatusVoid,
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textTertiary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DocStatusChip extends StatelessWidget {
  const DocStatusChip({
    super.key,
    required this.voided,
    required this.issuedLabel,
    required this.voidLabel,
  });

  final bool voided;
  final String issuedLabel;
  final String voidLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: voided
            ? AppColors.error.withValues(alpha: 0.1)
            : AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: voided
              ? AppColors.error.withValues(alpha: 0.35)
              : AppColors.success.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        voided ? voidLabel : issuedLabel,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: voided ? AppColors.error : AppColors.success,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
