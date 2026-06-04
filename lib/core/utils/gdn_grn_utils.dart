import 'package:flutter/material.dart';

/// Whether a GDN/GRN API row or [DocumentRef.status] is voided.
bool isGdnGrnVoided(String? status) {
  final s = status?.trim().toUpperCase();
  return s == 'VOID' || s == 'VOIDED';
}

bool isGdnGrnVoidedMap(Map<String, dynamic> m) =>
    isGdnGrnVoided(m['status']?.toString());

/// Newest document in [list] (includes voided).
Map<String, dynamic> pickLatestGdnGrnMap(
  List<dynamic> list,
  List<String> dateKeys,
) {
  Map<String, dynamic>? best;
  DateTime? bestTime;
  for (final e in list) {
    if (e is! Map) continue;
    final m = Map<String, dynamic>.from(e);
    DateTime? t;
    for (final k in dateKeys) {
      final v = m[k];
      if (v != null) {
        t = DateTime.tryParse(v.toString());
        if (t != null) break;
      }
    }
    if (best == null) {
      best = m;
      bestTime = t;
      continue;
    }
    if (t != null && (bestTime == null || t.isAfter(bestTime))) {
      best = m;
      bestTime = t;
    }
  }
  return best ?? {};
}

/// Newest non-void document, if any.
Map<String, dynamic>? pickLatestActiveGdnGrnMap(
  List<dynamic> list,
  List<String> dateKeys,
) {
  final active = list
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .where((m) => !isGdnGrnVoidedMap(m))
      .toList();
  if (active.isEmpty) return null;
  return pickLatestGdnGrnMap(active, dateKeys);
}

bool hasActiveGdnGrn(List<dynamic> list) =>
    list.any((e) => e is Map && !isGdnGrnVoidedMap(Map<String, dynamic>.from(e)));

/// All rows newest-first for history UI.
List<Map<String, dynamic>> sortGdnGrnHistory(
  List<dynamic> list,
  List<String> dateKeys,
) {
  final rows = list
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
  rows.sort((a, b) {
    DateTime? ta;
    DateTime? tb;
    for (final k in dateKeys) {
      ta ??= DateTime.tryParse(a[k]?.toString() ?? '');
      tb ??= DateTime.tryParse(b[k]?.toString() ?? '');
    }
    final da = ta ?? DateTime.fromMillisecondsSinceEpoch(0);
    final db = tb ?? DateTime.fromMillisecondsSinceEpoch(0);
    return db.compareTo(da);
  });
  return rows;
}

String gdnGrnPublicId(Map<String, dynamic> m) {
  final pid = m['publicId']?.toString().trim();
  if (pid != null && pid.isNotEmpty) return pid;
  return m['id']?.toString().trim() ?? '';
}

int parseGdnGrnInt(String raw, {int fallback = 0}) =>
    int.tryParse(raw.trim()) ?? fallback;

Map<String, dynamic> buildGdnCreateBody({
  required String assignmentId,
  required String issuersName,
  required String consigneeName,
  required String consigneeContact,
  required String quantityText,
  required String goodsDescription,
  String? weight,
  String? volume,
  String? packagingType,
  String? remarks,
}) {
  return {
    'assignmentId': assignmentId,
    'issuersName': issuersName,
    'consigneeName': consigneeName,
    'consigneeContact': consigneeContact,
    'quantity': parseGdnGrnInt(quantityText, fallback: 1),
    if (weight != null && weight.isNotEmpty) 'weight': weight,
    if (volume != null && volume.isNotEmpty) 'volume': volume,
    if (packagingType != null && packagingType.isNotEmpty)
      'packagingType': packagingType,
    'goodsDescription': goodsDescription,
    if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
  };
}

Map<String, dynamic> buildGrnCreateBody({
  required String assignmentId,
  required String receiverName,
  required String receivedQuantityText,
  required String receivedAt,
  String? receivedWeight,
  String? receivedVolume,
  int damageQuantity = 0,
  int shortageQuantity = 0,
  String? conditionNote,
}) {
  return {
    'assignmentId': assignmentId,
    'receiverName': receiverName,
    'receivedQuantity': parseGdnGrnInt(receivedQuantityText, fallback: 1),
    if (receivedWeight != null && receivedWeight.isNotEmpty)
      'receivedWeight': receivedWeight,
    if (receivedVolume != null && receivedVolume.isNotEmpty)
      'receivedVolume': receivedVolume,
    'damageQuantity': damageQuantity,
    'shortageQuantity': shortageQuantity,
    if (conditionNote != null && conditionNote.isNotEmpty)
      'conditionNote': conditionNote,
    'receivedAt': receivedAt,
  };
}

Future<String?> showVoidGdnGrnReasonDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String reasonLabel,
  required String cancelLabel,
  required String confirmLabel,
}) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => _VoidGdnGrnReasonDialog(
      title: title,
      message: message,
      reasonLabel: reasonLabel,
      cancelLabel: cancelLabel,
      confirmLabel: confirmLabel,
    ),
  );
}

/// Owns the reason [TextEditingController] so it is disposed with the route.
class _VoidGdnGrnReasonDialog extends StatefulWidget {
  const _VoidGdnGrnReasonDialog({
    required this.title,
    required this.message,
    required this.reasonLabel,
    required this.cancelLabel,
    required this.confirmLabel,
  });

  final String title;
  final String message;
  final String reasonLabel;
  final String cancelLabel;
  final String confirmLabel;

  @override
  State<_VoidGdnGrnReasonDialog> createState() => _VoidGdnGrnReasonDialogState();
}

class _VoidGdnGrnReasonDialogState extends State<_VoidGdnGrnReasonDialog> {
  final _reasonCtrl = TextEditingController();

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.message),
          const SizedBox(height: 16),
          TextField(
            controller: _reasonCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: widget.reasonLabel,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.cancelLabel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_reasonCtrl.text.trim()),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
