import 'package:flutter/material.dart';
import 'package:global_logistics_app/l10n/app_localizations.dart';

/// Field metadata mirrored from the live OpenAPI registration schemas:
/// `RegisterRequest`, `CreateDriverProfileRequest`, `CreateVehicleRequest`.
enum DriverRegistrationFieldType { text, documentUpload, photoUpload }

class DriverRegistrationField {
  const DriverRegistrationField({
    required this.apiKey,
    required this.type,
    required this.required,
    required this.icon,
    this.keyboardType,
    this.allowPdf = true,
    this.pattern,
  });

  final String apiKey;
  final DriverRegistrationFieldType type;
  final bool required;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool allowPdf;
  final String? pattern;
}

abstract final class DriverRegistrationSchema {
  /// `RegisterRequest` — all fields required; phone must match `^(09|07)\d{8}$`.
  static const List<DriverRegistrationField> accountFields = [
    DriverRegistrationField(
      apiKey: 'firstName',
      type: DriverRegistrationFieldType.text,
      required: true,
      icon: Icons.person_outline_rounded,
    ),
    DriverRegistrationField(
      apiKey: 'lastName',
      type: DriverRegistrationFieldType.text,
      required: true,
      icon: Icons.person_outline_rounded,
    ),
    DriverRegistrationField(
      apiKey: 'phoneNumber',
      type: DriverRegistrationFieldType.text,
      required: true,
      icon: Icons.phone_outlined,
      keyboardType: TextInputType.phone,
      pattern: r'^(09|07)\d{8}$',
    ),
    DriverRegistrationField(
      apiKey: 'password',
      type: DriverRegistrationFieldType.text,
      required: true,
      icon: Icons.lock_outline_rounded,
    ),
    DriverRegistrationField(
      apiKey: 'confirmPassword',
      type: DriverRegistrationFieldType.text,
      required: true,
      icon: Icons.lock_outline_rounded,
    ),
  ];

  /// `CreateDriverProfileRequest` — licence fields required; rest optional.
  static const List<DriverRegistrationField> profileFields = [
    DriverRegistrationField(
      apiKey: 'profilePic',
      type: DriverRegistrationFieldType.photoUpload,
      required: false,
      icon: Icons.account_circle_outlined,
      allowPdf: false,
    ),
    DriverRegistrationField(
      apiKey: 'nationalId',
      type: DriverRegistrationFieldType.text,
      required: false,
      icon: Icons.badge_outlined,
    ),
    DriverRegistrationField(
      apiKey: 'nationalIdImg',
      type: DriverRegistrationFieldType.documentUpload,
      required: false,
      icon: Icons.image_outlined,
    ),
    DriverRegistrationField(
      apiKey: 'licenceNumber',
      type: DriverRegistrationFieldType.text,
      required: true,
      icon: Icons.pin_outlined,
    ),
    DriverRegistrationField(
      apiKey: 'licenceDocument',
      type: DriverRegistrationFieldType.documentUpload,
      required: true,
      icon: Icons.description_outlined,
    ),
    DriverRegistrationField(
      apiKey: 'preferredLanes',
      type: DriverRegistrationFieldType.text,
      required: false,
      icon: Icons.route_outlined,
    ),
  ];

  /// `CreateVehicleRequest` — libreDocument, plateNumber, type required.
  static const List<DriverRegistrationField> vehicleFields = [
    DriverRegistrationField(
      apiKey: 'libreDocument',
      type: DriverRegistrationFieldType.documentUpload,
      required: true,
      icon: Icons.description_outlined,
    ),
    DriverRegistrationField(
      apiKey: 'libreDocumentSec',
      type: DriverRegistrationFieldType.documentUpload,
      required: false,
      icon: Icons.description_outlined,
    ),
    DriverRegistrationField(
      apiKey: 'insuranceDoc',
      type: DriverRegistrationFieldType.documentUpload,
      required: false,
      icon: Icons.description_outlined,
    ),
    DriverRegistrationField(
      apiKey: 'plateNumber',
      type: DriverRegistrationFieldType.text,
      required: true,
      icon: Icons.numbers_rounded,
    ),
    DriverRegistrationField(
      apiKey: 'type',
      type: DriverRegistrationFieldType.text,
      required: true,
      icon: Icons.local_shipping_outlined,
    ),
    DriverRegistrationField(
      apiKey: 'details',
      type: DriverRegistrationFieldType.text,
      required: false,
      icon: Icons.info_outline_rounded,
    ),
    DriverRegistrationField(
      apiKey: 'photo',
      type: DriverRegistrationFieldType.photoUpload,
      required: false,
      icon: Icons.photo_camera_outlined,
      allowPdf: false,
    ),
  ];

