import 'package:global_logistics_app/core/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';
import 'package:global_logistics_app/core/utils/consignor_account_status_utils.dart';
import 'package:global_logistics_app/core/errors/user_facing_error.dart';
import 'package:global_logistics_app/core/providers/auth_provider.dart';
import 'package:global_logistics_app/core/providers/backend_api_provider.dart';
import 'package:global_logistics_app/core/providers/driver_offers_provider.dart';
import 'package:global_logistics_app/core/utils/negotiation_status_utils.dart';
import 'package:global_logistics_app/data/models/driver_offer_model.dart';
import 'package:global_logistics_app/core/services/device_location_service.dart';
import 'package:intl/intl.dart';

class DriverOffersScreen extends ConsumerStatefulWidget {
  const DriverOffersScreen({super.key});

  @override
  ConsumerState<DriverOffersScreen> createState() => _DriverOffersScreenState();
}

class _DriverOffersScreenState extends ConsumerState<DriverOffersScreen> {
  String _filter = 'active';

  Future<void> _accept(
    BuildContext context,
    WidgetRef ref,
    String negotiationId,
  ) async {
    try {
      final location = await DeviceLocationService.current();
      final payload = {
        'negotiationId': negotiationId,
        'lat': location.latitude,
        'lon': location.longitude,
        'locationText':
            'GPS(${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)})',
      };
      await ref
          .read(backendApiProvider)
          .driverNegotiationsDriverAccepts(payload);
      ref.invalidate(driverOffersProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.offerAccepted)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(userFacingMessage(e))));
      }
    }
  }

  Future<void> _reject(
    BuildContext context,
    WidgetRef ref,
    String negotiationId,
  ) async {
    final reason = await _prompt(context, 'Reject', context.l10n.reasonOptional);
    if (!context.mounted) return;
    try {
      await ref.read(backendApiProvider).driverNegotiationsDriverRejects({
        'negotiationId': negotiationId,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      });
      ref.invalidate(driverOffersProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.offerDeclined)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(userFacingMessage(e))));
      }
    }
  }

  Future<void> _cancel(
    BuildContext context,
    WidgetRef ref,
    String negotiationId,
  ) async {
    final reason = await _prompt(context, context.l10n.cancelOffer, context.l10n.reasonOptional);
    if (!context.mounted) return;
    try {
      await ref.read(backendApiProvider).driverNegotiationsDriverCancel({
        'negotiationId': negotiationId,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      });
      ref.invalidate(driverOffersProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.offerCancelled)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(userFacingMessage(e))));
      }
    }
  }

  static Future<String?> _prompt(
    BuildContext context,
    String title,
    String hint,
  ) {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: c,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, c.text.trim()),
            child: Text(context.l10n.ok),
          ),
        ],
      ),
    );
  }

  List<DriverOfferModel> _applyFilter(List<DriverOfferModel> list, String filter) {
    return switch (filter) {
      'active' => list.where((o) => !isNegotiationSettled(o.apiStatus)).toList(),
      'settled' => list.where((o) => isNegotiationSettled(o.apiStatus)).toList(),
      _ => list,
    };
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    if (!auth.canViewDriverOffers) {
      final accountStatusLabel =
          DriverAccountStatusUtils.displayLabel(auth, context.l10n);
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text(context.l10n.shipmentOffers)),
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
                  const Icon(
                    Icons.lock_clock_rounded,
                    color: AppColors.primary,
                    size: 36,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Admin approval pending',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    accountStatusLabel == null
                        ? 'Your account is not approved by admin yet, so you will not receive shipment offers until approval is completed.'
                        : 'Current status: $accountStatusLabel. Your account is not approved by admin yet, so you will not receive shipment offers until approval is completed.',
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
        title: Text(context.l10n.shipmentOffers),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(driverOffersProvider),
          ),
        ],
      ),
      body: async.when(
        data: (offers) {
          final filtered = _applyFilter(offers, _filter);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  children: [
                    _CategoryTab(
                      label: context.l10n.allOffers,
                      icon: Icons.all_inbox_rounded,
                      isSelected: _filter == 'all',
                      onTap: () => setState(() => _filter = 'all'),
                    ),
                    const SizedBox(width: 8),
                    _CategoryTab(
                      label: context.l10n.active,
                      icon: Icons.local_shipping_rounded,
                      isSelected: _filter == 'active',
                      onTap: () => setState(() => _filter = 'active'),
                    ),
                    const SizedBox(width: 8),
                    _CategoryTab(
                      label: context.l10n.settled,
                      icon: Icons.verified_rounded,
                      isSelected: _filter == 'settled',
                      onTap: () => setState(() => _filter = 'settled'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.inbox_rounded,
                              size: 48,
                              color: AppColors.textSecondary.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No offers found',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'There are no offers in this category right now.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 14),
                        itemBuilder: (context, i) {
                          final o = filtered[i];
                          final isSettled = isNegotiationSettled(o.apiStatus);
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.goldLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            o.apiStatus ?? 'Offer',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
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
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => context.push(
                          '/driver/offers/${o.apiNegotiationId}/negotiation',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: AppColors.textPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.forum_rounded),
                        label: Text(context.l10n.openNegotiation),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      o.routeSummary,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (o.goodType != null)
                      Text(
                        o.goodType!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    const SizedBox(height: 6),
                    Text(
                      '${o.price.toStringAsFixed(0)} ${o.currency}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    _OfferDetailRow(
                      label: context.l10n.goods,
                      value: o.goodType?.isNotEmpty == true
                          ? context.translateDynamic(o.goodType!)
                          : context.l10n.notSpecified,
                    ),
                    _OfferDetailRow(
                      label: context.l10n.distance,
                      value: o.distanceKm > 0
                          ? '${o.distanceKm.toStringAsFixed(0)} km'
                          : context.l10n.notSpecified,
                    ),
                    _OfferDetailRow(
                      label: context.l10n.negotiationId,
                      value: o.displayNegotiationId,
                    ),
                    const SizedBox(height: 12),
                    if (isSettled)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.verified_rounded,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              context.l10n.settled,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      Text(
                        'Quick actions',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  _reject(context, ref, o.apiNegotiationId),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 4,
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              child: Text(
                                context.l10n.decline,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  _cancel(context, ref, o.apiNegotiationId),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 4,
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              child: Text(
                                context.l10n.cancel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton(
                              onPressed: () =>
                                  _accept(context, ref, o.apiNegotiationId),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 4,
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              child: Text(
                                context.l10n.accept,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
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

class _CategoryTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
