import 'package:global_logistics_app/core/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';
import 'package:global_logistics_app/core/providers/auth_provider.dart';
import 'package:global_logistics_app/core/providers/driver_tracking_provider.dart';
import 'package:global_logistics_app/core/providers/shipments_provider.dart';

class DriverShell extends ConsumerStatefulWidget {
  const DriverShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<DriverShell> createState() => _DriverShellState();
}

class _DriverShellState extends ConsumerState<DriverShell>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final tracking = ref.read(driverTrackingControllerProvider.notifier);
    switch (state) {
      case AppLifecycleState.resumed:
        tracking.setAppInForeground(true);
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        tracking.setAppInForeground(false);
    }
  }

  void _goBranch(BuildContext context, WidgetRef ref, int index) {
    final canViewOffers = ref.read(authProvider).canViewDriverOffers;
    if (index == 1 && !canViewOffers) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your driver account is not approved yet. You will get offers after admin approval.',
          ),
        ),
      );
      return;
    }
    if (index == 0) {
      refreshDriverHomeData(ref);
    }
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(driverTrackingControllerProvider);
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: context.l10n.bottomNavHome,
                selected: widget.navigationShell.currentIndex == 0,
                onTap: () => _goBranch(context, ref, 0),
              ),
              _NavItem(
                icon: Icons.local_offer_outlined,
                label: context.l10n.bottomNavOffers,
                selected: widget.navigationShell.currentIndex == 1,
                onTap: () => _goBranch(context, ref, 1),
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                label: context.l10n.bottomNavProfile,
                selected: widget.navigationShell.currentIndex == 2,
                onTap: () => _goBranch(context, ref, 2),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.gold : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: selected ? AppColors.primaryDark : AppColors.surface.withValues(alpha: 0.7),
              size: 26,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppColors.primaryDark : AppColors.surface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
