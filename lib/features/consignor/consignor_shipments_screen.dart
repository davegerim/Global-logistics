import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';
import 'package:global_logistics_app/core/errors/user_facing_error.dart';
import 'package:global_logistics_app/core/providers/auth_provider.dart';
import 'package:global_logistics_app/core/providers/shipments_provider.dart';
import 'package:global_logistics_app/data/models/shipment_model.dart';
import 'package:global_logistics_app/data/models/shipment_status.dart';
import 'package:global_logistics_app/shared/widgets/shipment_card.dart';

class ConsignorShipmentsScreen extends ConsumerStatefulWidget {
  const ConsignorShipmentsScreen({super.key});

  @override
  ConsumerState<ConsignorShipmentsScreen> createState() => _ConsignorShipmentsScreenState();
}

class _ConsignorShipmentsScreenState extends ConsumerState<ConsignorShipmentsScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(consignorShipmentsProvider);
    final auth = ref.watch(authProvider);
    final awaitingApproval = !auth.canCreateConsignorBooking;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My shipments'),
      ),
      body: async.when(
        data: (list) {
          final filtered = _applyFilter(list, _filter);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: _filter == 'all',
                      onTap: () => setState(() => _filter = 'all'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'In progress',
                      selected: _filter == 'progress',
                      onTap: () => setState(() => _filter = 'progress'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Delivered',
                      selected: _filter == 'done',
                      onTap: () => setState(() => _filter = 'done'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? _ShipmentsEmptyState(awaitingApproval: awaitingApproval)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, i) {
                          final s = filtered[i];
                          return ShipmentCard(
                            shipment: s,
                            onTap: () => context.push('/consignor/shipment/${s.id}'),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(userFacingMessage(e))),
      ),
    );
  }

  List<ShipmentModel> _applyFilter(List<ShipmentModel> list, String filter) {
    bool inProgress(ShipmentStatus s) =>
        s != ShipmentStatus.completed && s != ShipmentStatus.cancelled;
    return switch (filter) {
      'progress' => list.where((s) => inProgress(s.status)).toList(),
      'done' => list.where((s) => s.status == ShipmentStatus.completed).toList(),
      _ => list,
    };
  }
}

class _ShipmentsEmptyState extends StatelessWidget {
  const _ShipmentsEmptyState({required this.awaitingApproval});

  final bool awaitingApproval;

  @override
  Widget build(BuildContext context) {
    final title = awaitingApproval
        ? 'Account approval pending'
        : 'No shipments yet';
    final subtitle = awaitingApproval
        ? 'Your account is verified but not yet approved by admin. Shipments will appear here after approval.'
        : 'You do not have shipments for this filter yet.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              awaitingApproval ? Icons.lock_clock_rounded : Icons.inbox_rounded,
              size: 36,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.surface,
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
