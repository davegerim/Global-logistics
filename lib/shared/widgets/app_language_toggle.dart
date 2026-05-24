import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';
import 'package:global_logistics_app/core/extensions/l10n_extension.dart';
import 'package:global_logistics_app/core/providers/locale_provider.dart';

/// Compact language dropdown for auth and onboarding headers.
class AppLanguageToggle extends ConsumerWidget {
  const AppLanguageToggle({super.key, this.lightOnDark = false});

  /// Use on dark backgrounds (e.g. onboarding).
  final bool lightOnDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final code =
        ref.watch(localeProvider)?.languageCode ??
        Localizations.localeOf(context).languageCode;
    final isAm = code == 'am';
    final shortLabel = isAm ? 'አማ' : 'EN';

    return PopupMenuButton<String>(
      onSelected: (v) => ref.read(localeProvider.notifier).setLocale(v),
      offset: const Offset(0, 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      itemBuilder: (ctx) => [
        PopupMenuItem(
          value: 'en',
          child: _MenuRow(
            label: context.l10n.englishUs,
            selected: !isAm,
          ),
        ),
        PopupMenuItem(
          value: 'am',
          child: _MenuRow(
            label: context.l10n.amharicLanguage,
            selected: isAm,
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: lightOnDark
              ? Colors.white.withValues(alpha: 0.15)
              : const Color(0xFFE9F1F1),
          borderRadius: BorderRadius.circular(14),
          border: lightOnDark
              ? null
              : Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.language_rounded,
              size: 18,
              color: lightOnDark ? Colors.white : AppColors.textPrimary,
            ),
            const SizedBox(width: 6),
            Text(
              shortLabel,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: lightOnDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: lightOnDark
                  ? Colors.white.withValues(alpha: 0.85)
                  : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 22,
          child: selected
              ? const Icon(Icons.check_rounded, size: 18, color: AppColors.primary)
              : null,
        ),
        Text(label),
      ],
    );
  }
}
