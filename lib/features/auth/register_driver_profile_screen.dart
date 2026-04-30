import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';
import 'package:global_logistics_app/core/providers/backend_api_provider.dart';
import 'package:global_logistics_app/shared/widgets/gl_primary_button.dart';

class RegisterDriverProfileScreen extends ConsumerStatefulWidget {
  const RegisterDriverProfileScreen({super.key});

  @override
  ConsumerState<RegisterDriverProfileScreen> createState() =>
      _RegisterDriverProfileScreenState();
}

class _RegisterDriverProfileScreenState
    extends ConsumerState<RegisterDriverProfileScreen> {
  final _licenceNumber = TextEditingController();
  final _licenceDocument = TextEditingController();
  final _preferredLanes = TextEditingController();
  var _busy = false;

  @override
  void dispose() {
    _licenceNumber.dispose();
    _licenceDocument.dispose();
    _preferredLanes.dispose();
    super.dispose();
  }

  Future<void> _createDriverProfile() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(backendApiProvider)
          .driversCreate(
            licenceNumber: _licenceNumber.text.trim().isEmpty
                ? null
                : _licenceNumber.text.trim(),
            licenceDocument: _licenceDocument.text.trim().isEmpty
                ? null
                : _licenceDocument.text.trim(),
            preferredLanes: _preferredLanes.text.trim().isEmpty
                ? null
                : _preferredLanes.text.trim(),
          );
      if (mounted) context.go('/register-driver-vehicle');
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
        title: const Text('Driver profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Step 3 — complete your personal profile.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _licenceNumber,
            decoration: const InputDecoration(labelText: 'Licence number'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _licenceDocument,
            decoration: const InputDecoration(
              labelText: 'Licence document ref',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _preferredLanes,
            decoration: const InputDecoration(
              labelText: 'Preferred lanes (optional)',
            ),
          ),
          const SizedBox(height: 24),
          GlPrimaryButton(
            label: 'Save personal profile',
            isLoading: _busy,
            onPressed: _createDriverProfile,
          ),
        ],
      ),
    );
  }
}
