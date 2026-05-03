import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_logistics_app/core/providers/backend_api_provider.dart';
import 'package:global_logistics_app/core/services/device_location_service.dart';
import 'package:global_logistics_app/data/storage/token_cache.dart';
import 'package:global_logistics_app/data/storage/token_storage.dart';

enum AppRole { consignor, driver }

class AuthState {
  const AuthState({
    this.isAuthenticated = false,
    this.role,
    this.displayName,
    this.phone,
    this.userPublicId,
    this.isLoading = false,
    this.bootstrapDone = false,
    this.errorMessage,
    this.rolesFromApi = const [],
    this.accountStatus,
    this.isConsignorApproved,
  });

  final bool isAuthenticated;
  final AppRole? role;
  final String? displayName;
  final String? phone;
  final String? userPublicId;
  final bool isLoading;
  final bool bootstrapDone;
  final String? errorMessage;
  final List<String> rolesFromApi;
  final String? accountStatus;
  final bool? isConsignorApproved;

  bool get canCreateConsignorBooking {
    if (role != AppRole.consignor) return true;
    final approved = isConsignorApproved;
    if (approved != null) return approved;
    final status = accountStatus?.trim().toUpperCase();
    if (status == null || status.isEmpty) return true;
    const approvedStatuses = {'APPROVED', 'ACTIVE'};
    const blockedStatuses = {
      'VERIFIED',
      'PENDING',
      'PENDING_APPROVAL',
      'UNDER_REVIEW',
      'SUSPENDED',
      'REJECTED',
      'INACTIVE',
      'NOT_APPROVED',
    };
    if (approvedStatuses.contains(status)) return true;
    if (blockedStatuses.contains(status)) return false;
    return true;
  }

  bool get canViewDriverOffers {
    if (role != AppRole.driver) return true;
    final status = accountStatus?.trim().toUpperCase();
    if (status == null || status.isEmpty) return false;
    const approvedStatuses = {'APPROVED', 'ACTIVE'};
    const blockedStatuses = {
      'VERIFIED',
      'PENDING',
      'PENDING_APPROVAL',
      'UNDER_REVIEW',
      'SUSPENDED',
      'REJECTED',
      'INACTIVE',
      'NOT_APPROVED',
    };
    if (approvedStatuses.contains(status)) return true;
    if (blockedStatuses.contains(status)) return false;
    return false;
  }

