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
                  Icons.badge_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.personalProfileTitle,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.driverRegStep3,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Form Section
              _buildInput(
                controller: _licenceNumber,
                label: context.l10n.licenceNumber,
                icon: Icons.pin_outlined,
              ),
              PresignedUrlUploadRow(
                urlController: _licenceDocument,
                folder: S3Folder.profile,
                borderRadius: 12,
                buttonLabel: context.l10n.uploadLicenceDocument,
                successMessage: context.l10n.licenceDocumentUploaded,
              ),
              PresignedUploadAttachedHint(
                controller: _licenceDocument,
                message: context.l10n.licenceDocumentAttached,
              ),
              _buildInput(
                controller: _preferredLanes,
                label: context.l10n.preferredLanesOptional,
                icon: Icons.route_outlined,
              ),
              const SizedBox(height: 24),

              // Action Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: GlPrimaryButton(
                  label: context.l10n.saveProfileAndContinue,
                  isLoading: _busy,
                  onPressed: _createDriverProfile,
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
