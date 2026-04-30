import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';
import 'package:global_logistics_app/core/providers/backend_api_provider.dart';
import 'package:global_logistics_app/core/providers/shipments_provider.dart';
import 'package:global_logistics_app/shared/widgets/gl_primary_button.dart';

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
  bool _loadingState = true;
  bool _locked = false;
  String? _stateMessage;

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

  Future<void> _loadGdnState() async {
    setState(() => _loadingState = true);
    try {
      final gdns = await ref
          .read(backendApiProvider)
          .gdnOfAssignment(widget.assignmentId);
      if (!mounted) return;
      setState(() {
        _locked = gdns.isNotEmpty;
        _stateMessage = _locked
            ? 'GDN already generated and locked.'
            : 'Fill the form to create GDN.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _stateMessage = '$e');
    } finally {
      if (mounted) setState(() => _loadingState = false);
    }
  }

  Future<void> _createGdn() async {
    if (_creating || _locked) return;
    if (_issuerCtrl.text.trim().isEmpty ||
        _consigneeCtrl.text.trim().isEmpty ||
        _contactCtrl.text.trim().isEmpty ||
        _quantityCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Issuer, consignee, contact and quantity are required.')),
      );
      return;
    }
    setState(() => _creating = true);
    try {
      await ref.read(backendApiProvider).gdnCreate({
        'assignmentId': widget.assignmentId,
        'issuersName': _issuerCtrl.text.trim(),
        'consigneeName': _consigneeCtrl.text.trim(),
        'consigneeContact': _contactCtrl.text.trim(),
        'quantity': _quantityCtrl.text.trim(),
        'weight': _weightCtrl.text.trim(),
        'volume': _volumeCtrl.text.trim(),
        'packagingType': _packagingCtrl.text.trim(),
        'goodsDescription': widget.goodsDescription,
        'remarks': _remarksCtrl.text.trim(),
      });
      if (!mounted) return;
      setState(() {
        _locked = true;
        _stateMessage = 'GDN created successfully. Editing is disabled.';
      });
      ref.invalidate(consignorShipmentsProvider);
      ref.invalidate(shipmentDetailProvider(widget.shipmentId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('GDN created. Driver can now confirm loading.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
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
        title: const Text('Create GDN'),
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
                    Text('GDN Form', style: Theme.of(context).textTheme.titleSmall),
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
                      color: _locked ? AppColors.success : AppColors.textSecondary,
                    ),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: _issuerCtrl,
                  enabled: !_locked,
                  decoration: const InputDecoration(
                    labelText: 'Issuer name *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _consigneeCtrl,
                  enabled: !_locked,
                  decoration: const InputDecoration(
                    labelText: 'Consignee name *',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _contactCtrl,
                  enabled: !_locked,
                  decoration: const InputDecoration(
                    labelText: 'Consignee contact *',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _quantityCtrl,
                        enabled: !_locked,
                        decoration: const InputDecoration(labelText: 'Quantity *'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _packagingCtrl,
                        enabled: !_locked,
                        decoration: const InputDecoration(labelText: 'Packaging'),
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
                        decoration: const InputDecoration(labelText: 'Weight'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _volumeCtrl,
                        enabled: !_locked,
                        decoration: const InputDecoration(labelText: 'Volume'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _remarksCtrl,
                  enabled: !_locked,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Remarks',
                    prefixIcon: Icon(Icons.note_alt_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                GlPrimaryButton(
                  label: _locked ? 'GDN already created' : 'Create GDN',
                  icon: _locked ? Icons.lock_rounded : Icons.description_outlined,
                  onPressed: (_locked || _creating || _loadingState) ? null : _createGdn,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
