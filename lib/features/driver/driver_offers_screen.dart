import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';
import 'package:global_logistics_app/core/providers/auth_provider.dart';
import 'package:global_logistics_app/core/providers/backend_api_provider.dart';
import 'package:global_logistics_app/core/providers/driver_offers_provider.dart';
import 'package:intl/intl.dart';

class DriverOffersScreen extends ConsumerWidget {
  const DriverOffersScreen({super.key});

  Future<void> _accept(BuildContext context, WidgetRef ref, String negotiationId) async {
    try {
      await ref.read(backendApiProvider).driverNegotiationsDriverAccepts({
        'negotiationId': negotiationId,
        'lat': 9.03,
        'lon': 38.75,
        'locationText': 'Addis Ababa (mobile demo)',
      });
      ref.invalidate(driverOffersProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offer accepted.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref, String negotiationId) async {
    final reason = await _prompt(context, 'Reject', 'Reason (optional)');
    if (!context.mounted) return;
    try {
      await ref.read(backendApiProvider).driverNegotiationsDriverRejects({
        'negotiationId': negotiationId,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      });
      ref.invalidate(driverOffersProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offer declined.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref, String negotiationId) async {
    final reason = await _prompt(context, 'Cancel offer', 'Reason (optional)');
    if (!context.mounted) return;
    try {
      await ref.read(backendApiProvider).driverNegotiationsDriverCancel({
        'negotiationId': negotiationId,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      });
      ref.invalidate(driverOffersProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offer cancelled.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  static Future<String?> _prompt(BuildContext context, String title, String hint) {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(controller: c, decoration: InputDecoration(hintText: hint)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    if (!auth.canViewDriverOffers) {
      final statusText = (auth.accountStatus ?? 'VERIFIED').trim().toUpperCase();
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Shipment offers')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: 520,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_clock_rounded, color: AppColors.primary, size: 36),
                  const SizedBox(height: 12),
                  Text(
                    'Admin approval pending',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Current status: $statusText. Your account is not approved by admin yet, so you will not receive shipment offers until approval is completed.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final async = ref.watch(driverOffersProvider);
    final timeFmt = DateFormat.jm();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Shipment offers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(driverOffersProvider),
          ),
        ],
      ),
      body: async.when(
        data: (offers) {
          if (offers.isEmpty) {
            return Center(
              child: Text(
                'No offers available right now.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: offers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, i) {
              final o = offers[i];
              return Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.goldLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            o.apiStatus ?? 'Offer',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Updated ${timeFmt.format(o.expiresAt)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      o.routeSummary,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (o.goodType != null)
                      Text(o.goodType!, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 6),
                    Text(
                      '${o.price.toStringAsFixed(0)} ${o.currency}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    _OfferDetailRow(
                      label: 'Goods',
                      value: o.goodType?.isNotEmpty == true
                          ? o.goodType!
                          : 'Not specified',
                    ),
                    _OfferDetailRow(
                      label: 'Distance',
                      value: o.distanceKm > 0
                          ? '${o.distanceKm.toStringAsFixed(0)} km'
                          : 'Not specified',
                    ),
                    _OfferDetailRow(
                      label: 'Negotiation ID',
                      value: o.negotiationId,
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => context.push(
                          '/driver/offers/${o.negotiationId}/negotiation',
                        ),
                        icon: const Icon(Icons.forum_rounded),
                        label: const Text('Open negotiation'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Quick actions',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: () => _reject(context, ref, o.negotiationId),
                          child: const Text('Decline'),
                        ),
                        OutlinedButton(
                          onPressed: () => _cancel(context, ref, o.negotiationId),
                          child: const Text('Cancel'),
                        ),
                        OutlinedButton(
                          onPressed: () => context.push(
                            '/driver/offers/${o.negotiationId}/negotiation',
                          ),
                          child: const Text('Negotiate'),
                        ),
                        FilledButton(
                          onPressed: () => _accept(context, ref, o.negotiationId),
                          child: const Text('Accept'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}

class _OfferDetailRow extends StatelessWidget {
  const _OfferDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
