import 'package:global_logistics_app/core/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';
import 'package:global_logistics_app/core/services/presigned_storage_service.dart';
import 'package:global_logistics_app/core/utils/form_field_utils.dart';
import 'package:global_logistics_app/data/schemas/driver_registration_schema.dart';
import 'package:global_logistics_app/shared/widgets/presigned_url_upload_row.dart';

typedef DriverRegistrationTextInputBuilder =
    Widget Function({
      required TextEditingController controller,
      required String label,
      required IconData icon,
      required String fieldKey,
      bool isPassword,
      TextInputType? keyboardType,
      bool required,
      String? errorText,
      VoidCallback? onChanged,
    });

List<Widget> buildDriverRegistrationFields({
  required BuildContext context,
  required List<DriverRegistrationField> fields,
  required Map<String, TextEditingController> controllers,
  required Map<String, String?> fieldErrors,
  required void Function(String apiKey) onFieldChanged,
  required DriverRegistrationTextInputBuilder buildTextInput,
}) {
  final l10n = context.l10n;
  final widgets = <Widget>[];

  for (final field in fields) {
    final controller = controllers[field.apiKey]!;
    final errorText = fieldErrors[field.apiKey];
    final label = DriverRegistrationSchema.label(l10n, field);

    switch (field.type) {
      case DriverRegistrationFieldType.text:
        widgets.add(
          buildTextInput(
            controller: controller,
            label: label,
            icon: field.icon,
            fieldKey: field.apiKey,
            isPassword: field.apiKey == 'password' ||
                field.apiKey == 'confirmPassword',
            keyboardType: field.keyboardType,
            required: field.required,
            errorText: errorText,
            onChanged: () => onFieldChanged(field.apiKey),
          ),
        );
      case DriverRegistrationFieldType.documentUpload:
      case DriverRegistrationFieldType.photoUpload:
        final invalidTypeMessage =
            DriverRegistrationSchema.uploadInvalidTypeMessage(l10n, field);
        widgets.add(
          PresignedUrlUploadRow(
            urlController: controller,
            folder: S3Folder.profile,
            allowPdf: field.allowPdf,
            borderRadius: 12,
            buttonLabel: DriverRegistrationSchema.uploadButtonLabel(
              l10n,
              field,
            ),
            invalidTypeMessage: invalidTypeMessage ??
                'Please choose a JPG, PNG, WebP, or PDF file.',
            successMessage: DriverRegistrationSchema.uploadSuccessMessage(
              l10n,
              field,
            ),
          ),
        );
        if (errorText != null) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 4),
              child: Text(
                errorText,
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }
        widgets.add(
          PresignedUploadAttachedHint(
            controller: controller,
            message: DriverRegistrationSchema.uploadAttachedHint(l10n, field),
          ),
        );
    }
  }

  return widgets;
}

Map<String, String?> validateDriverRegistrationFields({
  required List<DriverRegistrationField> fields,
  required Map<String, TextEditingController> controllers,
  required String Function(DriverRegistrationField field) labelFor,
  required String Function(String label) fieldIsRequired,
  String? Function(DriverRegistrationField field, String value)? validateValue,
}) {
  final errors = <String, String?>{};

  for (final field in fields) {
    final value = controllers[field.apiKey]?.text ?? '';

    if (field.required && isFormFieldEmpty(value)) {
      errors[field.apiKey] = fieldIsRequired(labelFor(field));
      continue;
    }

    final customError = validateValue?.call(field, value);
    if (customError != null && customError.isNotEmpty) {
      errors[field.apiKey] = customError;
    }
  }

  return errors;
}
