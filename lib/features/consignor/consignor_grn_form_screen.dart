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
import 'package:global_logistics_app/features/consignor/consignor_gdn_form_screen.dart';
import 'package:global_logistics_app/features/documents/gdn_grn_document_sheet.dart';
import 'package:global_logistics_app/core/utils/form_field_utils.dart';
import 'package:global_logistics_app/shared/widgets/gl_primary_button.dart';
import 'package:intl/intl.dart';

class ConsignorGrnFormScreen extends ConsumerStatefulWidget {
  const ConsignorGrnFormScreen({
    super.key,
    required this.shipmentId,
    required this.assignmentId,
    required this.assignmentStatus,
  });

  final String shipmentId;
  final String assignmentId;
  final String assignmentStatus;

  @override
  ConsumerState<ConsignorGrnFormScreen> createState() =>
      _ConsignorGrnFormScreenState();
}

class _ConsignorGrnFormScreenState
    extends ConsumerState<ConsignorGrnFormScreen> {
  final _receiverNameCtrl = TextEditingController();
  final _receivedQuantityCtrl = TextEditingController();
  final _receivedWeightCtrl = TextEditingController();
  final _receivedVolumeCtrl = TextEditingController();
  final _damageQtyCtrl = TextEditingController(text: '0');
  final _shortageQtyCtrl = TextEditingController(text: '0');
  final _conditionNoteCtrl = TextEditingController();
  final _receivedAtCtrl = TextEditingController();

  bool _loadingState = true;
  bool _creating = false;
  bool _voiding = false;
  bool _grnCreated = false;
  bool _consignorConfirmed = false;
  String? _stateMessage;
  String? _activePublicId;
  List<Map<String, dynamic>> _history = const [];
  final Map<String, String?> _fieldErrors = {};

  void _clearFieldError(String key) {
    if (_fieldErrors.containsKey(key)) {
      setState(() => _fieldErrors.remove(key));
    }
  }

  static const _dateKeys = ['receivedAt', 'issuedAt', 'createdAt'];

  @override
  void initState() {
    super.initState();
    _receivedAtCtrl.text = DateTime.now().toUtc().toIso8601String();
    _loadGrnState();
  }

  @override
  void dispose() {
    _receiverNameCtrl.dispose();
    _receivedQuantityCtrl.dispose();
    _receivedWeightCtrl.dispose();
    _receivedVolumeCtrl.dispose();
    _damageQtyCtrl.dispose();
    _shortageQtyCtrl.dispose();
    _conditionNoteCtrl.dispose();
    _receivedAtCtrl.dispose();
    super.dispose();
  }

  bool get _canCreateGrn => !_grnCreated && !_consignorConfirmed;

  bool get _canVoidGrn => _grnCreated && !_consignorConfirmed && _activePublicId != null;

  String _pickStr(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return '';
  }

  void _applyGrnFields(Map<String, dynamic> m) {
    _receiverNameCtrl.text = _pickStr(m, ['receiverName', 'receiver_name']);
    final rq = _pickStr(m, [
      'receivedQuantity',
      'received_quantity',
      'quantity',
    ]);
    if (rq.isNotEmpty) _receivedQuantityCtrl.text = rq;
    final rw = _pickStr(m, [
      'receivedWeight',
      'received_weight',
      'weight',
    ]);
    if (rw.isNotEmpty) _receivedWeightCtrl.text = rw;
    final rv = _pickStr(m, [
      'receivedVolume',
      'received_volume',
      'volume',
    ]);
    if (rv.isNotEmpty) _receivedVolumeCtrl.text = rv;
    final dq = _pickStr(m, [
      'damageQuantity',
      'damage_quantity',
      'damageQty',
    ]);
    if (dq.isNotEmpty) _damageQtyCtrl.text = dq;
    final sq = _pickStr(m, [
      'shortageQuantity',
      'shortage_quantity',
      'shortageQty',
    ]);
    if (sq.isNotEmpty) _shortageQtyCtrl.text = sq;
    _conditionNoteCtrl.text = _pickStr(m, [
      'conditionNote',
      'condition_note',
      'note',
    ]);
    final ra = _pickStr(m, [
      'receivedAt',
      'received_at',
      'issuedAt',
    ]);
    if (ra.isNotEmpty) _receivedAtCtrl.text = ra;
  }

  void _resetFormForNewEntry() {
    _receiverNameCtrl.clear();
    _receivedQuantityCtrl.clear();
    _receivedWeightCtrl.clear();
    _receivedVolumeCtrl.clear();
    _damageQtyCtrl.text = '0';
    _shortageQtyCtrl.text = '0';
    _conditionNoteCtrl.clear();
    _receivedAtCtrl.text = DateTime.now().toUtc().toIso8601String();
  }

  Future<void> _loadGrnState() async {
    setState(() => _loadingState = true);
    try {
      final grns = await ref
          .read(backendApiProvider)
          .grnOfAssignment(widget.assignmentId);
      if (!mounted) return;
      final status = widget.assignmentStatus.toUpperCase();
      final history = sortGdnGrnHistory(grns, _dateKeys);
      final activeSummary = pickLatestActiveGdnGrnMap(grns, _dateKeys);

      Map<String, dynamic>? resolved;
      String? activePid;
      if (activeSummary != null) {
        activePid = gdnGrnPublicId(activeSummary);
        if (activePid.isNotEmpty) {
          try {
            resolved = await ref.read(backendApiProvider).grnGet(activePid);
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
        _grnCreated = activeSummary != null;
        _activePublicId = activePid?.isNotEmpty == true ? activePid : null;
        _consignorConfirmed =
            status == 'CONSIGNOR_RECEIVED' || status == 'COMPLETED';
        if (_consignorConfirmed) {
          _stateMessage = context.l10n.grnExistsAndCompleted;
        } else if (_grnCreated) {
          _stateMessage = context.l10n.grnActiveLockedVoidToReplace;
        } else if (history.any(isGdnGrnVoidedMap)) {
          _stateMessage = context.l10n.grnVoidedCreateNew;
          _resetFormForNewEntry();
        } else {
          _stateMessage = context.l10n.fillFormToCreateGrnAfterOffload;
        }
        if (resolved != null && _grnCreated) {
          _applyGrnFields(resolved);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _stateMessage = userFacingMessage(e));
    } finally {
      if (mounted) setState(() => _loadingState = false);
    }
  }

  int _parseIntOrZero(String raw) {
    return int.tryParse(raw.trim()) ?? 0;
  }

  Future<DateTime?> _pickDateTime({required DateTime initial}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  bool _validateGrnForm() {
    final l10n = context.l10n;
    final errors = <String, String?>{};

    if (isFormFieldEmpty(_receiverNameCtrl.text)) {
      errors['receiverName'] = l10n.fieldIsRequired(l10n.receiverNameStar.replaceAll(' *', ''));
    }
    if (isFormFieldEmpty(_receivedQuantityCtrl.text)) {
      errors['receivedQuantity'] =
          l10n.fieldIsRequired(l10n.receivedQuantityStar.replaceAll(' *', ''));
    }
    if (isFormFieldEmpty(_conditionNoteCtrl.text)) {
      errors['conditionNote'] =
          l10n.fieldIsRequired(l10n.conditionNoteStar.replaceAll(' *', ''));
    }

    setState(() {
      _fieldErrors
        ..clear()
        ..addAll(errors);
    });
    return errors.isEmpty;
  }

  Map<String, dynamic> _grnCreateBodyFromForm() {
    return buildGrnCreateBody(
      assignmentId: widget.assignmentId,
      receiverName: _receiverNameCtrl.text.trim(),
      receivedQuantityText: _receivedQuantityCtrl.text.trim(),
      receivedWeight: _receivedWeightCtrl.text.trim(),
      receivedVolume: _receivedVolumeCtrl.text.trim(),
      damageQuantity: _parseIntOrZero(_damageQtyCtrl.text),
      shortageQuantity: _parseIntOrZero(_shortageQtyCtrl.text),
      conditionNote: _conditionNoteCtrl.text.trim(),
      receivedAt: _receivedAtCtrl.text.trim().isEmpty
          ? DateTime.now().toUtc().toIso8601String()
          : _receivedAtCtrl.text.trim(),
    );
  }

  Future<void> _voidActiveGrn() async {
    final pid = _activePublicId;
    if (_voiding || pid == null || pid.isEmpty) return;
    if (!_validateGrnForm()) {
      return;
    }
    final reason = await showVoidGdnGrnReasonDialog(
      context,
      title: context.l10n.voidGrnTitle,
      message: context.l10n.voidGrnMessage,
      reasonLabel: context.l10n.voidDocumentReasonHint,
      cancelLabel: context.l10n.cancel,
      confirmLabel: context.l10n.voidDocumentConfirm,
    );
    if (reason == null || !mounted) return;

    final createBody = _grnCreateBodyFromForm();
    setState(() => _voiding = true);
    try {
      final api = ref.read(backendApiProvider);
      await api.grnVoid(
        publicId: pid,
        reason: reason.isEmpty ? null : reason,
      );
      try {
        await api.grnCreate(createBody);
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
      await _loadGrnState();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFacingMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _voiding = false);
    }
  }

  Future<void> _createGrn() async {
    if (_creating || !_canCreateGrn) return;
    if (!_validateGrnForm()) return;

    setState(() => _creating = true);
    try {
      await ref.read(backendApiProvider).grnCreate(_grnCreateBodyFromForm());
      if (!mounted) return;
      ref.invalidate(consignorShipmentsProvider);
      ref.invalidate(shipmentDetailProvider(widget.shipmentId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.grnCreatedSuccessfully)),
      );
      await _loadGrnState();
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
          m['receivedAt']?.toString() ??
              m['issuedAt']?.toString() ??
              m['createdAt']?.toString() ??
              '',
        ) ??
        DateTime.now();
    showGdnGrnDocumentSheet(
      context,
      documentRef: DocumentRef(
        id: pid,
        title: context.l10n.goodsReceivedNote,
        type: 'GRN',
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
    final receivedFmt = DateFormat.yMMMd().add_jm();
    final receivedAt = DateTime.tryParse(_receivedAtCtrl.text.trim());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(context.l10n.createGrn),
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
                      Icons.inventory_rounded,
                      color: AppColors.primary.withValues(alpha: 0.85),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.l10n.grnForm,
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
                      color: (_grnCreated || _consignorConfirmed)
                          ? AppColors.success
                          : AppColors.textSecondary,
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
                      typeLabel: context.l10n.grnFilter,
                      dateKeys: _dateKeys,
                      onTap: () => _openHistoryDocument(m),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: _receiverNameCtrl,
                  enabled: _canCreateGrn,
                  onChanged: (_) => _clearFieldError('receiverName'),
                  decoration: InputDecoration(
                    labelText: context.l10n.receiverNameStar,
                    errorText: _fieldErrors['receiverName'],
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _receivedQuantityCtrl,
                  enabled: _canCreateGrn,
                  onChanged: (_) => _clearFieldError('receivedQuantity'),
                  decoration: InputDecoration(
                    labelText: context.l10n.receivedQuantityStar,
                    errorText: _fieldErrors['receivedQuantity'],
                    prefixIcon: const Icon(Icons.numbers_rounded),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _receivedWeightCtrl,
                        enabled: _canCreateGrn,
                        decoration: InputDecoration(
                          labelText: context.l10n.receivedWeight,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _receivedVolumeCtrl,
                        enabled: _canCreateGrn,
                        decoration: InputDecoration(
                          labelText: context.l10n.receivedVolume,
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
                        controller: _damageQtyCtrl,
                        enabled: _canCreateGrn,
                        decoration: InputDecoration(
                          labelText: context.l10n.damageQuantity,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _shortageQtyCtrl,
                        enabled: _canCreateGrn,
                        decoration: InputDecoration(
                          labelText: context.l10n.shortageQuantity,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _conditionNoteCtrl,
                  enabled: _canCreateGrn,
                  maxLines: 2,
                  onChanged: (_) => _clearFieldError('conditionNote'),
                  decoration: InputDecoration(
                    labelText: context.l10n.conditionNoteStar,
                    errorText: _fieldErrors['conditionNote'],
                    prefixIcon: const Icon(Icons.note_alt_outlined),
                  ),
                ),
                const SizedBox(height: 10),
                IgnorePointer(
                  ignoring: !_canCreateGrn,
                  child: Opacity(
                    opacity: _canCreateGrn ? 1 : 0.6,
                    child: InkWell(
                      onTap: () async {
                        final picked = await _pickDateTime(
                          initial: receivedAt?.toLocal() ?? DateTime.now(),
                        );
                        if (picked == null || !mounted) return;
                        setState(() {
                          _receivedAtCtrl.text =
                              picked.toUtc().toIso8601String();
                        });
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: context.l10n.receivedAt,
                          prefixIcon: Icon(Icons.schedule_rounded),
                        ),
                        child: Text(
                          receivedAt == null
                              ? 'Select received date & time'
                              : receivedFmt.format(receivedAt.toLocal()),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                if (_canVoidGrn) ...[
                  OutlinedButton.icon(
                    onPressed: (_voiding || _creating || _loadingState)
                        ? null
                        : _voidActiveGrn,
                    icon: _voiding
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.block_flipped),
                    label: Text(context.l10n.voidGrn),
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
                  label: _grnCreated
                      ? context.l10n.grnAlreadyCreated
                      : context.l10n.createGrn,
                  icon: _grnCreated
                      ? Icons.lock_rounded
                      : Icons.inventory_2_rounded,
                  onPressed: (_loadingState || _creating || !_canCreateGrn)
                      ? null
                      : _createGrn,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
