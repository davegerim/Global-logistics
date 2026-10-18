import 'package:global_logistics_app/core/providers/auth_provider.dart';

/// Routes users through registration based on account status from auth APIs.
abstract final class RegistrationFlowUtils {
  static const notVerified = 'NOT_VERIFIED';
  static const verified = 'VERIFIED';
  static const profileCreated = 'PROFILE_CREATED';
  static const pending = 'PENDING';

  static String? normalizeStatus(String? status) {
    final trimmed = status?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed.toUpperCase();
  }

  static String? extractStatus(Map<String, dynamic> data) {
    final candidates = [
      data['status'],
      data['accountStatus'],
      data['verificationStatus'],
      data['approvalStatus'],
    ];
    for (final value in candidates) {
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return normalizeStatus(text);
    }
    return null;
  }

  static bool needsOtpVerification({
    required String? status,
    bool? phoneVerified,
    bool hasPendingOtp = false,
  }) {
    if (hasPendingOtp) return true;
    if (phoneVerified == true) return false;
    final normalized = normalizeStatus(status);
    if (normalized == notVerified) return true;
    if (normalized == null) return phoneVerified == false;
    return false;
  }

  static bool needsProfileRegistration(String? status) =>
      normalizeStatus(status) == verified;

  static bool needsVehicleRegistration(String? status, AppRole? role) =>
      role == AppRole.driver && normalizeStatus(status) == profileCreated;

  static String otpVerifyRoute(AuthState auth, {bool autoResend = true}) {
    final phone = auth.phone?.trim() ?? '';
    if (phone.isEmpty) return '/login';
    final resend = autoResend ? '&resend=1' : '';
    return '/register-driver-verify?phone=${Uri.encodeComponent(phone)}$resend';
  }

  /// Previous registration step before the profile/vehicle screens.
  static String previousRegistrationStep(AuthState auth) {
    final status = normalizeStatus(auth.accountStatus);
    if (status == profileCreated && auth.role == AppRole.driver) {
      return '/register-driver-profile';
    }
    final phone = auth.phone?.trim() ?? '';
    if (phone.isEmpty) return '/register-driver';
    return otpVerifyRoute(auth, autoResend: false);
  }

  static String registrationEntryRoute(AuthState? auth) => '/register-driver';

  static String postAuthRoute(AuthState auth) {
    final status = normalizeStatus(auth.accountStatus);
    if (status == verified) return '/register-driver-profile';
    if (status == profileCreated && auth.role == AppRole.driver) {
      return '/register-driver-vehicle';
    }
    return '/driver/home';
  }

  static String? onboardingRedirect(AuthState auth, String path) {
    if (!auth.isAuthenticated) return null;
    final status = normalizeStatus(auth.accountStatus);

    if (status == verified) {
      const target = '/register-driver-profile';
      if (path == target) return null;
      if (path.startsWith('/driver') ||
          path == '/login' ||
          path == '/splash') {
        return target;
      }
    }

    if (status == profileCreated && auth.role == AppRole.driver) {
      if (path == '/register-driver-vehicle') return null;
      if (path.startsWith('/driver') ||
          path == '/login' ||
          path == '/splash' ||
          path == '/register-driver-profile') {
        return '/register-driver-vehicle';
      }
    }

    return null;
  }
}
