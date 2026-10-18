import 'package:shared_preferences/shared_preferences.dart';

/// Persists in-progress registration until phone OTP is verified.
class PendingOtpRegistration {
  const PendingOtpRegistration({required this.phone, required this.role});

  final String phone;
  /// Always `DRIVER` for this app.
  final String role;
}

class RegistrationPreferences {
  RegistrationPreferences._();
  static final RegistrationPreferences instance = RegistrationPreferences._();

  static const _kPendingPhone = 'gl_pending_otp_phone';
  static const _kPendingRole = 'gl_pending_otp_role';

  Future<void> setPendingOtp({
    required String phone,
    required String role,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kPendingPhone, phone);
    await p.setString(_kPendingRole, role);
  }

  Future<PendingOtpRegistration?> getPendingOtp() async {
    final p = await SharedPreferences.getInstance();
    final phone = p.getString(_kPendingPhone);
    final role = p.getString(_kPendingRole);
    if (phone == null || phone.trim().isEmpty) return null;
    if (role == null || role.trim().isEmpty) return null;
    return PendingOtpRegistration(phone: phone.trim(), role: role.trim());
  }

  Future<void> clearPendingOtp() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kPendingPhone);
    await p.remove(_kPendingRole);
  }
}
