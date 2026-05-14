import 'dart:convert';

/// Reads JWT `exp` claim (UTC). Does not verify the signature (same as typical
/// client-side expiry scheduling).
DateTime? readAccessTokenExpiryUtc(String? jwt) {
  if (jwt == null || jwt.isEmpty) return null;
  final parts = jwt.split('.');
  if (parts.length != 3) return null;
  try {
    final json =
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    final map = jsonDecode(json) as Map<String, dynamic>;
    final exp = map['exp'];
    if (exp is int) {
      return DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
    }
    if (exp is num) {
      return DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000, isUtc: true);
    }
    return null;
  } catch (_) {
    return null;
  }
}

/// Returns true when the token should be refreshed soon (or is already expired).
bool isAccessTokenExpiringSoon(
  String jwt, {
  Duration margin = const Duration(seconds: 120),
}) {
  final exp = readAccessTokenExpiryUtc(jwt);
  if (exp == null) return false;
  final now = DateTime.now().toUtc();
  if (!now.isBefore(exp)) return true;
  return exp.difference(now) <= margin;
}
