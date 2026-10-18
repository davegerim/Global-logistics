import 'package:flutter/material.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';
import 'package:global_logistics_app/data/utils/role_profile_utils.dart';

/// Renders an uploaded document URL as an image preview (never as raw link text).
class NetworkDocumentPreview extends StatelessWidget {
  const NetworkDocumentPreview({
    super.key,
    required this.url,
    this.aspectRatio = 16 / 10,
    this.borderRadius = 16,
    this.onTap,
  });

  final String url;
  final double aspectRatio;
  final double borderRadius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return const SizedBox.shrink();

    final child = RoleProfileUtils.looksLikeImageUrl(trimmed)
        ? _ImagePreview(url: trimmed)
        : _DocumentTile(url: trimmed);

    final preview = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: AspectRatio(aspectRatio: aspectRatio, child: child),
    );

    if (onTap == null) return preview;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: preview,
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => const _BrokenPreview(),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final isPdf = RoleProfileUtils.looksLikePdfUrl(url);
    return Container(
      color: AppColors.surfaceHighlight,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPdf ? Icons.picture_as_pdf_rounded : Icons.insert_drive_file_rounded,
              size: 48,
              color: AppColors.primary,
            ),
            const SizedBox(height: 8),
            Text(
              isPdf ? 'PDF document' : 'Document',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrokenPreview extends StatelessWidget {
  const _BrokenPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceHighlight,
      child: const Center(
        child: Icon(
          Icons.broken_image_outlined,
          size: 48,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}
