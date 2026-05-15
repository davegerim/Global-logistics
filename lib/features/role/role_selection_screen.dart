import 'package:global_logistics_app/core/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

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
                    onPressed: () => context.go('/onboarding'),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFE9F1F1),
                      foregroundColor: AppColors.textPrimary,
                    ),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'How would you like\nto use the app?',
                style: t.headlineMedium?.copyWith(
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Choose the experience that fits you. You can always sign out and switch later.',
                style: t.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              _RoleCard(
                title: context.l10n.consignor,
                subtitle:
                    'Ship goods, track loads, pay, and receive delivery notes.',
                icon: Icons.inventory_2_outlined,
                accent: AppColors.primary,
                onTap: () => context.push('/login?role=consignor'),
              ),
              const SizedBox(height: 14),
              _RoleCard(
                title: context.l10n.driver,
                subtitle:
                    'Receive offers, accept routes, and confirm delivery.',
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
                      builder: (context) => Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Create an account',
                              style: t.titleLarge,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Registration is reviewed by your logistics team.',
                              style: t.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            FilledButton(
                              onPressed: () {
                                Navigator.pop(context);
                                context.push('/register-consignor');
                              },
                              child: Text(context.l10n.registerAsConsignor),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                context.push('/register-driver');
                              },
                              child: Text(context.l10n.registerAsDriver),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'Need to register?',
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
