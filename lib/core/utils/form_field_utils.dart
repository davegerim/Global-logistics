import 'package:flutter/material.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';

/// Appends " *" when [required] and the label is not already marked.
String formFieldLabel(String label, {bool required = false}) {
  if (!required) return label;
  final trimmed = label.trim();
  if (trimmed.endsWith('*')) return label;
  return '$label *';
}

bool isFormFieldEmpty(String? value) =>
    value == null || value.trim().isEmpty;

bool isPositiveNumber(String? value) {
  final parsed = double.tryParse(value?.trim() ?? '');
  return parsed != null && parsed > 0;
}

bool isValidTenDigitPhone(String value) =>
    RegExp(r'^\d{10}$').hasMatch(value.trim());

/// Matches `RegisterRequest.phoneNumber` pattern from OpenAPI.
bool isValidRegistrationPhone(String value) =>
    RegExp(r'^(09|07)\d{8}$').hasMatch(value.trim());

/// Mirrors `RegisterRequest.password` / `ResetPasswordRequest.newPassword`.
const int kPasswordMinLength = 6;
const int kPasswordMaxLength = 8;

bool isValidPasswordLength(String value) {
  final length = value.length;
  return length >= kPasswordMinLength && length <= kPasswordMaxLength;
}

String? passwordLengthValidationError(
  String value, {
  required String Function(int min, int max) invalidLengthMessage,
}) {
  if (isValidPasswordLength(value)) return null;
  return invalidLengthMessage(kPasswordMinLength, kPasswordMaxLength);
}

Color formContainerBorderColor({
  required String? errorText,
  Color normal = AppColors.borderLight,
}) {
  if (errorText != null && errorText.isNotEmpty) return AppColors.error;
  return normal;
}

double formContainerBorderWidth({
  required String? errorText,
  double normal = 1.0,
  double error = 1.5,
}) {
  if (errorText != null && errorText.isNotEmpty) return error;
  return normal;
}
