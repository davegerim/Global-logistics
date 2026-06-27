import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';
import 'package:global_logistics_app/core/extensions/l10n_extension.dart';
import 'package:global_logistics_app/core/providers/locale_provider.dart';
import 'package:global_logistics_app/shared/widgets/app_language_toggle.dart';

class RoleSelectionScreen extends ConsumerWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: () => context.go('/login'),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFE9F1F1),
                      foregroundColor: AppColors.textPrimary,
                    ),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const Spacer(),
                  const AppLanguageToggle(),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.howWouldYouLikeToUseApp,
                style: t.headlineMedium?.copyWith(
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                context.l10n.chooseExperienceSubtitle,
                style: t.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              _RoleCard(
                title: context.l10n.consignor,
                subtitle: context.l10n.consignorRoleSubtitle,
                icon: Icons.inventory_2_outlined,
                accent: AppColors.primary,
                onTap: () => context.push('/login?role=consignor'),
              ),
              const SizedBox(height: 14),
              _RoleCard(
                title: context.l10n.driver,
                subtitle: context.l10n.driverRoleSubtitle,
                icon: Icons.local_shipping_outlined,
                accent: AppColors.gold,
                onTap: () => context.push('/login?role=driver'),
              ),
              const SizedBox(height: 28),
              Center(
                child: TextButton(
                  onPressed: () {
                    showModalBottomSheet<void>(
                      context: context,
                      showDragHandle: true,
                      backgroundColor: AppColors.surface,
                      builder: (sheetContext) => Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              sheetContext.l10n.createAnAccount,
                              style: t.titleLarge,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              sheetContext.l10n.registrationReviewedByTeam,
                              style: t.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            FilledButton(
                              onPressed: () {
                                Navigator.pop(sheetContext);
                                context.push('/register-consignor');
                              },
                              child: Text(sheetContext.l10n.registerAsConsignor),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton(
                              onPressed: () {
                                Navigator.pop(sheetContext);
                                context.push('/register-driver');
                              },
                              child: Text(sheetContext.l10n.registerAsDriver),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: Text(
                    context.l10n.needToRegister,
                    style: t.labelLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            color: const Color(0xFFE9F1F1),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [accent, accent.withValues(alpha: 0.65)],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: const Color(0xFFFFFFFF),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: t.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: t.bodyMedium?.copyWith(height: 1.4),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
