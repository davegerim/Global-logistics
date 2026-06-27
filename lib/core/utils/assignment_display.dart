import 'package:global_logistics_app/data/models/shipment_model.dart';

/// Display helpers for assignment labels in the UI (API calls still use UUIDs).
class AssignmentDisplay {
  AssignmentDisplay._();

  static final RegExp _uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  static bool isUuidLike(String? value) {
    final t = value?.trim();
    if (t == null || t.isEmpty) return false;
    return _uuid.hasMatch(t);
  }

  /// Zero-padded 3-digit sequence (e.g. `1` → `001`).
  static String formatSequenceNumber(int oneBasedIndex) {
    assert(oneBasedIndex >= 1);
    return oneBasedIndex.toString().padLeft(3, '0');
  }

  /// Pads numeric API display ids; leaves non-numeric values unchanged.
  static String formatDisplayNumber(String value) {
    final trimmed = value.trim();
    final n = int.tryParse(trimmed);
    if (n != null && n >= 0) {
      return n.toString().padLeft(3, '0');
    }
    return trimmed;
  }

  /// [prefix] is localized and includes trailing space (e.g. `Assignment `).
  static String sequenceLabel(String prefix, int oneBasedIndex) {
    assert(oneBasedIndex >= 1);
    return '$prefix${formatSequenceNumber(oneBasedIndex)}';
  }

  static int oneBasedIndexInOrder(
    List<String> orderedIds,
    String assignmentId,
  ) {
    final idx = orderedIds.indexOf(assignmentId);
    return idx < 0 ? 1 : idx + 1;
  }

  /// Driver assignment lists: use 1..n within a booking when it has multiple
  /// assignments; otherwise use the row's 1-based position in [items] so
  /// separate bookings do not all show `Assignment 001`.
  static List<ShipmentModel> withDriverListSequences(
    List<ShipmentModel> items,
  ) {
    if (items.isEmpty) return items;

    final countsByShipment = <String, int>{};
    for (final s in items) {
      final sid = s.id.trim();
      if (sid.isEmpty) continue;
      countsByShipment[sid] = (countsByShipment[sid] ?? 0) + 1;
    }

    final perShipment = <String, int>{};
    var globalIndex = 0;
    final out = <ShipmentModel>[];

    for (final s in items) {
      if (s.bookingId?.trim().isNotEmpty ?? false) {
        out.add(s);
        continue;
      }

      globalIndex++;
      final sid = s.id.trim();
      final assignmentsOnShipment = sid.isEmpty
          ? 1
          : (countsByShipment[sid] ?? 1);
      final perShipmentIndex = sid.isEmpty
          ? globalIndex
          : () {
              final next = (perShipment[sid] ?? 0) + 1;
              perShipment[sid] = next;
              return next;
            }();
      final seq = assignmentsOnShipment > 1 ? perShipmentIndex : globalIndex;
      out.add(s.copyWith(assignmentSequenceNumber: seq));
    }

    return out;
  }
}
