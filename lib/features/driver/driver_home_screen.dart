import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';
import 'package:global_logistics_app/core/errors/user_facing_error.dart';
import 'package:global_logistics_app/core/providers/auth_provider.dart';
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
    final assigned = ref.watch(driverActiveAssignmentsProvider);
    final unreadAsync = ref.watch(unreadNotificationsCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            systemOverlayStyle: SystemUiOverlayStyle.dark,
            toolbarHeight: 70,
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
                  onPressed: () => context.push('/driver/notifications'),
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
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.gold,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.gold.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.route, color: AppColors.primaryDark),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Assigned shipments',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      color: AppColors.surface,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Accept offers from the Offers tab; admin assigns final routes.',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.surface.withValues(alpha: 0.8),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
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
                secondaryActionLabel: 'History',
                onSecondaryAction: () => context.push('/driver/assignments/history'),
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
                SliverFillRemaining(child: Center(child: Text(userFacingMessage(e)))),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}