  static String label(AppLocalizations l10n, DriverRegistrationField field) {
    return switch (field.apiKey) {
      'firstName' => l10n.firstName,
      'lastName' => l10n.lastName,
      'phoneNumber' => l10n.phoneNumber,
      'password' => l10n.password,
      'confirmPassword' => l10n.confirmPassword,
      'profilePic' => l10n.profilePic,
      'nationalId' => l10n.nationalId,
      'nationalIdImg' => l10n.nationalIdImg,
      'licenceNumber' => l10n.licenceNumber,
      'licenceDocument' => l10n.licenceDocument,
      'preferredLanes' => l10n.preferredLanes,
      'libreDocument' => l10n.libreDocument,
      'libreDocumentSec' => l10n.libreDocumentSec,
      'insuranceDoc' => l10n.insuranceDocument,
      'plateNumber' => l10n.plateNumber,
      'type' => l10n.typeLabel,
      'details' => l10n.details,
      'photo' => l10n.photoTitle,
      _ => field.apiKey,
    };
  }

  static String uploadButtonLabel(
    AppLocalizations l10n,
    DriverRegistrationField field,
  ) {
    return switch (field.apiKey) {
      'profilePic' => l10n.uploadProfilePic,
      'nationalIdImg' => l10n.uploadNationalIdImg,
      'licenceDocument' => l10n.uploadLicenceDocument,
      'libreDocument' => l10n.uploadLibreDocument,
      'libreDocumentSec' => l10n.uploadLibreDocumentSec,
      'insuranceDoc' => l10n.uploadInsuranceDocument,
      'photo' => l10n.uploadPhoto,
      _ => field.apiKey,
    };
  }

  static String uploadSuccessMessage(
    AppLocalizations l10n,
    DriverRegistrationField field,
  ) {
    return switch (field.apiKey) {
      'profilePic' => l10n.profilePicUploaded,
      'nationalIdImg' => l10n.nationalIdImgUploaded,
      'licenceDocument' => l10n.licenceDocumentUploaded,
      'libreDocument' => l10n.libreDocumentUploaded,
      'libreDocumentSec' => l10n.libreDocumentSecUploaded,
      'insuranceDoc' => l10n.insuranceDocumentUploaded,
      'photo' => l10n.photoUploaded,
      _ => field.apiKey,
    };
  }

  static String uploadAttachedHint(
    AppLocalizations l10n,
    DriverRegistrationField field,
  ) {
    return switch (field.apiKey) {
      'profilePic' => l10n.profilePicAttached,
      'nationalIdImg' => l10n.nationalIdImgAttached,
      'licenceDocument' => l10n.licenceDocumentAttached,
      'libreDocument' => l10n.libreDocumentAttached,
      'libreDocumentSec' => l10n.libreDocumentSecAttached,
      'insuranceDoc' => l10n.insuranceDocumentAttached,
      'photo' => l10n.photoAttached,
      _ => field.apiKey,
    };
  }

  static String? uploadInvalidTypeMessage(
    AppLocalizations l10n,
    DriverRegistrationField field,
  ) {
    if (field.apiKey == 'photo') return l10n.vehiclePhotoInvalidType;
    return null;
  }

  static Map<String, dynamic> buildPayload(
    List<DriverRegistrationField> fields,
    Map<String, String> values,
  ) {
    final payload = <String, dynamic>{};
    for (final field in fields) {
      final value = values[field.apiKey]?.trim() ?? '';
      if (value.isEmpty) continue;
      payload[field.apiKey] = value;
    }
    return payload;
  }
}
