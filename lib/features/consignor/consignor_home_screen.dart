import 'package:global_logistics_app/core/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';
import 'package:global_logistics_app/core/providers/auth_provider.dart';
import 'package:global_logistics_app/core/providers/notifications_provider.dart';
import 'package:global_logistics_app/core/providers/shipments_provider.dart';
import 'package:global_logistics_app/data/models/shipment_status.dart';
import 'package:global_logistics_app/shared/widgets/section_header.dart';
import 'package:global_logistics_app/shared/widgets/shipment_card.dart';
import 'package:global_logistics_app/shared/widgets/gl_primary_button.dart';

class ConsignorHomeScreen extends ConsumerWidget {
  const ConsignorHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final canBook = auth.canCreateConsignorBooking;
    final rawStatus = (auth.accountStatus ?? '').trim();
    final statusLabel = canBook
        ? (rawStatus.isEmpty ? 'APPROVED' : rawStatus.toUpperCase())
        : (rawStatus.toUpperCase() == 'VERIFIED'
              ? 'VERIFIED (waiting admin approval)'
              : (rawStatus.isEmpty
                    ? 'PENDING ADMIN APPROVAL'
                    : '${rawStatus.toUpperCase()} (waiting admin approval)'));
    final shipments = ref.watch(consignorShipmentsProvider);
    final unreadAsync = ref.watch(unreadNotificationsCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.surface,
            toolbarHeight: 82,
            title: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primarySoft,
                  child: Text(
                    (auth.displayName ?? 'G').substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Welcome back',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        auth.displayName ?? context.l10n.consignor,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => context.push('/consignor/notifications'),
                  icon: unreadAsync.when(
                    data: (n) => Badge(
                      isLabelVisible: n > 0,
                      label: Text('$n'),
                      child: const Icon(Icons.notifications_outlined),
                    ),
                    loading: () => const Icon(Icons.notifications_outlined),
                    error: (error, stackTrace) =>
                        const Icon(Icons.notifications_outlined),
                  ),
                ),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: AppColors.heroCardGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            'Quick action',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: AppColors.goldMuted,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Create booking',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.22),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                canBook
                                    ? Icons.verified_rounded
                                    : Icons.pending_actions_rounded,
                                size: 18,
                                color: canBook
                                    ? AppColors.goldMuted
                                    : Colors.white.withValues(alpha: 0.9),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  canBook
                                      ? 'Status: $statusLabel'
                                      : 'Status: $statusLabel · Booking unlocks after admin approval',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Colors.white.withValues(
                                          alpha: 0.9,
                                        ),
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            width: 190,
                            child: GlPrimaryButton(
                              useGoldAccent: true,
                              showShadow: false,
                              label: context.l10n.newBooking,
                              icon: Icons.arrow_forward_rounded,
                              onPressed: canBook
                                  ? () => context.push('/consignor/create')
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: -10,
                    bottom: -15,
                    child: IgnorePointer(
                      child: Image.asset(
                        'assets/images/image-31GYuaDQ6tzlmK2MsYTpfwzmJwf9Kr.webp',
                        width: 150,
                        height: 150,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
            sliver: SliverToBoxAdapter(
              child: SectionHeader(
                title: context.l10n.activeAndRecent,
                actionLabel: 'View all',
                onAction: () => context.go('/consignor/shipments'),
              ),
            ),
          ),
          shipments.when(
            data: (list) {
              final featured = list
                  .where(
                    (s) =>
                        s.status != ShipmentStatus.completed &&
                        s.status != ShipmentStatus.cancelled,
                  )
                  .take(2)
                  .toList();
              if (featured.isEmpty) {
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      'No active shipments. Create a booking to get started.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.separated(
                  itemCount: featured.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 14),
                  itemBuilder: (context, i) {
                    final s = featured[i];
                    return ShipmentCard(
                      shipment: s,
                      onTap: () => context.push('/consignor/shipment/${s.id}'),
                    );
                  },
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) =>
                SliverFillRemaining(child: Center(child: Text('Error: $e'))),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
