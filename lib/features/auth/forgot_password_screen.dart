import 'package:global_logistics_app/core/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';
import 'package:global_logistics_app/core/errors/user_facing_error.dart';
import 'package:global_logistics_app/core/providers/backend_api_provider.dart';
import 'package:global_logistics_app/core/utils/form_field_utils.dart';
import 'package:global_logistics_app/shared/widgets/gl_primary_button.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialPhone = ''});

  final String initialPhone;

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  late final TextEditingController _phone;
  final _otp = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _sendingOtp = false;
  bool _resettingPassword = false;
  String? _phoneError;
  String? _otpError;
  String? _newPasswordError;
  String? _confirmPasswordError;

  @override
  void initState() {
    super.initState();
    _phone = TextEditingController(text: widget.initialPhone);
  }

  @override
  void dispose() {
    _phone.dispose();
    _otp.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = _phone.text.trim();
    if (phone.isEmpty) {
      setState(() {
        _phoneError = context.l10n.fieldIsRequired(context.l10n.phoneLabel);
      });
      return;
    }
    setState(() => _phoneError = null);
    setState(() => _sendingOtp = true);
    try {
      await ref.read(backendApiProvider).authForgetPassword(phone);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.otpSentCheckPhone)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(userFacingMessage(e))));
    } finally {
      if (mounted) setState(() => _sendingOtp = false);
    }
  }

  Future<void> _resetPassword() async {
    final phone = _phone.text.trim();
    final otp = _otp.text.trim();
    final newPassword = _newPassword.text;
    final confirmPassword = _confirmPassword.text;

    final phoneError = phone.isEmpty
        ? context.l10n.fieldIsRequired(context.l10n.phoneLabel)
        : null;
    final otpError = otp.isEmpty
        ? context.l10n.fieldIsRequired(context.l10n.otpCodeLabel)
        : null;
    final newPasswordError = newPassword.isEmpty
        ? context.l10n.fieldIsRequired(context.l10n.newPasswordLabel)
        : null;
    String? confirmPasswordError;
    if (confirmPassword.isEmpty) {
      confirmPasswordError =
          context.l10n.fieldIsRequired(context.l10n.confirmNewPasswordLabel);
    } else if (newPassword != confirmPassword) {
      confirmPasswordError = context.l10n.passwordsDoNotMatch;
    }

    if (phoneError != null ||
        otpError != null ||
        newPasswordError != null ||
        confirmPasswordError != null) {
      setState(() {
        _phoneError = phoneError;
        _otpError = otpError;
        _newPasswordError = newPasswordError;
        _confirmPasswordError = confirmPasswordError;
      });
      return;
    }

    setState(() => _resettingPassword = true);
    try {
      await ref.read(backendApiProvider).authResetPassword(
            phone: phone,
            otpCode: otp,
            newPassword: newPassword,
            confirmPassword: confirmPassword,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.passwordResetSuccessful)),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(userFacingMessage(e))));
    } finally {
      if (mounted) setState(() => _resettingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -70,
            left: -50,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: 0.08),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton.filledTonal(
                      onPressed: () => context.pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        foregroundColor: AppColors.textPrimary,
                      ),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    context.l10n.forgotPasswordTitle,
                    textAlign: TextAlign.center,
                    style: t.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    context.l10n.forgotPasswordSubtitle,
                    textAlign: TextAlign.center,
                    style: t.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 26),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: AppColors.borderLight),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 32,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          onChanged: (_) {
                            if (_phoneError != null) {
                              setState(() => _phoneError = null);
                            }
                          },
                          decoration: InputDecoration(
                            labelText: formFieldLabel(
                              context.l10n.phoneLabel,
                              required: true,
                            ),
                            errorText: _phoneError,
                            prefixIcon: const Icon(Icons.phone_outlined),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: _sendingOtp || _resettingPassword ? null : _sendOtp,
                            icon: _sendingOtp
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.sms_outlined),
                            label: Text(context.l10n.sendOtp),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _otp,
                          keyboardType: TextInputType.number,
                          onChanged: (_) {
                            if (_otpError != null) {
                              setState(() => _otpError = null);
                            }
                          },
                          decoration: InputDecoration(
                            labelText: formFieldLabel(
                              context.l10n.otpCodeLabel,
                              required: true,
                            ),
                            errorText: _otpError,
                            prefixIcon: const Icon(Icons.lock_clock_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _newPassword,
                          obscureText: _obscureNew,
                          onChanged: (_) {
                            if (_newPasswordError != null) {
                              setState(() => _newPasswordError = null);
                            }
                          },
                          decoration: InputDecoration(
                            labelText: formFieldLabel(
                              context.l10n.newPasswordLabel,
                              required: true,
                            ),
                            errorText: _newPasswordError,
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => _obscureNew = !_obscureNew),
                              icon: Icon(
                                _obscureNew
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _confirmPassword,
                          obscureText: _obscureConfirm,
                          onChanged: (_) {
                            if (_confirmPasswordError != null) {
                              setState(() => _confirmPasswordError = null);
                            }
                          },
                          decoration: InputDecoration(
                            labelText: formFieldLabel(
                              context.l10n.confirmNewPasswordLabel,
                              required: true,
                            ),
                            errorText: _confirmPasswordError,
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        GlPrimaryButton(
                          label: context.l10n.resetPassword,
                          isLoading: _resettingPassword,
                          onPressed: _sendingOtp || _resettingPassword ? null : _resetPassword,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
