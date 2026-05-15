import 'package:global_logistics_app/core/extensions/l10n_extension.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';
import 'package:global_logistics_app/core/errors/user_facing_error.dart';
import 'package:global_logistics_app/core/providers/presigned_storage_provider.dart';

String _contentTypeForFileName(String name) {
  final lower = name.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.pdf')) return 'application/pdf';
  return 'application/octet-stream';
}

String _sanitizeFileName(String name) {
  var s = name.trim().replaceAll(RegExp(r'\s+'), '_');
  if (s.isEmpty) s = 'upload';
  if (s.length > 120) s = s.substring(s.length - 120);
  return s;
}

bool _isAllowedExtension(String name, {required bool allowPdf}) {
  final lower = name.toLowerCase();
  final isImage = lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.png') ||
      lower.endsWith('.webp');
  if (allowPdf && lower.endsWith('.pdf')) return true;
  return isImage;
}

/// Picks a file, uploads via presigned URL to [folder], sets [urlController].
///
/// Uses [FileType.any] and filters in Dart (avoids `FileType.custom` native issues).
class PresignedUrlUploadRow extends ConsumerStatefulWidget {
  const PresignedUrlUploadRow({
    super.key,
    required this.urlController,
    required this.folder,
    this.allowPdf = true,
    this.buttonLabel = 'Upload file (image or PDF)',
    this.busyLabel = 'Uploading…',
    this.successMessage = 'File uploaded.',
    this.invalidTypeMessage = 'Please choose a JPG, PNG, WebP, or PDF file.',
    this.borderRadius = 20,
  });

  final TextEditingController urlController;
  final String folder;
  final bool allowPdf;
  final String buttonLabel;
  final String busyLabel;
  final String successMessage;
  final String invalidTypeMessage;
  final double borderRadius;

  @override
  ConsumerState<PresignedUrlUploadRow> createState() =>
      _PresignedUrlUploadRowState();
}

class _PresignedUrlUploadRowState extends ConsumerState<PresignedUrlUploadRow> {
  var _busy = false;

  Future<void> _pickAndUpload() async {
    setState(() => _busy = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );
      if (!mounted) return;
      if (result == null || result.files.isEmpty) return;

      final f = result.files.single;
      if (!_isAllowedExtension(f.name, allowPdf: widget.allowPdf)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(widget.invalidTypeMessage)),
          );
        }
        return;
      }

      final bytes = f.bytes;
      if (bytes == null || bytes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.couldNotReadFile)),
          );
        }
        return;
      }

      final baseName = _sanitizeFileName(f.name);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$baseName';
      final contentType = _contentTypeForFileName(baseName);
      if (contentType == 'application/octet-stream') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(widget.invalidTypeMessage)),
          );
        }
        return;
      }

      final service = ref.read(presignedStorageServiceProvider);
      final url = await service.uploadBytes(
        bytes: bytes,
        fileName: fileName,
        contentType: contentType,
        folder: widget.folder,
      );

      if (!mounted) return;
      widget.urlController.text = url;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.successMessage)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFacingMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: _busy ? null : _pickAndUpload,
          icon: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              : const Icon(Icons.upload_file_rounded, size: 20),
          label: Text(
            _busy ? widget.busyLabel : widget.buttonLabel,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.borderLight, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          ),
        ),
      ),
    );
  }
}

/// Green check + [message] when [controller] has text (after upload); hides raw URL.
class PresignedUploadAttachedHint extends StatelessWidget {
  const PresignedUploadAttachedHint({
    super.key,
    required this.controller,
    required this.message,
  });

  final TextEditingController controller;
  final String message;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.text.trim().isEmpty) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
