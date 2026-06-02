import 'package:global_logistics_app/core/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';
import 'package:global_logistics_app/core/errors/user_facing_error.dart';
import 'package:global_logistics_app/core/providers/consignor_active_provider.dart';
import 'package:global_logistics_app/core/providers/backend_api_provider.dart';
import 'package:global_logistics_app/core/providers/shipments_provider.dart';
import 'package:global_logistics_app/core/utils/negotiation_status_utils.dart';
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
    }, success: context.l10n.offerAccepted);
  }

  Future<void> _rejectOffer() async {
    final reason = await _promptText(
      title: context.l10n.rejectOffer,
      hint: context.l10n.reasonLabel,
      requiredField: true,
    );
    if (!mounted || reason == null) return;
    await _runAction(() async {
      await ref.read(backendApiProvider).shipmentsConsignorRejectOffer({
        'shipmentId': widget.shipmentId,
        'reason': reason,
      });
    }, success: context.l10n.offerRejected);
  }

  Future<void> _cancelShipment() async {
    final reason = await _promptText(
      title: context.l10n.cancelShipmentTitle,
      hint: context.l10n.reasonLabel,
      requiredField: true,
    );
    if (!mounted || reason == null) return;
    await _runAction(() async {
      await ref.read(backendApiProvider).shipmentsConsignorCancel({
        'shipmentId': widget.shipmentId,
        'reason': reason,
      });
    }, success: context.l10n.shipmentCancelled);
  }

  Future<void> _counterOffer() async {
    final shipment = ref
        .read(consignorShipmentsProvider)
        .maybeWhen(data: _findShipment, orElse: () => null);
    if (shipment == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.shipmentContextNotLoaded)),
        );
      }
      return;
    }
    final form = await _promptCounterOfferForm(shipment);
    if (!mounted || form == null) return;
    await _runAction(() async {
      await ref.read(backendApiProvider).shipmentsConsignorCounterOffer(form);
    }, success: context.l10n.counterOfferSent);
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
        ).showSnackBar(SnackBar(content: Text(userFacingMessage(e))));
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
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final v = c.text.trim();
              if (requiredField && v.isEmpty) return;
              Navigator.pop(ctx, v);
            },
            child: Text(context.l10n.sendButton),
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
    final displayFmt = DateFormat.yMMMd().add_jm();

    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        DateTime? loadingValue = DateTime.tryParse(loadingDate.text.trim());
        DateTime? deliveryValue = DateTime.tryParse(deliveryDate.text.trim());
        return StatefulBuilder(
          builder: (ctx, setSheetState) => Padding(
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
                    context.l10n.counterOfferTitle,
                    style: Theme.of(
                      ctx,
                    ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: price,
                    keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: context.l10n.counterPriceRequired,
                        hintText: context.l10n.egCounterPrice,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: vehicleType,
                      decoration: InputDecoration(
                        labelText: context.l10n.requiredVehicleTypeOptional,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: vehicleNumber,
                    keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: context.l10n.requiredVehicleNumberOptional,
                    ),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () async {
                      final picked = await _pickDateTime(
                        initial: loadingValue ?? shipment.placedAt,
                      );
                      if (picked == null) return;
                      setSheetState(() {
                        loadingValue = picked;
                        loadingDate.text = picked.toUtc().toIso8601String();
                      });
                    },
                    child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: context.l10n.loadingDateTime,
                        suffixIcon: Icon(Icons.schedule_rounded),
                      ),
                      child: Text(
                        loadingValue == null
                            ? context.l10n.selectLoadingDateTime
                            : displayFmt.format(loadingValue!.toLocal()),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () async {
                      final initialDate = deliveryValue ??
                          loadingValue ??
                          shipment.estimatedDelivery ??
                          shipment.placedAt.add(const Duration(days: 2));
                      final picked = await _pickDateTime(initial: initialDate);
                      if (picked == null) return;
                      setSheetState(() {
                        deliveryValue = picked;
                        deliveryDate.text = picked.toUtc().toIso8601String();
                      });
                    },
                    child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: context.l10n.deliveryDateTime,
                        suffixIcon: Icon(Icons.event_available_rounded),
                      ),
                      child: Text(
                        deliveryValue == null
                            ? context.l10n.selectDeliveryDateTime
                            : displayFmt.format(deliveryValue!.toLocal()),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: reason,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: context.l10n.reasonOptional,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GlPrimaryButton(
                    label: context.l10n.sendCounterOffer,
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
      },
    );
  }

  Future<DateTime?> _pickDateTime({required DateTime initial}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
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
        title: Text(context.l10n.negotiationRoom),
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
            return Center(child: Text(context.l10n.shipmentNotFound));
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
          final isSettled =
              isNegotiationSettled(status) || shipment.status == ShipmentStatus.completed;

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
                        '${context.l10n.statusPrefix}${context.translateDynamic(status)}'
                        '${latestPrice != null ? '  •  ${context.l10n.latestPrice} $latestPrice' : ''}',
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
                            context.l10n.noOfferRoundsYet,
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
                              ? AppColors.primarySoft
                              : AppColors.surface;
                          final textColor = mine
                              ? AppColors.primaryDark
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
                                    color: mine ? AppColors.primary.withValues(alpha: 0.2) : AppColors.borderLight,
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
                                          color: AppColors.primary,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          context.translateDynamic(_timelineActorTitle(e.actor)),
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
                                        context.translateDynamic(e.message!),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          height: 1.3,
                                          fontWeight: FontWeight.w500,
                                        ).copyWith(color: textColor.withValues(alpha: 0.9)),
                                      ),
                                    ],
                                    if (e.price != null) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        '${context.l10n.pricePrefix}${e.price}',
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
                                        e.when != null ? fmt.format(e.when!) : context.l10n.timeUnknown,
                                        style: const TextStyle(
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
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: FilledButton.icon(
                  onPressed: () => context.push(
                    '/consignor/shipment/${shipment.id}/history',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.history_rounded),
                  label: Text(context.l10n.openShipmentHistory),
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
                    : hasAdminEvent
                    ? Row(
                        children: [
                          Expanded(
                            child: _buildActionBtn(
                              icon: Icons.thumb_down_alt_outlined,
                              label: context.l10n.decline,
                              onPressed: _busy ? null : _rejectOffer,
                              isPrimary: false,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _buildActionBtn(
                              icon: Icons.cancel_outlined,
                              label: context.l10n.cancel,
                              onPressed: _busy ? null : _cancelShipment,
                              isPrimary: false,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _buildActionBtn(
                              icon: Icons.currency_exchange_rounded,
                              label: context.l10n.counter,
                              onPressed: _busy ? null : _counterOffer,
                              isPrimary: false,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _buildActionBtn(
                              icon: Icons.check_circle_outline,
                              label: context.l10n.accept,
                              onPressed: _busy ? null : _acceptOffer,
                              isPrimary: true,
                              isLoading: _busy,
                            ),
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
                              context.l10n.waitingForAdminMessage,
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
              userFacingMessage(e),
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
    if (parts.isEmpty) {
      final actor = (offer['actorType']?.toString() ?? '').toUpperCase();
      if (actor == 'ADMIN') return 'Admin updated the offer details.';
      if (actor == 'CONSIGNOR') return 'Consignor updated the offer details.';
      return 'Offer details updated.';
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

  String _timelineActorTitle(_TimelineActor actor) {
    switch (actor) {
      case _TimelineActor.admin:
        return context.l10n.adminMessage;
      case _TimelineActor.consignor:
        return context.l10n.consignorMessage;
      case _TimelineActor.system:
        return context.translateDynamic('System message');
    }
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
              context.l10n.settled,
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
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: content,
      );
    }
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
