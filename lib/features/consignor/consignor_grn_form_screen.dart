import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';
import 'package:global_logistics_app/core/errors/user_facing_error.dart';
import 'package:global_logistics_app/core/providers/backend_api_provider.dart';
import 'package:global_logistics_app/core/providers/shipments_provider.dart';
import 'package:global_logistics_app/shared/widgets/gl_primary_button.dart';

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

Map<String, dynamic> _pickLatestMap(
  List<dynamic> list,
  List<String> dateKeys,
) {
  Map<String, dynamic>? best;
  DateTime? bestTime;
  for (final e in list) {
    if (e is! Map) continue;
    final m = Map<String, dynamic>.from(e);
    DateTime? t;
    for (final k in dateKeys) {
      final v = m[k];
      if (v != null) {
        t = DateTime.tryParse(v.toString());
        if (t != null) break;
      }
    }
    if (best == null) {
      best = m;
      bestTime = t;
      continue;
    }
    if (t != null && (bestTime == null || t.isAfter(bestTime))) {
      best = m;
      bestTime = t;
    }
  }
  return best ?? {};
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
  bool _grnCreated = false;
  bool _consignorConfirmed = false;
  String? _stateMessage;

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

  Future<void> _loadGrnState() async {
    setState(() => _loadingState = true);
    try {
      final grns = await ref
          .read(backendApiProvider)
          .grnOfAssignment(widget.assignmentId);
      if (!mounted) return;
      final status = widget.assignmentStatus.toUpperCase();

      Map<String, dynamic>? resolved;
      if (grns.isNotEmpty) {
        final summary = _pickLatestMap(
          grns,
          const ['receivedAt', 'issuedAt', 'createdAt'],
        );
        final pid = summary['publicId'] as String?;
        if (pid != null && pid.isNotEmpty) {
          try {
            resolved = await ref.read(backendApiProvider).grnGet(pid);
          } catch (_) {
            resolved = summary;
          }
        } else {
          resolved = summary;
        }
      }

      if (!mounted) return;
      setState(() {
        _grnCreated = grns.isNotEmpty;
        _consignorConfirmed =
            status == 'CONSIGNOR_RECEIVED' || status == 'COMPLETED';
        if (_consignorConfirmed) {
          _stateMessage = 'GRN exists and consignor confirmation is completed.';
        } else if (_grnCreated) {
          _stateMessage =
              'GRN already created. Confirm final receipt on the shipment screen.';
        } else {
          _stateMessage = 'Fill the form to create GRN after offloading.';
        }
        if (resolved != null) {
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

  Future<void> _createGrn() async {
    if (_creating || !_canCreateGrn) return;
    if (_receiverNameCtrl.text.trim().isEmpty ||
        _receivedQuantityCtrl.text.trim().isEmpty ||
        _conditionNoteCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Receiver name, quantity and condition note are required.',
          ),
        ),
      );
      return;
    }

    setState(() => _creating = true);
    try {
      await ref.read(backendApiProvider).grnCreate({
        'assignmentId': widget.assignmentId,
        'receiverName': _receiverNameCtrl.text.trim(),
        'receivedQuantity': _receivedQuantityCtrl.text.trim(),
        'receivedWeight': _receivedWeightCtrl.text.trim(),
        'receivedVolume': _receivedVolumeCtrl.text.trim(),
        'damageQuantity': _parseIntOrZero(_damageQtyCtrl.text),
        'shortageQuantity': _parseIntOrZero(_shortageQtyCtrl.text),
        'conditionNote': _conditionNoteCtrl.text.trim(),
        'receivedAt': _receivedAtCtrl.text.trim().isEmpty
            ? DateTime.now().toUtc().toIso8601String()
            : _receivedAtCtrl.text.trim(),
      });
      if (!mounted) return;
      setState(() {
        _grnCreated = true;
        _stateMessage =
            'GRN created successfully. Confirm final receipt on the shipment screen.';
      });
      ref.invalidate(consignorShipmentsProvider);
      ref.invalidate(shipmentDetailProvider(widget.shipmentId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('GRN created successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(userFacingMessage(e))));
    } finally {
      if (mounted) setState(() => _creating = false);
    }
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
        title: const Text('Create GRN'),
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
                      'GRN Form',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text('Assignment: ${widget.assignmentId}'),
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
                const SizedBox(height: 12),
                TextField(
                  controller: _receiverNameCtrl,
                  enabled: _canCreateGrn,
                  decoration: const InputDecoration(
                    labelText: 'Receiver name *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _receivedQuantityCtrl,
                  enabled: _canCreateGrn,
                  decoration: const InputDecoration(
                    labelText: 'Received quantity *',
                    prefixIcon: Icon(Icons.numbers_rounded),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _receivedWeightCtrl,
                        enabled: _canCreateGrn,
                        decoration: const InputDecoration(
                          labelText: 'Received weight',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _receivedVolumeCtrl,
                        enabled: _canCreateGrn,
                        decoration: const InputDecoration(
                          labelText: 'Received volume',
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
                        decoration: const InputDecoration(
                          labelText: 'Damage quantity',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _shortageQtyCtrl,
                        enabled: _canCreateGrn,
                        decoration: const InputDecoration(
                          labelText: 'Shortage quantity',
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
                  decoration: const InputDecoration(
                    labelText: 'Condition note *',
                    prefixIcon: Icon(Icons.note_alt_outlined),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _receivedAtCtrl,
                  enabled: _canCreateGrn,
                  decoration: const InputDecoration(
                    labelText: 'Received at (ISO8601 UTC)',
                    prefixIcon: Icon(Icons.schedule_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                GlPrimaryButton(
                  label: _grnCreated ? 'GRN already created' : 'Create GRN',
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
