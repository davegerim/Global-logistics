import 'package:global_logistics_app/core/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';
import 'package:global_logistics_app/core/providers/auth_provider.dart';
import 'package:global_logistics_app/core/providers/shipments_provider.dart';

class ConsignorShell extends ConsumerWidget {
  const ConsignorShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _goBranch(WidgetRef ref, int index) {
    if (index == 0) {
      refreshConsignorHomeData(ref);
    }
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canBook = ref.watch(authProvider).canCreateConsignorBooking;
    return Scaffold(
      body: navigationShell,
      extendBody: true,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (canBook) {
            context.push('/consignor/create');
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Your account is verified but not admin-approved yet. Booking is disabled until approval.',
              ),
            ),
          );
        },
        backgroundColor: canBook ? AppColors.primary : AppColors.textTertiary,
        foregroundColor: Colors.white,
        elevation: 2,
        child: Icon(
          canBook ? Icons.add_rounded : Icons.lock_clock_rounded,
          size: 26,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: context.l10n.home,
                selected: navigationShell.currentIndex == 0,
                onTap: () => _goBranch(ref, 0),
              ),
              _NavItem(
                icon: Icons.list_alt_rounded,
                label: context.l10n.shipments,
                selected: navigationShell.currentIndex == 1,
                onTap: () => _goBranch(ref, 1),
              ),
              const SizedBox(width: 64),
              _NavItem(
                icon: Icons.folder_open_rounded,
                label: context.l10n.docs,
                selected: navigationShell.currentIndex == 2,
                onTap: () => _goBranch(ref, 2),
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                label: context.l10n.profile,
                selected: navigationShell.currentIndex == 3,
                onTap: () => _goBranch(ref, 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textSecondary;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
