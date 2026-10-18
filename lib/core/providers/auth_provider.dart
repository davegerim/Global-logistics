import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_logistics_app/core/network/auth_response_tokens.dart';
import 'package:global_logistics_app/core/network/token_refresh_executor.dart';
import 'package:global_logistics_app/core/errors/user_facing_error.dart';
import 'package:global_logistics_app/core/providers/backend_api_provider.dart';
import 'package:global_logistics_app/core/tracking/driver_location_tracking.dart';
import 'package:global_logistics_app/core/tracking/tracking_policy.dart';
import 'package:global_logistics_app/data/storage/app_launch_preferences.dart';
import 'package:global_logistics_app/data/storage/registration_preferences.dart';
import 'package:global_logistics_app/core/utils/registration_flow_utils.dart';
import 'package:global_logistics_app/data/storage/token_cache.dart';
import 'package:global_logistics_app/data/storage/token_storage.dart';

enum AppRole { driver }

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
    this.needsPhoneVerification = false,
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
  final bool needsPhoneVerification;

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
    bool? needsPhoneVerification,
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
      needsPhoneVerification:
          needsPhoneVerification ?? this.needsPhoneVerification,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  StreamSubscription<String>? _fcmRefreshSub;

  @override
  AuthState build() => const AuthState();

  Future<void> bootstrap() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await TokenStorage.instance.loadIntoCache();
      var pending = await RegistrationPreferences.instance.getPendingOtp();
      if (pending != null &&
          pending.role.trim().toUpperCase() != 'DRIVER') {
        await RegistrationPreferences.instance.clearPendingOtp();
        pending = null;
      }
      final cache = TokenCache.instance;
      if (cache.accessToken == null || cache.accessToken!.isEmpty) {
        final rt = cache.refreshToken;
        if (rt != null && rt.isNotEmpty) {
          final newAccess = await executeTokenRefresh(rt);
          if (newAccess == null || newAccess.isEmpty) {
            await TokenStorage.instance.clearPersisted();
            if (pending != null) {
              _setPendingPhoneVerification(pending);
              return;
            }
            state = state.copyWith(
              isLoading: false,
              bootstrapDone: true,
              isAuthenticated: false,
            );
            return;
          }
        } else {
          if (pending != null) {
            _setPendingPhoneVerification(pending);
            return;
          }
          state = state.copyWith(
            isLoading: false,
            bootstrapDone: true,
            isAuthenticated: false,
          );
          return;
        }
      }
      final api = ref.read(backendApiProvider);
      late Map<String, dynamic> profile;
      for (var attempt = 0; attempt < 3; attempt++) {
        try {
          profile = await api.identityGet();
          break;
        } catch (e) {
          if (attempt < 2 && _isBootstrapTransientFailure(e)) {
            await Future<void>.delayed(
              Duration(milliseconds: 400 * (attempt + 1)),
            );
            continue;
          }
          rethrow;
        }
      }
      await _establishSession(
        profile: profile,
        pending: pending,
        markBootstrapDone: true,
      );
    } catch (e) {
      final code = e is DioException ? e.response?.statusCode : null;
      if (code == 401 || code == 403) {
        await TokenStorage.instance.clearPersisted();
      }
      await _stopFcmTokenRefreshListener();
      var pending = await RegistrationPreferences.instance.getPendingOtp();
      if (pending != null &&
          pending.role.trim().toUpperCase() != 'DRIVER') {
        await RegistrationPreferences.instance.clearPendingOtp();
        pending = null;
      }
      if (pending != null) {
        _setPendingPhoneVerification(pending);
        return;
      }
      state = state.copyWith(
        isLoading: false,
        bootstrapDone: true,
        isAuthenticated: false,
      );
    }
  }

  bool _isBootstrapTransientFailure(Object e) {
    if (e is! DioException) return false;
    final code = e.response?.statusCode;
    if (code != null && code >= 500) return true;
    if (e.response != null) return false;
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      default:
        return false;
    }
  }

  void _applyProfile(Map<String, dynamic> p) {
    final roles =
        (p['roles'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];
    final fn = p['firstName'] as String? ?? '';
    final ln = p['lastName'] as String? ?? '';
    final name = '$fn $ln'.trim();
    final status = RegistrationFlowUtils.extractStatus(p);
    state = state.copyWith(
      displayName: name.isEmpty ? (p['phone'] as String? ?? 'User') : name,
      phone: p['phone'] as String?,
      userPublicId: p['publicId'] as String?,
      rolesFromApi: roles,
      role: _pickRole(roles),
      accountStatus: status,
    );
  }

  bool? _extractPhoneVerified(Map<String, dynamic> p) {
    final candidates = [
      p['phoneVerified'],
      p['isPhoneVerified'],
      p['phone_verified'],
      p['is_phone_verified'],
    ];
    for (final value in candidates) {
      if (value is bool) return value;
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (normalized == 'true' || normalized == 'verified') return true;
        if (normalized == 'false' || normalized == 'unverified') return false;
      }
    }
    return null;
  }

  void _setPendingPhoneVerification(PendingOtpRegistration pending) {
    state = state.copyWith(
      needsPhoneVerification: true,
      phone: pending.phone,
      role: AppRole.driver,
      isAuthenticated: false,
      isLoading: false,
      bootstrapDone: true,
    );
  }

  AppRole? _pickRole(List<String> roles) {
    final normalized = roles.map((r) => r.trim().toUpperCase()).toList();
    if (normalized.contains('DRIVER')) return AppRole.driver;
    return null;
  }

  bool _hasAppEligibleRole(List<String> roles) {
    final normalized = roles.map((r) => r.trim().toUpperCase()).toList();
    return normalized.contains('DRIVER');
  }

  Future<void> _establishSession({
    required Map<String, dynamic> profile,
    Map<String, dynamic>? authResponse,
    PendingOtpRegistration? pending,
    AppRole? intendedRole,
    String? loginPhone,
    bool markBootstrapDone = false,
  }) async {
    _applyProfile(profile);
    final phoneVerified = _extractPhoneVerified(profile);
    final responseStatus = authResponse != null
        ? RegistrationFlowUtils.extractStatus(authResponse)
        : null;
    if (responseStatus != null) {
      final profileStatus = RegistrationFlowUtils.normalizeStatus(
        RegistrationFlowUtils.extractStatus(profile),
      );
      final shouldPreferProfile = phoneVerified == true ||
          (profileStatus != null &&
              profileStatus != RegistrationFlowUtils.notVerified);
      if (!shouldPreferProfile) {
        state = state.copyWith(accountStatus: responseStatus);
      }
    }
    if (!_hasAppEligibleRole(state.rolesFromApi)) {
      await _rejectIneligibleAccount();
      return;
    }
    if (intendedRole == AppRole.driver &&
        state.rolesFromApi
            .map((r) => r.trim().toUpperCase())
            .contains('DRIVER')) {
      state = state.copyWith(role: AppRole.driver);
    }
    if (RegistrationFlowUtils.needsOtpVerification(
      status: state.accountStatus,
      phoneVerified: phoneVerified,
      hasPendingOtp: pending != null,
    )) {
      final otpPhone = pending?.phone ?? state.phone ?? loginPhone ?? '';
      _setPendingPhoneVerification(
        pending ??
            PendingOtpRegistration(
              phone: otpPhone,
              role: 'DRIVER',
            ),
      );
      return;
    }
    if (pending != null) {
      await RegistrationPreferences.instance.clearPendingOtp();
    }
    await _sendInitialDriverTrackingPing();
    await _registerFcmTokenIfPossible();
    _ensureFcmTokenRefreshListener();
    await AppLaunchPreferences.instance.setIntroWalkthroughDone();
    state = state.copyWith(
      isAuthenticated: true,
      isLoading: false,
      bootstrapDone: markBootstrapDone ? true : state.bootstrapDone,
      needsPhoneVerification: false,
    );
  }

  Future<void> _rejectIneligibleAccount() async {
    await _stopFcmTokenRefreshListener();
    await TokenStorage.instance.clearPersisted();
    state = AuthState(
      bootstrapDone: true,
      isLoading: false,
      errorMessage: ineligibleAppRoleMessage,
    );
  }

  /// [intendedRole] is always driver for this app; kept for call-site compatibility.
  Future<void> login({
    required String phone,
    required String password,
    AppRole? intendedRole,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final api = ref.read(backendApiProvider);
      final data = await api.authLogin(phone: phone, password: password);
      final access = readAccessTokenFromBody(data);
      final refresh = readRefreshTokenFromBody(data);
      if (access != null || refresh != null) {
        await TokenStorage.instance.persistTokens(
          access: access,
          refresh: refresh,
        );
      }
      if (TokenCache.instance.accessToken == null ||
          TokenCache.instance.accessToken!.isEmpty) {
        final rt = TokenCache.instance.refreshToken;
        if (rt != null && rt.isNotEmpty) {
          await executeTokenRefresh(rt);
        }
      }
      final profile = await api.identityGet();
      final pending = await RegistrationPreferences.instance.getPendingOtp();
      await _establishSession(
        profile: profile,
        authResponse: data,
        pending: pending,
        intendedRole: intendedRole,
        loginPhone: phone,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _formatError(e));
    }
  }

  Future<void> _sendInitialDriverTrackingPing() async {
    if (state.role != AppRole.driver) return;
    try {
      final api = ref.read(backendApiProvider);
      final assignments = await api.assignmentsDriver();
      for (final raw in assignments) {
        if (raw is! Map) continue;
        final assignment = raw.cast<String, dynamic>();
        final candidateId = assignmentIdFromMap(assignment);
        if (candidateId == null) continue;
        final status = assignmentStatusFromMap(assignment);
        final gdns = await api.gdnOfAssignment(candidateId);
        if (!canSendDriverTrackingUpdate(
          status,
          hasGdn: assignmentHasActiveGdn(gdns),
        )) {
          continue;
        }
        await sendDriverTrackingRecord(
          api,
          candidateId,
          reason: 'login-initial',
        );
        return;
      }
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
      await RegistrationPreferences.instance.setPendingOtp(
        phone: phoneNumber,
        role: role,
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
      final access = readAccessTokenFromBody(data);
      final refresh = readRefreshTokenFromBody(data);
      if (access != null || refresh != null) {
        await TokenStorage.instance.persistTokens(
          access: access,
          refresh: refresh,
        );
      }
      if (TokenCache.instance.accessToken == null ||
          TokenCache.instance.accessToken!.isEmpty) {
        final rt = TokenCache.instance.refreshToken;
        if (rt != null && rt.isNotEmpty) {
          await executeTokenRefresh(rt);
        }
      }
      final profile = await api.identityGet();
      await RegistrationPreferences.instance.clearPendingOtp();
      await _establishSession(
        profile: profile,
        authResponse: data,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _formatError(e));
      rethrow;
    }
  }

  Future<void> sendOtp(String phone) async {
    await ref.read(backendApiProvider).authOtpSend(phone);
  }

  Future<void> refreshProfile() async {
    try {
      final profile = await ref.read(backendApiProvider).identityGet();
      _applyProfile(profile);
    } catch (_) {}
  }

  Future<void> logout() async {
    final cache = TokenCache.instance;
    final hasSession =
        (cache.accessToken != null && cache.accessToken!.isNotEmpty) ||
        (cache.refreshToken != null && cache.refreshToken!.isNotEmpty);
    try {
      if (hasSession) {
        await ref.read(backendApiProvider).authLogout();
      }
    } catch (_) {}
    await _stopFcmTokenRefreshListener();
    await RegistrationPreferences.instance.clearPendingOtp();
    await TokenStorage.instance.clearPersisted();
    state = AuthState(bootstrapDone: true);
  }

  Future<void> _registerFcmTokenIfPossible() async {
    final userId = state.userPublicId;
    if (userId == null || userId.trim().isEmpty) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.trim().isEmpty) return;
      await ref
          .read(backendApiProvider)
          .fcmTokenRegister(userId: userId, fcmToken: token);
      debugPrint('[FCM] registered token for userId=$userId');
    } catch (e) {
      // FCM registration must never block successful login/bootstrap.
      debugPrint('[FCM] token registration skipped: $e');
    }
  }

  void _ensureFcmTokenRefreshListener() {
    if (_fcmRefreshSub != null) return;
    _fcmRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen((
      newToken,
    ) async {
      final userId = state.userPublicId;
      if (userId == null || userId.trim().isEmpty) return;
      if (newToken.trim().isEmpty) return;
      try {
        await ref
            .read(backendApiProvider)
            .fcmTokenRegister(userId: userId, fcmToken: newToken);
        debugPrint('[FCM] updated token (rotation) for userId=$userId');
      } catch (e) {
        debugPrint('[FCM] token rotation update skipped: $e');
      }
    });
  }

  Future<void> _stopFcmTokenRefreshListener() async {
    final sub = _fcmRefreshSub;
    _fcmRefreshSub = null;
    await sub?.cancel();
  }

  String _formatError(Object e) => userFacingMessage(e);
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
