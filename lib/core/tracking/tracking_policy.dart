String normalizeTrackingStatus(String? status) =>
    (status ?? '').trim().toUpperCase();

const Set<String> _driverTrackingSendStatuses = {
  'LOADED',
  'IN_TRANSIT',
  'ARRIVED',
  'OFFLOADED',
};

const Set<String> _driverTrackingBlockedStatuses = {
  'COMPLETED',
  'CONSIGNOR_RECEIVED',
  'CANCELLED',
  'CANCELLED_BY_CONSIGNOR',
  'CANCELLED_BY_ADMIN',
  'CANCELLED_SYSTEM',
};

bool isDriverTrackingBlockedStatus(String? status) {
  final normalized = normalizeTrackingStatus(status);
  return normalized.isEmpty ||
      _driverTrackingBlockedStatuses.contains(normalized);
}

bool canRunDriverTrackingLoop(String? status, {required bool hasGdn}) {
  return canSendDriverTrackingUpdate(status, hasGdn: hasGdn);
}

bool canSendDriverTrackingUpdate(String? status, {required bool hasGdn}) {
  if (!hasGdn || isDriverTrackingBlockedStatus(status)) return false;
  final normalized = normalizeTrackingStatus(status);
  return _driverTrackingSendStatuses.contains(normalized);
}
