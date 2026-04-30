import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';
import 'package:global_logistics_app/core/providers/auth_provider.dart';
import 'package:global_logistics_app/core/providers/backend_api_provider.dart';
import 'package:global_logistics_app/core/providers/notifications_provider.dart';
import 'package:global_logistics_app/core/providers/shipments_provider.dart';
import 'package:global_logistics_app/shared/widgets/shipment_card.dart';
import 'package:global_logistics_app/shared/widgets/section_header.dart';

class DriverHomeScreen extends ConsumerWidget {
  const DriverHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final rawStatus = (auth.accountStatus ?? 'UNKNOWN').trim().toUpperCase();
    final approvalPending = !auth.canViewDriverOffers;
    final statusLabel = approvalPending ? 'Pending admin approval' : rawStatus;
    final statusColor = approvalPending ? AppColors.warning : AppColors.success;
    final assigned = ref.watch(driverAssignedShipmentsProvider);
    final unreadAsync = ref.watch(unreadNotificationsCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            pinned: true,
            backgroundColor: AppColors.surface,
            title: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    (auth.displayName ?? 'D').substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'On the road',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        auth.displayName ?? 'Driver',
                        style: Theme.of(context).textTheme.titleMedium,
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
                      child: const Icon(Icons.notifications_none_rounded),
                    ),
                    loading: () => const Icon(Icons.notifications_none_rounded),
                    error: (_, __) =>
                        const Icon(Icons.notifications_none_rounded),
                  ),
                ),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.goldLight,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.route, color: AppColors.primary),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Assigned shipments',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              Text(
                                'Accept offers from the Offers tab; admin assigns final routes.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.verified_user_outlined, size: 18, color: statusColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Account status: $statusLabel',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
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
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            sliver: SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Active assignments',
                actionLabel: 'Open offers',
                onAction: () {
                  if (auth.canViewDriverOffers) {
                    context.go('/driver/offers');
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Your driver account is not approved yet. You will get offers after admin approval.',
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          assigned.when(
            data: (list) {
              if (list.isEmpty) {
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      'No active assignments. Check new offers.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, i) {
                    final s = list[i];
                    return ShipmentCard(
                      shipment: s,
                      onTap: () => context.push('/driver/shipment/${s.id}'),
                    );
                  },
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) =>
                SliverFillRemaining(child: Center(child: Text('$e'))),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}
