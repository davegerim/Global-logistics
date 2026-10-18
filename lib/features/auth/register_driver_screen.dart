import 'package:global_logistics_app/core/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';
import 'package:global_logistics_app/core/errors/user_facing_error.dart';
import 'package:global_logistics_app/core/providers/auth_provider.dart';
import 'package:global_logistics_app/core/utils/form_field_utils.dart';
import 'package:global_logistics_app/data/schemas/driver_registration_schema.dart';
import 'package:global_logistics_app/features/auth/widgets/driver_registration_field_list.dart';
import 'package:global_logistics_app/shared/widgets/gl_primary_button.dart';

/// Step 1 only: `POST /auth/register` (server sends OTP; no separate send call).
class RegisterDriverScreen extends ConsumerStatefulWidget {
  const RegisterDriverScreen({super.key});

  @override
  ConsumerState<RegisterDriverScreen> createState() =>
      _RegisterDriverScreenState();
}

class _RegisterDriverScreenState extends ConsumerState<RegisterDriverScreen> {
  late final Map<String, TextEditingController> _controllers;
  bool _busy = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  final Map<String, String?> _fieldErrors = {};

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final field in DriverRegistrationSchema.accountFields)
        field.apiKey: TextEditingController(),
    };
  }

  void _clearFieldError(String key) {
    if (_fieldErrors.containsKey(key)) {
      setState(() => _fieldErrors.remove(key));
    }
  }

  bool _validateForm() {
    final l10n = context.l10n;
    final errors = validateDriverRegistrationFields(
      fields: DriverRegistrationSchema.accountFields,
      controllers: _controllers,
      labelFor: (field) => DriverRegistrationSchema.label(l10n, field),
      fieldIsRequired: l10n.fieldIsRequired,
      validateValue: (field, value) {
        if (field.apiKey == 'phoneNumber' &&
            value.trim().isNotEmpty &&
            !isValidRegistrationPhone(value)) {
          return l10n.enterValidRegistrationPhone;
        }
        if ((field.apiKey == 'password' || field.apiKey == 'confirmPassword') &&
            value.isNotEmpty) {
          final lengthError = passwordLengthValidationError(
            value,
            invalidLengthMessage: l10n.passwordMustBeBetweenCharacters,
          );
          if (lengthError != null) return lengthError;
        }
        if (field.apiKey == 'confirmPassword' &&
            value != _controllers['password']!.text) {
          return l10n.passwordsDoNotMatch;
        }
        return null;
      },
    );

    setState(() {
      _fieldErrors
        ..clear()
        ..addAll(errors);
    });
    return errors.isEmpty;
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _registerAccount() async {
    if (!_validateForm()) return;
    setState(() => _busy = true);
    try {
      await ref.read(authProvider.notifier).register(
            firstName: _controllers['firstName']!.text.trim(),
            lastName: _controllers['lastName']!.text.trim(),
            phoneNumber: _controllers['phoneNumber']!.text.trim(),
            role: 'DRIVER',
            password: _controllers['password']!.text,
            confirmPassword: _controllers['confirmPassword']!.text,
          );
      if (mounted) {
        context.push(
          '/register-driver-verify',
          extra: {'phone': _controllers['phoneNumber']!.text.trim()},
        );
      }
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
    required String fieldKey,
    bool isPassword = false,
    TextInputType? keyboardType,
    bool required = true,
    String? errorText,
    VoidCallback? onChanged,
  }) {
    final obscure = isPassword
        ? (fieldKey == 'confirmPassword'
            ? _obscureConfirmPassword
            : _obscurePassword)
        : false;

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
        obscureText: obscure,
        keyboardType: keyboardType,
        onChanged: (_) => onChanged?.call(),
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
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
          ),
          prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
          suffixIcon: isPassword
              ? IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    setState(() {
                      if (fieldKey == 'confirmPassword') {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      } else {
                        _obscurePassword = !_obscurePassword;
                      }
                    });
                  },
                  icon: Icon(
                    obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                )
              : null,
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
            // VERIFIED users are redirected away from /login unless logged out.
            if (ref.read(authProvider).isAuthenticated) {
              await ref.read(authProvider.notifier).logout();
              if (!context.mounted) return;
            }
            context.go('/login');
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
                  Icons.local_shipping_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.driverRegistrationTitle,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.driverRegStep1,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              ...buildDriverRegistrationFields(
                context: context,
                fields: DriverRegistrationSchema.accountFields,
                controllers: _controllers,
                fieldErrors: _fieldErrors,
                onFieldChanged: _clearFieldError,
                buildTextInput: _buildInput,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: GlPrimaryButton(
                  label: context.l10n.continueAndSendOtp,
                  isLoading: _busy,
                  onPressed: _registerAccount,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
