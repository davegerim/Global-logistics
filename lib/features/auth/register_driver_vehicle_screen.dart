import 'package:global_logistics_app/core/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';
import 'package:global_logistics_app/core/errors/user_facing_error.dart';
import 'package:global_logistics_app/core/providers/backend_api_provider.dart';
import 'package:global_logistics_app/core/services/presigned_storage_service.dart';
import 'package:global_logistics_app/shared/widgets/gl_primary_button.dart';
import 'package:global_logistics_app/shared/widgets/presigned_url_upload_row.dart';

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
    TextInputType? keyboardType,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceHighlight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight, width: 1.5),
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
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          labelText: label,
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
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
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
          onPressed: () => context.pop(),
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
                  Icons.directions_car_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Vehicle Profile',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Step 4 of 4: Add your vehicle details to start accepting loads.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Form Section
              _buildInput(
                controller: _libriNumber,
                label: context.l10n.libriNumber,
                icon: Icons.pin_outlined,
              ),
              PresignedUrlUploadRow(
                urlController: _libriDocument,
                folder: S3Folder.profile,
                borderRadius: 12,
                buttonLabel: 'Upload libri document (image or PDF)',
                successMessage: 'Libri document uploaded.',
              ),
              PresignedUploadAttachedHint(
                controller: _libriDocument,
                message: context.l10n.libriDocumentAttached,
              ),
              _buildInput(
                controller: _plateNumber,
                label: context.l10n.plateNumber,
                icon: Icons.numbers_rounded,
              ),
              _buildInput(
                controller: _insuranceNumber,
                label: context.l10n.insuranceNumber,
                icon: Icons.security_rounded,
              ),
              PresignedUrlUploadRow(
                urlController: _insuranceDocument,
                folder: S3Folder.profile,
                borderRadius: 12,
                buttonLabel: 'Upload insurance document (image or PDF)',
                successMessage: 'Insurance document uploaded.',
              ),
              PresignedUploadAttachedHint(
                controller: _insuranceDocument,
                message: context.l10n.insuranceDocumentAttached,
              ),
              _buildInput(
                controller: _type,
                label: context.l10n.vehicleType,
                icon: Icons.local_shipping_outlined,
              ),
              _buildInput(
                controller: _details,
                label: context.l10n.details,
                icon: Icons.info_outline_rounded,
              ),
              PresignedUrlUploadRow(
                urlController: _photo,
                folder: S3Folder.profile,
                allowPdf: false,
                borderRadius: 12,
                buttonLabel: 'Upload vehicle photo (JPG, PNG, or WebP)',
                invalidTypeMessage:
                    'Please choose a JPG, PNG, or WebP image for the vehicle photo.',
                successMessage: 'Vehicle photo uploaded.',
              ),
              PresignedUploadAttachedHint(
                controller: _photo,
                message: context.l10n.vehiclePhotoAttached,
              ),
              const SizedBox(height: 24),

              // Action Button
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
