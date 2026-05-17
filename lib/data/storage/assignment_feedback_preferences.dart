import 'package:shared_preferences/shared_preferences.dart';

/// Tracks one-time assignment feedback submissions (no GET endpoint on API).
class AssignmentFeedbackPreferences {
  AssignmentFeedbackPreferences._();
  static final AssignmentFeedbackPreferences instance =
      AssignmentFeedbackPreferences._();

  static const _kToConsignor = 'gl_feedback_to_consignor_ids';
  static const _kToDriver = 'gl_feedback_to_driver_ids';

  Future<bool> hasSubmittedToConsignor(String assignmentId) async {
    final ids = await _readIds(_kToConsignor);
    return ids.contains(assignmentId);
  }

  Future<void> markSubmittedToConsignor(String assignmentId) async {
    await _addId(_kToConsignor, assignmentId);
  }

  Future<bool> hasSubmittedToDriver(String assignmentId) async {
    final ids = await _readIds(_kToDriver);
    return ids.contains(assignmentId);
  }

  Future<void> markSubmittedToDriver(String assignmentId) async {
    await _addId(_kToDriver, assignmentId);
  }

  Future<Set<String>> _readIds(String key) async {
    final p = await SharedPreferences.getInstance();
    return p.getStringList(key)?.toSet() ?? {};
  }

  Future<void> _addId(String key, String assignmentId) async {
    final p = await SharedPreferences.getInstance();
    final ids = p.getStringList(key)?.toSet() ?? {};
    if (ids.add(assignmentId)) {
      await p.setStringList(key, ids.toList());
    }
  }
}

bool assignmentAllowsFeedback(String? apiStatus) {
  return (apiStatus ?? '').trim().toUpperCase() == 'CONSIGNOR_RECEIVED';
}
