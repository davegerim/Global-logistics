import 'package:flutter/material.dart';
import 'package:global_logistics_app/core/services/presigned_storage_service.dart';
import 'package:global_logistics_app/shared/widgets/presigned_url_upload_row.dart';

/// Uploads a payment receipt to `shipment_payments` and fills [slipController].
class ShipmentReceiptUploadRow extends StatelessWidget {
  const ShipmentReceiptUploadRow({super.key, required this.slipController});

  final TextEditingController slipController;

  @override
  Widget build(BuildContext context) {
    return PresignedUrlUploadRow(
      urlController: slipController,
      folder: S3Folder.shipmentPayments,
      allowPdf: true,
      buttonLabel: 'Upload receipt (image or PDF)',
      successMessage: 'Receipt uploaded.',
    );
  }
}
