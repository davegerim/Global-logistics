import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';
import 'package:global_logistics_app/core/extensions/l10n_extension.dart';
import 'package:global_logistics_app/core/providers/locale_provider.dart';

/// Shows the app language picker bottom sheet (English / Amharic).
Future<void> showAppLanguagePickerSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  final savedCode = ref.read(localeProvider)?.languageCode;
  final deviceCode = Localizations.localeOf(context).languageCode;
  final initialCode = savedCode ?? deviceCode;
  var selectedCode = initialCode == 'am' ? 'am' : 'en';

  await showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => StatefulBuilder(
      builder: (ctx, setSheetState) {
        return Container(
          margin: EdgeInsets.only(top: MediaQuery.paddingOf(ctx).top + 40),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 32,
            bottom:
                MediaQuery.viewInsetsOf(ctx).bottom +
                MediaQuery.paddingOf(ctx).bottom +
                32,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.language_rounded,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  context.l10n.appLanguage,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.choosePreferredLanguage,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                ),
                const SizedBox(height: 32),
                _LanguageOptionTile(
                  flag: '🇺🇸',
                  name: 'English (US)',
                  selected: selectedCode == 'en',
                  onTap: () => setSheetState(() => selectedCode = 'en'),
                ),
                _LanguageOptionTile(
                  flag: '🇪🇹',
                  name: 'Amharic',
                  selected: selectedCode == 'am',
                  onTap: () => setSheetState(() => selectedCode = 'am'),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      await ref
                          .read(localeProvider.notifier)
                          .setLocale(selectedCode);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text(
                      'Confirm Selection',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

class _LanguageOptionTile extends StatelessWidget {
  const _LanguageOptionTile({
    required this.flag,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final String flag;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: selected ? AppColors.primarySoft : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.borderLight,
          width: 2,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Text(flag, style: const TextStyle(fontSize: 28)),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? AppColors.primary : AppColors.textPrimary,
            fontSize: 16,
          ),
        ),
        trailing: selected
            ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
            : null,
      ),
    );
  }
}

/// Label for the profile language list row.
String currentAppLanguageLabel(BuildContext context, WidgetRef ref) {
  final code =
      ref.watch(localeProvider)?.languageCode ??
      Localizations.localeOf(context).languageCode;
  return code == 'am' ? 'Amharic' : 'English (US)';
}
