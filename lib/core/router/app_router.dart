import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:global_logistics_app/core/providers/auth_provider.dart';
import 'package:global_logistics_app/core/utils/registration_flow_utils.dart';
import 'package:global_logistics_app/features/auth/forgot_password_screen.dart';
import 'package:global_logistics_app/features/auth/login_screen.dart';
import 'package:global_logistics_app/features/auth/register_driver_profile_screen.dart';
import 'package:global_logistics_app/features/auth/register_driver_screen.dart';
import 'package:global_logistics_app/features/auth/register_driver_vehicle_screen.dart';
import 'package:global_logistics_app/features/auth/register_driver_verify_screen.dart';
import 'package:global_logistics_app/features/driver/driver_assignment_history_screen.dart';
import 'package:global_logistics_app/features/driver/driver_home_screen.dart';
import 'package:global_logistics_app/features/driver/driver_license_details_screen.dart';
import 'package:global_logistics_app/features/driver/driver_offer_negotiation_screen.dart';
import 'package:global_logistics_app/features/driver/driver_offers_screen.dart';
import 'package:global_logistics_app/features/driver/driver_payouts_screen.dart';
import 'package:global_logistics_app/features/driver/driver_profile_screen.dart';
import 'package:global_logistics_app/features/driver/driver_shipment_detail_screen.dart';
import 'package:global_logistics_app/features/driver/driver_shell.dart';
import 'package:global_logistics_app/features/driver/driver_vehicle_details_screen.dart';
import 'package:global_logistics_app/features/notifications/notifications_screen.dart';
import 'package:global_logistics_app/features/splash/splash_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this.ref) {
    ref.listen(authProvider, (previous, next) => notifyListeners());
  }

  final Ref ref;
}

GlobalKey<NavigatorState> get rootNavigatorKey => _rootNavigatorKey;

final goRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final path = state.uri.path;

      if (path == '/onboarding' || path == '/role') {
        return '/login';
      }

      // Legacy consignor deep links → driver home.
      if (path.startsWith('/consignor') ||
          path.startsWith('/register-consignor')) {
        return auth.isAuthenticated ? '/driver/home' : '/login';
      }

      final otpRedirect = _otpVerifyRedirect(auth, path, state.uri);
      if (otpRedirect != null) {
        return otpRedirect;
      }

      final onboardingRedirect = RegistrationFlowUtils.onboardingRedirect(
        auth,
        path,
      );
      if (onboardingRedirect != null) {
        return onboardingRedirect;
      }

      final isPublic =
          path == '/splash' ||
          path == '/login' ||
          path == '/forgot-password' ||
          path == '/register-driver' ||
          path == '/register-driver-verify' ||
          path == '/register-driver-profile' ||
          path == '/register-driver-vehicle';

      if (!auth.isAuthenticated && !isPublic) {
        return '/login';
      }
      if (auth.isAuthenticated && auth.role == null) {
        return '/login';
      }
      if (auth.isAuthenticated && path == '/login') {
        return RegistrationFlowUtils.postAuthRoute(auth);
      }
      if (auth.isAuthenticated && path == '/splash') {
        return RegistrationFlowUtils.postAuthRoute(auth);
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) {
          final extra = state.extra;
          final phone = extra is Map<String, dynamic>
              ? (extra['phone'] as String? ?? '')
              : '';
          return ForgotPasswordScreen(initialPhone: phone);
        },
      ),
      GoRoute(
        path: '/register-driver',
        builder: (context, state) => const RegisterDriverScreen(),
      ),
      GoRoute(
        path: '/register-driver-verify',
        builder: (context, state) {
          final extra = state.extra;
          var phone = extra is Map<String, dynamic>
              ? (extra['phone'] as String? ?? '')
              : '';
          if (phone.isEmpty) {
            phone = state.uri.queryParameters['phone'] ?? '';
          }
          return RegisterDriverVerifyScreen(phone: phone);
        },
      ),
      GoRoute(
        path: '/register-driver-profile',
        builder: (context, state) => const RegisterDriverProfileScreen(),
      ),
      GoRoute(
        path: '/register-driver-vehicle',
        builder: (context, state) => const RegisterDriverVehicleScreen(),
      ),
      GoRoute(
        path: '/driver',
        redirect: (context, state) {
          if (state.fullPath == '/driver') {
            return '/driver/home';
          }
          return null;
        },
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) {
              return DriverShell(navigationShell: navigationShell);
            },
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: 'home',
                    pageBuilder: (context, state) =>
                        const NoTransitionPage(child: DriverHomeScreen()),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: 'offers',
                    pageBuilder: (context, state) =>
                        const NoTransitionPage(child: DriverOffersScreen()),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: 'profile',
                    pageBuilder: (context, state) =>
                        const NoTransitionPage(child: DriverProfileScreen()),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            parentNavigatorKey: _rootNavigatorKey,
            path: 'offers/:negotiationId/negotiation',
            builder: (context, state) {
              final negotiationId = state.pathParameters['negotiationId']!;
              return DriverOfferNegotiationScreen(negotiationId: negotiationId);
            },
          ),
          GoRoute(
            parentNavigatorKey: _rootNavigatorKey,
            path: 'shipment/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return DriverShipmentDetailScreen(shipmentId: id);
            },
          ),
          GoRoute(
            parentNavigatorKey: _rootNavigatorKey,
            path: 'assignments/history',
            builder: (context, state) => const DriverAssignmentHistoryScreen(),
          ),
          GoRoute(
            parentNavigatorKey: _rootNavigatorKey,
            path: 'profile/vehicle',
            builder: (context, state) => const DriverVehicleDetailsScreen(),
          ),
          GoRoute(
            parentNavigatorKey: _rootNavigatorKey,
            path: 'profile/license',
            builder: (context, state) => const DriverLicenseDetailsScreen(),
          ),
          GoRoute(
            parentNavigatorKey: _rootNavigatorKey,
            path: 'profile/payouts',
            builder: (context, state) => const DriverPayoutsScreen(),
          ),
          GoRoute(
            parentNavigatorKey: _rootNavigatorKey,
            path: 'notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
        ],
      ),
    ],
  );
});

String? _otpVerifyRedirect(AuthState auth, String path, Uri uri) {
  if (!auth.needsPhoneVerification) return null;
  final phone = auth.phone?.trim() ?? '';
  if (phone.isEmpty) return '/login';
  const otpPath = '/register-driver-verify';
  if (path == otpPath && uri.queryParameters['phone'] == phone) {
    return null;
  }
  return RegistrationFlowUtils.otpVerifyRoute(auth);
}
