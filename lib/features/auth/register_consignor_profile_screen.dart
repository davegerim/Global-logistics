import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';
import 'package:global_logistics_app/core/providers/backend_api_provider.dart';
import 'package:global_logistics_app/shared/widgets/gl_primary_button.dart';

class RegisterConsignorProfileScreen extends ConsumerStatefulWidget {
  const RegisterConsignorProfileScreen({super.key});

  @override
  ConsumerState<RegisterConsignorProfileScreen> createState() =>
      _RegisterConsignorProfileScreenState();
}

class _RegisterConsignorProfileScreenState
    extends ConsumerState<RegisterConsignorProfileScreen> {
  final _businessName = TextEditingController();
  final _tradeLicence = TextEditingController();
  var _busy = false;

  @override
  void dispose() {
    _businessName.dispose();
    _tradeLicence.dispose();
    super.dispose();
  }

  Future<void> _createProfile() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(backendApiProvider)
          .consignorsCreate(
            businessName: _businessName.text.trim().isEmpty
                ? null
                : _businessName.text.trim(),
            tradeLicence: _tradeLicence.text.trim().isEmpty
                ? null
                : _tradeLicence.text.trim(),
          );
      if (mounted) context.go('/consignor/home');
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
        title: const Text('Complete profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Step 3 - complete your consignor profile.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _businessName,
            decoration: const InputDecoration(
              labelText: 'Business name (optional)',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _tradeLicence,
            decoration: const InputDecoration(
              labelText: 'Trade licence ref / URL (optional)',
            ),
          ),
          const SizedBox(height: 24),
          GlPrimaryButton(
            label: 'Create profile',
            isLoading: _busy,
            onPressed: _createProfile,
          ),
        ],
      ),
    );
  }
}
