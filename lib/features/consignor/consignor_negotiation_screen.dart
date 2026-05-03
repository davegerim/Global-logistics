import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';
import 'package:global_logistics_app/core/providers/consignor_active_provider.dart';
import 'package:global_logistics_app/core/providers/backend_api_provider.dart';
import 'package:global_logistics_app/core/providers/shipments_provider.dart';
import 'package:global_logistics_app/data/models/shipment_model.dart';
import 'package:global_logistics_app/data/models/shipment_status.dart';
import 'package:global_logistics_app/shared/widgets/gl_primary_button.dart';
import 'package:intl/intl.dart';

class ConsignorNegotiationScreen extends ConsumerStatefulWidget {
  const ConsignorNegotiationScreen({super.key, required this.shipmentId});

  final String shipmentId;

  @override
  ConsumerState<ConsignorNegotiationScreen> createState() =>
      _ConsignorNegotiationScreenState();
}

class _ConsignorNegotiationScreenState
    extends ConsumerState<ConsignorNegotiationScreen> {
  bool _busy = false;

  Future<void> _acceptOffer() async {
    await _runAction(() async {
      await ref
          .read(backendApiProvider)
          .shipmentsConsignorAcceptOffer(widget.shipmentId);
    }, success: 'Offer accepted.');
  }

  Future<void> _rejectOffer() async {
    final reason = await _promptText(
      title: 'Reject offer',
      hint: 'Reason',
      requiredField: true,
    );
    if (!mounted || reason == null) return;
    await _runAction(() async {
      await ref.read(backendApiProvider).shipmentsConsignorRejectOffer({
        'shipmentId': widget.shipmentId,
        'reason': reason,
      });
    }, success: 'Offer rejected.');
  }

  Future<void> _cancelShipment() async {
    final reason = await _promptText(
      title: 'Cancel shipment',
      hint: 'Reason',
      requiredField: true,
    );
    if (!mounted || reason == null) return;
    await _runAction(() async {
      await ref.read(backendApiProvider).shipmentsConsignorCancel({
        'shipmentId': widget.shipmentId,
        'reason': reason,
      });
    }, success: 'Shipment cancelled.');
  }

  Future<void> _counterOffer() async {
    final shipment = ref
        .read(consignorShipmentsProvider)
        .maybeWhen(data: _findShipment, orElse: () => null);
    if (shipment == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shipment context not loaded yet.')),
        );
      }
      return;
    }
    final form = await _promptCounterOfferForm(shipment);
    if (!mounted || form == null) return;
    await _runAction(() async {
      await ref.read(backendApiProvider).shipmentsConsignorCounterOffer(form);
    }, success: 'Counter offer sent.');
  }

  Future<void> _runAction(
    Future<void> Function() action, {
    required String success,
  }) async {
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(consignorShipmentsProvider);
      ref.invalidate(consignorActiveProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(success)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _promptText({
    required String title,
    required String hint,
    bool requiredField = false,
  }) async {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: c,
          maxLines: 4,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final v = c.text.trim();
              if (requiredField && v.isEmpty) return;
              Navigator.pop(ctx, v);
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>?> _promptCounterOfferForm(
    ShipmentModel shipment,
  ) async {
    final price = TextEditingController(
      text: shipment.priceOffer?.toStringAsFixed(2) ?? '',
    );
    final vehicleType = TextEditingController(text: shipment.vehicleType);
    final vehicleNumber = TextEditingController(text: '1');
    final loadingDate = TextEditingController(
      text: shipment.placedAt.toUtc().toIso8601String(),
    );
    final deliveryDate = TextEditingController(
      text:
          (shipment.estimatedDelivery ??
                  shipment.placedAt.add(const Duration(days: 2)))
              .toUtc()
              .toIso8601String(),
    );
    final reason = TextEditingController();

    return showModalBottomSheet<Map<String, dynamic>>(
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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Counter offer',
                style: Theme.of(
                  ctx,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: price,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Counter price *',
                  hintText: 'e.g. 960.00',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: vehicleType,
                decoration: const InputDecoration(
                  labelText: 'Required vehicle type (optional)',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: vehicleNumber,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Required vehicle number (optional)',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: loadingDate,
                decoration: const InputDecoration(
                  labelText: 'Loading date UTC (optional)',
                  hintText: '2026-03-10T08:00:00Z',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: deliveryDate,
                decoration: const InputDecoration(
                  labelText: 'Delivery date UTC (optional)',
                  hintText: '2026-03-12T14:30:00Z',
                ),
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
              GlPrimaryButton(
                label: 'Send counter offer',
                onPressed: () {
                  final parsedPrice = double.tryParse(price.text.trim());
                  if (parsedPrice == null) return;
                  final parsedVehicleCount = int.tryParse(
                    vehicleNumber.text.trim(),
                  );
                  final normalizedVehicleType = vehicleType.text.trim().isEmpty
                      ? shipment.vehicleType
                      : vehicleType.text.trim();
                  final normalizedLoadingDate = loadingDate.text.trim().isEmpty
                      ? shipment.placedAt.toUtc().toIso8601String()
                      : loadingDate.text.trim();
                  final normalizedDeliveryDate =
                      deliveryDate.text.trim().isEmpty
                      ? (shipment.estimatedDelivery ??
                                shipment.placedAt.add(const Duration(days: 2)))
                            .toUtc()
                            .toIso8601String()
                      : deliveryDate.text.trim();

                  Navigator.pop(ctx, {
                    'shipmentId': widget.shipmentId,
                    'counterPrice': parsedPrice,
                    'requiredVehicleType': normalizedVehicleType,
                    'requiredVehicleNumber': parsedVehicleCount ?? 1,
                    'loadingDate': normalizedLoadingDate,
                    'deliveryDate': normalizedDeliveryDate,
                    if (reason.text.trim().isNotEmpty)
                      'reason': reason.text.trim(),
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shipments = ref.watch(consignorShipmentsProvider);
    final activeAsync = ref.watch(consignorActiveProvider);
    final fmt = DateFormat.yMMMd().add_jm();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Negotiation room'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            onPressed: () {
              ref.invalidate(consignorShipmentsProvider);
              ref.invalidate(consignorActiveProvider);
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: shipments.when(
        data: (list) {
          final shipment = _findShipment(list);
          if (shipment == null) {
            return const Center(child: Text('Shipment not found'));
          }
          final activeShipment = activeAsync.maybeWhen(
            data: (data) => _findActiveShipment(data, shipment),
            orElse: () => null,
          );
          final events = _buildRoundsTimeline(activeShipment);
          final status = shipment.apiStatusLabel ?? shipment.status.label;
          final latestPrice = shipment.priceOffer;
          final hasAdminEvent = events.any(
            (e) => e.actor == _TimelineActor.admin,
          );

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
                        'Status: $status'
                        '${latestPrice != null ? '  •  Latest price: $latestPrice' : ''}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: events.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'No offer rounds yet.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: events.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final e = events[index];
                          final mine = e.actor == _TimelineActor.consignor;
                          final bubbleColor = mine
                              ? AppColors.primary
                              : AppColors.surface;
                          final textColor = mine
                              ? Colors.white
                              : AppColors.textPrimary;
                          return Align(
                            alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.85,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: bubbleColor,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: Radius.circular(mine ? 16 : 4),
                                    bottomRight: Radius.circular(mine ? 4 : 16),
                                  ),
                                  border: Border.all(
                                    color: mine ? AppColors.primary : AppColors.borderLight,
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.03),
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
                                          mine ? Icons.person_rounded : Icons.admin_panel_settings_rounded,
                                          size: 14,
                                          color: mine ? Colors.white.withValues(alpha: 0.9) : AppColors.primary,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          e.title,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.2,
                                          ).copyWith(color: textColor),
                                        ),
                                      ],
                                    ),
                                    if (e.message != null && e.message!.trim().isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        e.message!,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          height: 1.3,
                                          fontWeight: FontWeight.w500,
                                        ).copyWith(color: textColor.withValues(alpha: 0.9)),
                                      ),
                                    ],
                                    if (e.price != null) ...[
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: mine ? Colors.white.withValues(alpha: 0.15) : AppColors.primarySoft,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Price: ${e.price}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: mine ? Colors.white : AppColors.primaryDark,
                                          ),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 6),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        e.when != null ? fmt.format(e.when!) : 'time unknown',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ).copyWith(
                                          color: mine
                                              ? Colors.white.withValues(alpha: 0.7)
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
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: OutlinedButton.icon(
                  onPressed: () => context.push(
                    '/consignor/shipment/${shipment.id}/history',
                  ),
                  icon: const Icon(Icons.history_rounded),
                  label: const Text('Open shipment history'),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: hasAdminEvent
                    ? Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _busy ? null : _rejectOffer,
                                  icon: const Icon(
                                    Icons.thumb_down_alt_outlined,
                                  ),
                                  label: const Text('Reject'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _busy ? null : _cancelShipment,
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
                                  onPressed: _busy ? null : _counterOffer,
                                  icon: const Icon(
                                    Icons.currency_exchange_rounded,
                                  ),
                                  label: const Text('Counter offer'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: GlPrimaryButton(
                                  label: 'Accept',
                                  isLoading: _busy,
                                  onPressed: _acceptOffer,
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          const Icon(
                            Icons.mark_chat_unread_outlined,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Waiting for admin negotiation message. '
                              'Actions will appear here once admin responds.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              '$e',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  ShipmentModel? _findShipment(List<ShipmentModel> shipments) {
    for (final s in shipments) {
      if (s.id == widget.shipmentId || s.publicId == widget.shipmentId) {
        return s;
      }
    }
    return null;
  }

  Map<String, dynamic>? _findActiveShipment(
    dynamic payload,
    ShipmentModel shipment,
  ) {
    if (payload is! List) return null;
    for (final item in payload) {
      if (item is! Map) continue;
      final map = item.cast<String, dynamic>();
      final publicId = map['publicId']?.toString();
      if (publicId == shipment.publicId || publicId == shipment.id) {
        return map;
      }
    }
    return null;
  }

  List<_TimelineItem> _buildRoundsTimeline(Map<String, dynamic>? s) {
    if (s == null) return const [];
    final out = <_TimelineItem>[];
    final offers = s['offers'];
    if (offers is List) {
      for (final item in offers) {
        if (item is! Map) continue;
        final offer = item.cast<String, dynamic>();
        out.add(
          _TimelineItem(
            round: _parseInt(offer['round']),
            actor: _actorFromActorType(offer['actorType']?.toString()),
            title: 'Round ${offer['round'] ?? '-'} offer',
            message: _offerMessage(offer),
            when: _parseDate(offer['offeredAt']),
            price: _parseNum(offer['priceAmount']),
          ),
        );
      }
    }
    out.sort((a, b) {
      final ar = a.round ?? 1 << 30;
      final br = b.round ?? 1 << 30;
      final roundCompare = ar.compareTo(br);
      if (roundCompare != 0) return roundCompare;
      final av = a.when?.millisecondsSinceEpoch ?? 0;
      final bv = b.when?.millisecondsSinceEpoch ?? 0;
      final timeCompare = av.compareTo(bv);
      if (timeCompare != 0) return timeCompare;
      return a.title.compareTo(b.title);
    });
    return out;
  }

  String _offerMessage(Map<String, dynamic> offer) {
    final parts = <String>[];
    final reason = offer['reason']?.toString();
    if (reason != null && reason.trim().isNotEmpty) {
      parts.add(reason.trim());
    }
    final vehicleType = offer['requiredVehicleType']?.toString();
    final vehicleNum = offer['requiredVehicleNumber']?.toString();
    if (vehicleType != null && vehicleType.trim().isNotEmpty) {
      parts.add(
        'Vehicle: $vehicleType${vehicleNum != null && vehicleNum.isNotEmpty ? ' x$vehicleNum' : ''}',
      );
    }
    final loading = offer['loadingDate']?.toString();
    final delivery = offer['deliveryDate']?.toString();
    if ((loading ?? '').isNotEmpty || (delivery ?? '').isNotEmpty) {
      parts.add('Schedule updated');
    }
    return parts.join(' • ');
  }

  DateTime? _parseDate(dynamic value) {
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  num? _parseNum(dynamic value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }

  int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  _TimelineActor _actorFromActorType(String? actorType) {
    final v = (actorType ?? '').toUpperCase();
    if (v == 'ADMIN') return _TimelineActor.admin;
    if (v == 'CONSIGNOR') return _TimelineActor.consignor;
    return _TimelineActor.system;
  }
}

enum _TimelineActor { consignor, admin, system }

class _TimelineItem {
  const _TimelineItem({
    this.round,
    required this.actor,
    required this.title,
    this.message,
    this.when,
    this.price,
  });

  final int? round;
  final _TimelineActor actor;
  final String title;
  final String? message;
  final DateTime? when;
  final num? price;
}
