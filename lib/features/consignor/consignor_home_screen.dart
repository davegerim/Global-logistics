import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';
import 'package:global_logistics_app/core/providers/auth_provider.dart';
import 'package:global_logistics_app/core/providers/backend_api_provider.dart';
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
                        auth.displayName ?? 'Consignor',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    final list = await ref
                        .read(backendApiProvider)
                        .notificationsLatest();
                    if (!context.mounted) return;
                    ref.invalidate(unreadNotificationsCountProvider);
                    await showModalBottomSheet<void>(
                      context: context,
                      showDragHandle: true,
                      builder: (ctx) => Padding(
                        padding: const EdgeInsets.all(20),
                        child: ListView(
                          children: [
                            Text(
                              'Notifications',
                              style: Theme.of(ctx).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              list.toString(),
                              style: Theme.of(ctx).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
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
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Freight operations,\nmade effortless.',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Book quickly, track milestones, and receive delivery documents in one place.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: AppColors.heroCardGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.32),
                          blurRadius: 32,
                          offset: const Offset(0, 16),
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
                        const SizedBox(height: 6),
                        Text(
                          'Points, goods, timeline, payment.',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                                height: 1.35,
                              ),
                        ),
                        const SizedBox(height: 10),
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
                              label: 'New booking',
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
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
            sliver: SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Active & recent',
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
