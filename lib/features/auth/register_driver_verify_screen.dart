import 'package:global_logistics_app/core/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';
import 'package:global_logistics_app/core/errors/user_facing_error.dart';
import 'package:global_logistics_app/core/providers/auth_provider.dart';
import 'package:global_logistics_app/core/utils/form_field_utils.dart';
import 'package:global_logistics_app/core/utils/registration_flow_utils.dart';
import 'package:global_logistics_app/shared/widgets/gl_primary_button.dart';

class RegisterDriverVerifyScreen extends ConsumerStatefulWidget {
  const RegisterDriverVerifyScreen({super.key, required this.phone});

  final String phone;

  @override
  ConsumerState<RegisterDriverVerifyScreen> createState() =>
      _RegisterDriverVerifyScreenState();
}

class _RegisterDriverVerifyScreenState
    extends ConsumerState<RegisterDriverVerifyScreen> {
  final _otp = TextEditingController();
  var _busy = false;
  var _resending = false;
  var _autoResendDone = false;
  String? _otpError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAutoResendOtp());
  }

  Future<void> _maybeAutoResendOtp() async {
    if (_autoResendDone || !mounted) return;
    final shouldResend =
        GoRouterState.of(context).uri.queryParameters['resend'] == '1';
    if (!shouldResend) return;
    _autoResendDone = true;
    await _resendOtp(showFeedback: false);
  }

  Future<void> _resendOtp({bool showFeedback = true}) async {
    if (widget.phone.trim().isEmpty) {
      if (showFeedback && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.phoneIsMissing)),
        );
      }
      return;
    }
    if (_resending) return;
    setState(() => _resending = true);
    try {
      await ref.read(authProvider.notifier).sendOtp(widget.phone.trim());
      if (!mounted || !showFeedback) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.otpResent)),
      );
    } catch (e) {
      if (showFeedback && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFacingMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  void dispose() {
    _otp.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    if (widget.phone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.phoneIsMissing),
        ),
      );
      return;
    }
    if (isFormFieldEmpty(_otp.text)) {
      setState(() => _otpError = context.l10n.fieldIsRequired(context.l10n.otpCode));
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(authProvider.notifier)
          .verifyOtp(phone: widget.phone, code: _otp.text.trim());
      if (!mounted) return;
      final auth = ref.read(authProvider);
      if (!auth.isAuthenticated) {
        final message = auth.errorMessage ?? context.l10n.phoneIsMissing;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        return;
      }
      context.go(RegistrationFlowUtils.postAuthRoute(auth));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(userFacingMessage(e))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? errorText,
    TextInputType? keyboardType,
    bool required = true,
    VoidCallback? onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceHighlight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: formContainerBorderColor(
            errorText: errorText,
            normal: AppColors.borderLight,
          ),
          width: formContainerBorderWidth(
            errorText: errorText,
            normal: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: (_) => onChanged?.call(),
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          fontSize: 16,
          letterSpacing: 2.0,
        ),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          labelText: formFieldLabel(label, required: required),
          errorText: errorText,
          errorStyle: const TextStyle(
            color: AppColors.error,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          labelStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
            fontSize: 13,
            letterSpacing: 0,
          ),
          prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: errorText != null ? AppColors.error : AppColors.primary,
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWarm,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () async {
            if (context.canPop()) {
              context.pop();
              return;
            }
            final auth = ref.read(authProvider);
            final entry = RegistrationFlowUtils.registrationEntryRoute(auth);
            // Pending OTP redirect locks the user on this screen until cleared.
            if (auth.needsPhoneVerification) {
              await ref.read(authProvider.notifier).logout();
              if (!context.mounted) return;
            }
            context.go(entry);
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.message_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.verifyPhone,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.driverRegStep2,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Form Section
              _buildInput(
                controller: _otp,
                label: context.l10n.otpCode,
                icon: Icons.password_rounded,
                keyboardType: TextInputType.number,
                errorText: _otpError,
                onChanged: () {
                  if (_otpError != null) setState(() => _otpError = null);
                },
              ),
              const SizedBox(height: 24),

              // Action Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: GlPrimaryButton(
                  label: context.l10n.verifyPhone,
                  isLoading: _busy,
                  onPressed: _verifyOtp,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: (_busy || _resending) ? null : () => _resendOtp(),
                  child: _resending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text.rich(
                          TextSpan(
                            text: '${context.l10n.didntReceiveOtp} ',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            children: [
                              TextSpan(
                                text: context.l10n.resendOtp,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
