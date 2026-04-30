import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';
import 'package:global_logistics_app/core/providers/auth_provider.dart';
import 'package:global_logistics_app/shared/widgets/gl_primary_button.dart';

class RegisterConsignorVerifyScreen extends ConsumerStatefulWidget {
  const RegisterConsignorVerifyScreen({super.key, required this.phone});

  final String phone;

  @override
  ConsumerState<RegisterConsignorVerifyScreen> createState() =>
      _RegisterConsignorVerifyScreenState();
}

class _RegisterConsignorVerifyScreenState
    extends ConsumerState<RegisterConsignorVerifyScreen> {
  final _otp = TextEditingController();
  var _busy = false;

  @override
  void dispose() {
    _otp.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    if (widget.phone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone is missing. Please register again.'),
        ),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(authProvider.notifier)
          .verifyOtp(phone: widget.phone, code: _otp.text.trim());
      if (mounted) context.go('/register-consignor-profile');
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
        title: const Text('Verify phone'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Step 2 - enter the OTP sent to your phone.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _otp,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'OTP code'),
          ),
          const SizedBox(height: 24),
          GlPrimaryButton(
            label: 'Verify phone',
            isLoading: _busy,
            onPressed: _verifyOtp,
          ),
        ],
      ),
    );
  }
}
