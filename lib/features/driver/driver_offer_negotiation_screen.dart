import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';
import 'package:global_logistics_app/core/providers/backend_api_provider.dart';
import 'package:global_logistics_app/core/providers/driver_offers_provider.dart';
import 'package:global_logistics_app/data/models/driver_offer_model.dart';
import 'package:intl/intl.dart';

class DriverOfferNegotiationScreen extends ConsumerStatefulWidget {
  const DriverOfferNegotiationScreen({
    super.key,
    required this.negotiationId,
    this.initialOffer,
  });

  final String negotiationId;
  final DriverOfferModel? initialOffer;

  @override
  ConsumerState<DriverOfferNegotiationScreen> createState() =>
      _DriverOfferNegotiationScreenState();
}

class _DriverOfferNegotiationScreenState
    extends ConsumerState<DriverOfferNegotiationScreen> {
  bool _busy = false;

  Future<void> _accept(String negotiationId) async {
    await _runAction(() async {
      await ref.read(backendApiProvider).driverNegotiationsDriverAccepts({
        'negotiationId': negotiationId,
        'lat': 9.03,
        'lon': 38.75,
        'locationText': 'Addis Ababa (mobile demo)',
      });
    }, success: 'Offer accepted.');
  }

  Future<void> _reject(String negotiationId) async {
    final reason = await _promptText('Reject offer', 'Reason (optional)');
    if (!mounted) return;
    await _runAction(() async {
      await ref.read(backendApiProvider).driverNegotiationsDriverRejects({
        'negotiationId': negotiationId,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      });
    }, success: 'Offer declined.');
  }

  Future<void> _cancel(String negotiationId) async {
    final reason = await _promptText('Cancel offer', 'Reason (optional)');
    if (!mounted) return;
    await _runAction(() async {
      await ref.read(backendApiProvider).driverNegotiationsDriverCancel({
        'negotiationId': negotiationId,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      });
    }, success: 'Offer cancelled.');
  }

  Future<void> _counter(String negotiationId, DriverOfferModel offer) async {
    final price = TextEditingController(text: offer.price.toStringAsFixed(0));
    final reason = TextEditingController();
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 8,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Counter offer',
              style: Theme.of(
                ctx,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: price,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Counter price *'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: reason,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  final parsed = double.tryParse(price.text.trim());
                  if (parsed == null || parsed <= 0) return;
                  await _runAction(() async {
                    await ref
                        .read(backendApiProvider)
                        .driverNegotiationsDriverCounter({
                          'negotiationId': negotiationId,
                          'counterPrice': parsed,
                          if (reason.text.trim().isNotEmpty)
                            'reason': reason.text.trim(),
                        });
                  }, success: 'Counter offer sent.');
                  if (ctx.mounted) Navigator.pop(ctx, true);
                },
                icon: const Icon(Icons.currency_exchange_rounded),
                label: const Text('Send counter offer'),
              ),
            ),
          ],
        ),
      ),
    );
    if (submitted == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Counter proposal submitted.')),
      );
    }
  }

  Future<void> _runAction(
    Future<void> Function() action, {
    required String success,
  }) async {
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(driverOffersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _promptText(String title, String hint) async {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(controller: c, decoration: InputDecoration(hintText: hint)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, c.text.trim()),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncOffers = ref.watch(driverOffersProvider);
    final timeFmt = DateFormat.yMMMd().add_jm();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Offer negotiation'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: asyncOffers.when(
        data: (offers) {
          DriverOfferModel? matched;
          for (final offer in offers) {
            if (offer.negotiationId == widget.negotiationId) {
              matched = offer;
              break;
            }
          }
          final offer = widget.initialOffer ?? matched;
          if (offer == null) {
            return const Center(child: Text('Offer not found'));
          }
          final rounds = _buildTimeline(offer);
          final hasRounds = rounds.isNotEmpty;
          return Column(
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppColors.heroCardGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.handshake_rounded, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Status: ${offer.apiStatus ?? 'OFFER'}'
                        '  •  Rounds: ${rounds.length}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _InfoCard(
                  rows: [
                    _InfoRow('Route', offer.routeSummary),
                    _InfoRow('Goods type', offer.goodType ?? '—'),
                    _InfoRow('Last update', timeFmt.format(offer.expiresAt)),
                    _InfoRow('Negotiation ID', offer.negotiationId),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: hasRounds
                    ? ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: rounds.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = rounds[index];
                          final mine = item.actor == _RoundActor.driver;
                          final bubbleColor = mine
                              ? AppColors.primary
                              : AppColors.surface;
                          final textColor = mine
                              ? Colors.white
                              : AppColors.textPrimary;
                          return Align(
                            alignment: mine
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.84,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: bubbleColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: mine ? AppColors.primary : AppColors.border,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            color: textColor,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    if (item.message != null &&
                                        item.message!.trim().isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        item.message!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(color: textColor),
                                      ),
                                    ],
                                    if (item.priceAmount != null) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        'Price: ${item.priceAmount!.toStringAsFixed(0)} ${offer.currency}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: textColor,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ],
                                    const SizedBox(height: 6),
                                    Text(
                                      item.when != null
                                          ? timeFmt.format(item.when!)
                                          : 'time unknown',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: mine
                                                ? Colors.white.withValues(alpha: 0.82)
                                                : AppColors.textSecondary,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    : Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'No negotiation rounds yet.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ),
                      ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _busy ? null : () => _reject(offer.negotiationId),
                            icon: const Icon(Icons.thumb_down_alt_outlined),
                            label: const Text('Decline'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _busy ? null : () => _cancel(offer.negotiationId),
                            icon: const Icon(Icons.cancel_outlined),
                            label: const Text('Cancel'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _busy ? null : () => _counter(offer.negotiationId, offer),
                            icon: const Icon(Icons.currency_exchange_rounded),
                            label: const Text('Counter'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _busy ? null : () => _accept(offer.negotiationId),
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Accept'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }

  List<_RoundItem> _buildTimeline(DriverOfferModel offer) {
    final rounds = offer.rounds;
    if (rounds.isEmpty) {
      return [
        _RoundItem(
          actor: _RoundActor.admin,
          title: 'Current offer',
          message: offer.apiStatus,
          when: offer.expiresAt,
          priceAmount: offer.price,
          round: 1,
        ),
      ];
    }
    return rounds
        .map(
          (round) => _RoundItem(
            actor: _roundActorFromApi(round.actorType),
            round: round.round,
            title: 'Round ${round.round ?? '-'} offer',
            message: _roundMessage(round),
            when: round.offeredAt,
            priceAmount: round.priceAmount,
          ),
        )
        .toList();
  }

  String _roundMessage(DriverNegotiationRound round) {
    final parts = <String>[];
    final reason = round.reason?.trim();
    if (reason != null && reason.isNotEmpty) {
      parts.add(reason);
    }
    final vehicleType = round.requiredVehicleType?.trim();
    final vehicleNum = round.requiredVehicleNumber;
    if (vehicleType != null && vehicleType.isNotEmpty) {
      parts.add('Vehicle: $vehicleType${vehicleNum != null ? ' x$vehicleNum' : ''}');
    }
    if (round.loadingDate != null || round.deliveryDate != null) {
      parts.add('Schedule updated');
    }
    return parts.join(' • ');
  }

  _RoundActor _roundActorFromApi(String? actorType) {
    final value = (actorType ?? '').toUpperCase();
    if (value == 'DRIVER') return _RoundActor.driver;
    if (value == 'ADMIN') return _RoundActor.admin;
    return _RoundActor.system;
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.rows});

  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: rows
            .map(
              (row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 108,
                      child: Text(
                        row.keyLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        row.valueLabel,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _InfoRow {
  const _InfoRow(this.keyLabel, this.valueLabel);

  final String keyLabel;
  final String valueLabel;
}

enum _RoundActor { driver, admin, system }

class _RoundItem {
  const _RoundItem({
    required this.actor,
    required this.title,
    this.round,
    this.message,
    this.when,
    this.priceAmount,
  });

  final _RoundActor actor;
  final int? round;
  final String title;
  final String? message;
  final DateTime? when;
  final double? priceAmount;
}