  AuthState copyWith({
    bool? isAuthenticated,
    AppRole? role,
    String? displayName,
    String? phone,
    String? userPublicId,
    bool? isLoading,
    bool? bootstrapDone,
    String? errorMessage,
    List<String>? rolesFromApi,
    String? accountStatus,
    bool? isConsignorApproved,
    bool clearError = false,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      role: role ?? this.role,
      displayName: displayName ?? this.displayName,
      phone: phone ?? this.phone,
      userPublicId: userPublicId ?? this.userPublicId,
      isLoading: isLoading ?? this.isLoading,
      bootstrapDone: bootstrapDone ?? this.bootstrapDone,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      rolesFromApi: rolesFromApi ?? this.rolesFromApi,
      accountStatus: accountStatus ?? this.accountStatus,
      isConsignorApproved: isConsignorApproved ?? this.isConsignorApproved,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  Future<void> bootstrap() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await TokenStorage.instance.loadIntoCache();
      if (TokenCache.instance.accessToken == null ||
          TokenCache.instance.accessToken!.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          bootstrapDone: true,
          isAuthenticated: false,
        );
        return;
      }
      final api = ref.read(backendApiProvider);
      final profile = await api.identityGet();
      _applyProfile(profile);
      await _sendInitialDriverTrackingPing();
      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        bootstrapDone: true,
      );
    } catch (_) {
      await TokenStorage.instance.clearPersisted();
      state = state.copyWith(
        isLoading: false,
        bootstrapDone: true,
        isAuthenticated: false,
      );
    }
  }

  void _applyProfile(Map<String, dynamic> p) {
    final roles =
        (p['roles'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];
    final fn = p['firstName'] as String? ?? '';
    final ln = p['lastName'] as String? ?? '';
    final name = '$fn $ln'.trim();
    final status = _extractStatus(p);
    final approved = _extractApproved(p);
    state = state.copyWith(
      displayName: name.isEmpty ? (p['phone'] as String? ?? 'User') : name,
      phone: p['phone'] as String?,
      userPublicId: p['publicId'] as String?,
      rolesFromApi: roles,
      role: _pickRole(roles),
      accountStatus: status,
      isConsignorApproved: approved,
    );
  }

  String? _extractStatus(Map<String, dynamic> p) {
    final candidates = [
      p['status'],
      p['accountStatus'],
      p['verificationStatus'],
      p['approvalStatus'],
    ];
    for (final value in candidates) {
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  bool? _extractApproved(Map<String, dynamic> p) {
    final candidates = [p['approved'], p['isApproved'], p['consignorApproved']];
    for (final value in candidates) {
      if (value is bool) return value;
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (normalized == 'true') return true;
        if (normalized == 'false') return false;
      }
    }
    return null;
  }

  AppRole? _pickRole(List<String> roles) {
    if (roles.any((r) => r == 'DRIVER')) return AppRole.driver;
    if (roles.any((r) => r == 'CONSIGNOR')) return AppRole.consignor;
    if (roles.any((r) => r == 'ADMIN' || r == 'SUPER_ADMIN')) {
      return AppRole.consignor;
    }
    return AppRole.consignor;
  }

  /// [intendedRole] is used when the user tapped Driver vs Consignor on login screen
  /// (profile still decides API access; this only affects default tab if both roles exist).
  Future<void> login({
    required String phone,
    required String password,
    AppRole? intendedRole,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final api = ref.read(backendApiProvider);
      final data = await api.authLogin(phone: phone, password: password);
      final access = data['accessToken'] as String?;
      final refresh = data['refreshToken'] as String?;
      if (access != null) {
        await TokenStorage.instance.persistTokens(
          access: access,
          refresh: refresh,
        );
      }
      final profile = await api.identityGet();
      _applyProfile(profile);
      if (intendedRole != null &&
          state.rolesFromApi.contains(
            intendedRole == AppRole.driver ? 'DRIVER' : 'CONSIGNOR',
          )) {
        state = state.copyWith(role: intendedRole);
      }
      await _sendInitialDriverTrackingPing();
      state = state.copyWith(isAuthenticated: true, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _formatError(e));
    }
  }

  Future<void> _sendInitialDriverTrackingPing() async {
    if (state.role != AppRole.driver) return;
    try {
      final api = ref.read(backendApiProvider);
      final assignments = await api.assignmentsDriver();
      if (assignments.isEmpty || assignments.first is! Map) return;
      final first = (assignments.first as Map).cast<String, dynamic>();
      final assignmentId =
          (first['publicId'] as String?) ??
          (first['assignmentId'] as String?) ??
          (first['id'] as String?);
      if (assignmentId == null || assignmentId.trim().isEmpty) return;
      final location = await DeviceLocationService.current();
      final recordedAt = DateTime.fromMillisecondsSinceEpoch(
        DateTime.now().toUtc().millisecondsSinceEpoch,
        isUtc: true,
      ).toIso8601String();
      await api.trackingRecord({
        'assignmentId': assignmentId,
        'latitude': location.latitude,
        'longitude': location.longitude,
        'accuracy': location.accuracy,
        'speed': location.speed,
        'recordedAt': recordedAt,
      });
      debugPrint(
        '[TRACKING] sent (login-initial) for assignment=$assignmentId',
      );
    } catch (e) {
      // Tracking ping must never block successful login.
      debugPrint('[TRACKING] skipped (login-initial): $e');
    }
  }

  Future<void> register({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String role,
    required String password,
    required String confirmPassword,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final api = ref.read(backendApiProvider);
      await api.authRegister(
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        role: role,
        password: password,
        confirmPassword: confirmPassword,
      );
      state = state.copyWith(isLoading: false, clearError: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _formatError(e));
      rethrow;
    }
  }

  Future<void> verifyOtp({required String phone, required String code}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final api = ref.read(backendApiProvider);
      final data = await api.authOtpVerify(phone: phone, code: code);
      final access = data['accessToken'] as String?;
      final refresh = data['refreshToken'] as String?;
      if (access != null) {
        await TokenStorage.instance.persistTokens(
          access: access,
          refresh: refresh,
        );
      }
      final profile = await api.identityGet();
      _applyProfile(profile);
      await _sendInitialDriverTrackingPing();
      state = state.copyWith(isAuthenticated: true, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _formatError(e));
      rethrow;
    }
  }

  Future<void> logout() async {
    final rt = TokenCache.instance.refreshToken;
    try {
      if (rt != null && rt.isNotEmpty) {
        await ref.read(backendApiProvider).authLogout(rt);
      }
    } catch (_) {}
    await TokenStorage.instance.clearPersisted();
    state = AuthState(bootstrapDone: true);
  }

  String _formatError(Object e) => e.toString();
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
