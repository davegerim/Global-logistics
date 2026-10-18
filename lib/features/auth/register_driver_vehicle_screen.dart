import 'package:global_logistics_app/core/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';
import 'package:global_logistics_app/core/errors/user_facing_error.dart';
import 'package:global_logistics_app/core/providers/auth_provider.dart';
import 'package:global_logistics_app/core/providers/backend_api_provider.dart';
import 'package:global_logistics_app/core/utils/registration_flow_utils.dart';
import 'package:global_logistics_app/core/utils/form_field_utils.dart';
import 'package:global_logistics_app/data/schemas/driver_registration_schema.dart';
import 'package:global_logistics_app/features/auth/widgets/driver_registration_field_list.dart';
import 'package:global_logistics_app/shared/widgets/gl_primary_button.dart';

class RegisterDriverVehicleScreen extends ConsumerStatefulWidget {
  const RegisterDriverVehicleScreen({super.key});

  @override
  ConsumerState<RegisterDriverVehicleScreen> createState() =>
      _RegisterDriverVehicleScreenState();
}

class _RegisterDriverVehicleScreenState
    extends ConsumerState<RegisterDriverVehicleScreen> {
  late final Map<String, TextEditingController> _controllers;
  var _busy = false;
  final Map<String, String?> _fieldErrors = {};

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final field in DriverRegistrationSchema.vehicleFields)
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
      fields: DriverRegistrationSchema.vehicleFields,
      controllers: _controllers,
      labelFor: (field) {
        if (field.type != DriverRegistrationFieldType.text) {
          return DriverRegistrationSchema.uploadButtonLabel(l10n, field);
        }
        return DriverRegistrationSchema.label(l10n, field);
      },
      fieldIsRequired: l10n.fieldIsRequired,
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

  Future<void> _createVehicleProfile() async {
    if (!_validateForm()) return;
    setState(() => _busy = true);
    try {
      final values = {
        for (final entry in _controllers.entries)
          entry.key: entry.value.text,
      };
      final payload = DriverRegistrationSchema.buildPayload(
        DriverRegistrationSchema.vehicleFields,
        values,
      );
      await ref.read(backendApiProvider).vehiclesCreate(payload);
      await ref.read(authProvider.notifier).refreshProfile();
      if (!mounted) return;
      final auth = ref.read(authProvider);
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
    required String fieldKey,
    bool isPassword = false,
    TextInputType? keyboardType,
    bool required = true,
    String? errorText,
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
        obscureText: isPassword,
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
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(
                RegistrationFlowUtils.previousRegistrationStep(
                  ref.read(authProvider),
                ),
              );
            }
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
                  Icons.directions_car_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.vehicleProfileTitle,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.driverRegStep4,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              ...buildDriverRegistrationFields(
                context: context,
                fields: DriverRegistrationSchema.vehicleFields,
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
                  label: context.l10n.completeRegistration,
                  isLoading: _busy,
                  onPressed: _createVehicleProfile,
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
