import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';
import 'package:global_logistics_app/core/providers/auth_provider.dart';
import 'package:global_logistics_app/core/providers/backend_api_provider.dart';
import 'package:global_logistics_app/shared/widgets/gl_primary_button.dart';

/// Step 1 only: `POST /auth/register` -> `POST /auth/otp/send`.
class RegisterConsignorScreen extends ConsumerStatefulWidget {
  const RegisterConsignorScreen({super.key});

  @override
  ConsumerState<RegisterConsignorScreen> createState() =>
      _RegisterConsignorScreenState();
}

class _RegisterConsignorScreenState
    extends ConsumerState<RegisterConsignorScreen> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _registerAccount() async {
    if (_password.text != _confirm.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match.')));
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(authProvider.notifier)
          .register(
            firstName: _firstName.text.trim(),
            lastName: _lastName.text.trim(),
            phoneNumber: _phone.text.trim(),
            role: 'CONSIGNOR',
            password: _password.text,
            confirmPassword: _confirm.text,
          );
      try {
        await ref.read(backendApiProvider).authOtpSend(_phone.text.trim());
      } on DioException catch (e) {
        // Registration succeeded; a resend throttle should not block OTP entry.
        if (e.response?.statusCode != 429) rethrow;
      }
      if (mounted) {
        context.push(
          '/register-consignor-verify',
          extra: {'phone': _phone.text.trim()},
        );
      }
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
        title: const Text('Consignor registration'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Step 1 - create your consignor account.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _firstName,
            decoration: const InputDecoration(labelText: 'First name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _lastName,
            decoration: const InputDecoration(labelText: 'Last name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Phone'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirm,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Confirm password'),
          ),
          const SizedBox(height: 24),
          GlPrimaryButton(
            label: 'Continue & send OTP',
            isLoading: _busy,
            onPressed: _registerAccount,
          ),
        ],
      ),
    );
  }
}
