import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';
import 'package:global_logistics_app/core/errors/user_facing_error.dart';
import 'package:global_logistics_app/core/providers/consignor_active_provider.dart';
import 'package:intl/intl.dart';

class ConsignorShipmentHistoryScreen extends ConsumerWidget {
  const ConsignorShipmentHistoryScreen({super.key, required this.shipmentId});

  final String shipmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(consignorActiveProvider);
    final fmt = DateFormat.yMMMd().add_jm();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Shipment history'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(consignorActiveProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: active.when(
        data: (data) {
          final shipment = _findActiveShipment(data);
          if (shipment == null) {
            return const Center(child: Text('Shipment not found'));
          }
          final history = _statusHistory(shipment);
          if (history.isEmpty) {
            return const Center(child: Text('No shipment history yet.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            itemCount: history.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = history[index];
              final status = item['status']?.toString() ?? 'Status update';
              final reason = item['reason']?.toString();
              final actor = item['actorType']?.toString() ?? 'SYSTEM';
              final when = _parseDate(item['changedAt']);

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (reason != null && reason.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(reason),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      '$actor${when != null ? ' • ${fmt.format(when)}' : ''}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, stackTrace) => Center(child: Text(userFacingMessage(e))),
      ),
    );
  }

  Map<String, dynamic>? _findActiveShipment(dynamic payload) {
    if (payload is! List) return null;
    for (final item in payload) {
      if (item is! Map) continue;
      final map = item.cast<String, dynamic>();
      final publicId = map['publicId']?.toString();
      if (publicId == shipmentId) return map;
    }
    return null;
  }

  List<Map<String, dynamic>> _statusHistory(Map<String, dynamic> shipment) {
    final raw = shipment['statusHistory'];
    if (raw is! List) return const [];
    final out = <Map<String, dynamic>>[];
    for (final item in raw) {
      if (item is Map) out.add(item.cast<String, dynamic>());
    }
    out.sort((a, b) {
      final av = _parseDate(a['changedAt'])?.millisecondsSinceEpoch ?? 0;
      final bv = _parseDate(b['changedAt'])?.millisecondsSinceEpoch ?? 0;
      return bv.compareTo(av);
    });
    return out;
  }

  DateTime? _parseDate(dynamic value) {
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
