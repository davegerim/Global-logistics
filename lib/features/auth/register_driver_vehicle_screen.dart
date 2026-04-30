import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';
import 'package:global_logistics_app/core/providers/backend_api_provider.dart';
import 'package:global_logistics_app/shared/widgets/gl_primary_button.dart';

class RegisterDriverVehicleScreen extends ConsumerStatefulWidget {
  const RegisterDriverVehicleScreen({super.key});

  @override
  ConsumerState<RegisterDriverVehicleScreen> createState() =>
      _RegisterDriverVehicleScreenState();
}

class _RegisterDriverVehicleScreenState
    extends ConsumerState<RegisterDriverVehicleScreen> {
  final _libriNumber = TextEditingController();
  final _libriDocument = TextEditingController();
  final _plateNumber = TextEditingController();
  final _insuranceNumber = TextEditingController();
  final _insuranceDocument = TextEditingController();
  final _type = TextEditingController();
  final _details = TextEditingController();
  final _photo = TextEditingController();
  var _busy = false;

  @override
  void dispose() {
    _libriNumber.dispose();
    _libriDocument.dispose();
    _plateNumber.dispose();
    _insuranceNumber.dispose();
    _insuranceDocument.dispose();
    _type.dispose();
    _details.dispose();
    _photo.dispose();
    super.dispose();
  }

  Future<void> _createVehicleProfile() async {
    setState(() => _busy = true);
    try {
      await ref.read(backendApiProvider).vehiclesCreate({
        if (_libriNumber.text.trim().isNotEmpty)
          'libriNumber': _libriNumber.text.trim(),
        if (_libriDocument.text.trim().isNotEmpty)
          'libriDocument': _libriDocument.text.trim(),
        if (_plateNumber.text.trim().isNotEmpty)
          'plateNumber': _plateNumber.text.trim(),
        if (_insuranceNumber.text.trim().isNotEmpty)
          'insuranceNumber': _insuranceNumber.text.trim(),
        if (_insuranceDocument.text.trim().isNotEmpty)
          'insuranceDocument': _insuranceDocument.text.trim(),
        if (_type.text.trim().isNotEmpty) 'type': _type.text.trim(),
        if (_details.text.trim().isNotEmpty) 'details': _details.text.trim(),
        if (_photo.text.trim().isNotEmpty) 'photo': _photo.text.trim(),
      });
      if (mounted) context.go('/driver/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Vehicle profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Step 4 — complete your vehicle profile.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _libriNumber,
            decoration: const InputDecoration(labelText: 'Libri number'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _libriDocument,
            decoration: const InputDecoration(labelText: 'Libri document URL'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _plateNumber,
            decoration: const InputDecoration(labelText: 'Plate number'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _insuranceNumber,
            decoration: const InputDecoration(labelText: 'Insurance number'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _insuranceDocument,
            decoration: const InputDecoration(
              labelText: 'Insurance document URL',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _type,
            decoration: const InputDecoration(labelText: 'Vehicle type'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _details,
            decoration: const InputDecoration(labelText: 'Details'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _photo,
            decoration: const InputDecoration(labelText: 'Photo URL'),
          ),
          const SizedBox(height: 24),
          GlPrimaryButton(
            label: 'Save vehicle profile',
            isLoading: _busy,
            onPressed: _createVehicleProfile,
          ),
        ],
      ),
    );
  }
}
