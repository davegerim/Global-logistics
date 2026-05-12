import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';
import 'package:global_logistics_app/core/errors/user_facing_error.dart';
import 'package:global_logistics_app/core/providers/backend_api_provider.dart';
import 'package:global_logistics_app/core/providers/driver_offers_provider.dart';
import 'package:global_logistics_app/core/services/device_location_service.dart';
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
  bool _showDetails = false;

  Future<void> _accept(String negotiationId) async {
    await _runAction(() async {
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
              decoration: const InputDecoration(labelText: 'Reason (optional)'),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(success)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(userFacingMessage(e))));
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
        content: TextField(
          controller: c,
          decoration: InputDecoration(hintText: hint),
        ),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(driverOffersProvider),
          ),
        ],
      ),
      body: asyncOffers.when(
        data: (offers) {
          DriverOfferModel? matched;
          for (final offer in offers) {
            if (offer.apiNegotiationId == widget.negotiationId ||
                offer.negotiationId == widget.negotiationId) {
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
          final isSettled = _isNegotiationSettled(offer.apiStatus);
          return Column(
            children: [
              GestureDetector(
                onTap: () => setState(() => _showDetails = !_showDetails),
                child: Container(
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
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      Icon(
                        _showDetails
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: Colors.white70,
                      ),
                    ],
                  ),
                ),
              ),
              if (_showDetails) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _InfoCard(
                    rows: [
                      _InfoRow('Route', offer.routeSummary),
                      _InfoRow('Goods type', offer.goodType ?? '—'),
                      _InfoRow('Last update', timeFmt.format(offer.expiresAt)),
                      _InfoRow('Negotiation ID', offer.displayNegotiationId),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Expanded(
                child: hasRounds
                    ? ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: rounds.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = rounds[index];
                          final mine = item.actor == _RoundActor.driver;
                          final bubbleColor = mine
                              ? AppColors.primarySoft
                              : AppColors.surface;
                          final textColor = mine
                              ? AppColors.primaryDark
                              : AppColors.textPrimary;
                          return Align(
                            alignment: mine
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.85,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: bubbleColor,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: Radius.circular(mine ? 16 : 4),
                                    bottomRight: Radius.circular(mine ? 4 : 16),
                                  ),
                                  border: Border.all(
                                    color: mine
                                        ? AppColors.primary.withValues(alpha: 0.2)
                                        : AppColors.borderLight,
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.03,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          mine
                                              ? Icons.person_rounded
                                              : Icons
                                                    .admin_panel_settings_rounded,
                                          size: 14,
                                          color: AppColors.primary,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _roundActorTitle(item.actor),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.2,
                                          ).copyWith(color: textColor),
                                        ),
                                      ],
                                    ),
                                    if (item.message != null &&
                                        item.message!.trim().isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        item.message!,
                                        style:
                                            const TextStyle(
                                              fontSize: 13,
                                              height: 1.3,
                                              fontWeight: FontWeight.w500,
                                            ).copyWith(
                                              color: textColor.withValues(
                                                alpha: 0.9,
                                              ),
                                            ),
                                      ),
                                    ],
                                    if (item.priceAmount != null) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        'Price: ${item.priceAmount!.toStringAsFixed(0)} ${offer.currency}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: textColor,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 6),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        item.when != null
                                            ? timeFmt.format(item.when!)
                                            : 'time unknown',
                                        style:
                                            const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ).copyWith(
                                              color: mine
                                                  ? AppColors.primary.withValues(alpha: 0.6)
                                                  : AppColors.textTertiary,
                                            ),
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
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.textSecondary),
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
                child: isSettled
                    ? _buildSettledBanner()
                    : Row(
                        children: [
                          Expanded(
                            child: _buildActionBtn(
                              icon: Icons.thumb_down_alt_outlined,
                              label: 'Decline',
                              onPressed: _busy
                                  ? null
                                  : () => _reject(offer.apiNegotiationId),
                              isPrimary: false,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _buildActionBtn(
                              icon: Icons.cancel_outlined,
                              label: 'Cancel',
                              onPressed: _busy
                                  ? null
                                  : () => _cancel(offer.apiNegotiationId),
                              isPrimary: false,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _buildActionBtn(
                              icon: Icons.currency_exchange_rounded,
                              label: 'Counter',
                              onPressed: _busy
                                  ? null
                                  : () => _counter(offer.apiNegotiationId, offer),
                              isPrimary: false,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _buildActionBtn(
                              icon: Icons.check_circle_outline,
                              label: 'Accept',
                              onPressed: _busy
                                  ? null
                                  : () => _accept(offer.apiNegotiationId),
                              isPrimary: true,
                              isLoading: _busy,
                            ),
                          ),
                        ],
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
      parts.add(
        'Vehicle: $vehicleType${vehicleNum != null ? ' x$vehicleNum' : ''}',
      );
    }
    if (round.loadingDate != null || round.deliveryDate != null) {
      parts.add('Schedule updated');
    }
    if (parts.isEmpty) {
      final actor = (round.actorType ?? '').toUpperCase();
      if (actor == 'ADMIN') return 'Admin updated the offer details.';
      if (actor == 'DRIVER') return 'Driver updated the offer details.';
      return 'Offer details updated.';
    }
    return parts.join(' • ');
  }

  _RoundActor _roundActorFromApi(String? actorType) {
    final value = (actorType ?? '').toUpperCase();
    if (value == 'DRIVER') return _RoundActor.driver;
    if (value == 'ADMIN') return _RoundActor.admin;
    return _RoundActor.system;
  }

  String _roundActorTitle(_RoundActor actor) {
    switch (actor) {
      case _RoundActor.driver:
        return 'Driver message';
      case _RoundActor.admin:
        return 'Admin message';
      case _RoundActor.system:
        return 'System message';
    }
  }

  bool _isNegotiationSettled(String? apiStatus) {
    final status = (apiStatus ?? '').toUpperCase();
    if (status.isEmpty) return false;
    return status.contains('ACCEPTED') ||
        status.contains('APPROVED') ||
        status.contains('ASSIGNED') ||
        status.contains('SELECTED') ||
        status.contains('AGREED') ||
        status.contains('SETTLED') ||
        status.contains('COMPLETED') ||
        status.contains('CLOSED');
  }

  Widget _buildSettledBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.goldLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_rounded, color: AppColors.gold),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Settled',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.gold,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool isPrimary = false,
    bool isLoading = false,
  }) {
    final content = isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.textPrimary,
            ),
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          );

    if (isPrimary) {
      return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.textPrimary,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: content,
      );
    } else {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.gold,
          side: const BorderSide(color: AppColors.gold),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: content,
      );
    }
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
