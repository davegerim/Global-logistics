import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:global_logistics_app/core/providers/auth_provider.dart';
import 'package:global_logistics_app/features/auth/forgot_password_screen.dart';
import 'package:global_logistics_app/features/auth/login_screen.dart';
import 'package:global_logistics_app/features/auth/register_consignor_screen.dart';
import 'package:global_logistics_app/features/auth/register_consignor_profile_screen.dart';
import 'package:global_logistics_app/features/auth/register_consignor_verify_screen.dart';
import 'package:global_logistics_app/features/auth/register_driver_profile_screen.dart';
import 'package:global_logistics_app/features/auth/register_driver_screen.dart';
import 'package:global_logistics_app/features/auth/register_driver_vehicle_screen.dart';
import 'package:global_logistics_app/features/auth/register_driver_verify_screen.dart';
import 'package:global_logistics_app/features/consignor/consignor_documents_screen.dart';
import 'package:global_logistics_app/features/consignor/consignor_gdn_form_screen.dart';
import 'package:global_logistics_app/features/consignor/consignor_grn_form_screen.dart';
import 'package:global_logistics_app/features/consignor/consignor_home_screen.dart';
import 'package:global_logistics_app/features/consignor/consignor_negotiation_screen.dart';
import 'package:global_logistics_app/features/consignor/consignor_profile_screen.dart';
import 'package:global_logistics_app/features/consignor/consignor_shipment_history_screen.dart';
import 'package:global_logistics_app/features/consignor/consignor_shipment_detail_screen.dart';
import 'package:global_logistics_app/features/consignor/consignor_shipments_screen.dart';
import 'package:global_logistics_app/features/consignor/consignor_shell.dart';
import 'package:global_logistics_app/features/consignor/create_booking_screen.dart';
import 'package:global_logistics_app/features/consignor/tracking_map_screen.dart';
import 'package:global_logistics_app/features/driver/driver_home_screen.dart';
import 'package:global_logistics_app/features/driver/driver_offer_negotiation_screen.dart';
import 'package:global_logistics_app/features/driver/driver_offers_screen.dart';
import 'package:global_logistics_app/features/driver/driver_profile_screen.dart';
import 'package:global_logistics_app/features/driver/driver_shipment_detail_screen.dart';
import 'package:global_logistics_app/features/driver/driver_shell.dart';
import 'package:global_logistics_app/features/onboarding/onboarding_screen.dart';
import 'package:global_logistics_app/features/role/role_selection_screen.dart';
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

      final isPublic =
          path == '/splash' ||
          path == '/onboarding' ||
          path == '/role' ||
          path == '/login' ||
          path == '/forgot-password' ||
          path == '/register-consignor' ||
          path == '/register-consignor-verify' ||
          path == '/register-consignor-profile' ||
          path == '/register-driver' ||
          path == '/register-driver-verify';

      if (!auth.isAuthenticated && !isPublic) {
        return '/login';
      }
      if (auth.isAuthenticated &&
          (path == '/login' || path == '/role' || path == '/onboarding')) {
        return auth.role == AppRole.driver ? '/driver/home' : '/consignor/home';
      }
      if (auth.isAuthenticated && path == '/splash') {
        return auth.role == AppRole.driver ? '/driver/home' : '/consignor/home';
      }
      if (auth.isAuthenticated &&
          auth.role == AppRole.consignor &&
          path.startsWith('/driver')) {
        return '/consignor/home';
      }
      if (auth.isAuthenticated &&
          auth.role == AppRole.driver &&
          path.startsWith('/consignor')) {
        return '/driver/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/role',
        builder: (context, state) => const RoleSelectionScreen(),
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
        path: '/register-consignor',
        builder: (context, state) => const RegisterConsignorScreen(),
      ),
      GoRoute(
        path: '/register-consignor-verify',
        builder: (context, state) {
          final extra = state.extra;
          final phone = extra is Map<String, dynamic>
              ? (extra['phone'] as String? ?? '')
              : '';
          return RegisterConsignorVerifyScreen(phone: phone);
        },
      ),
      GoRoute(
        path: '/register-consignor-profile',
        builder: (context, state) => const RegisterConsignorProfileScreen(),
      ),
      GoRoute(
        path: '/register-driver',
        builder: (context, state) => const RegisterDriverScreen(),
      ),
      GoRoute(
        path: '/register-driver-verify',
        builder: (context, state) {
          final extra = state.extra;
          final phone = extra is Map<String, dynamic>
              ? (extra['phone'] as String? ?? '')
              : '';
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
        path: '/consignor',
        redirect: (context, state) {
          if (state.fullPath == '/consignor') {
            return '/consignor/home';
          }
          return null;
        },
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) {
              return ConsignorShell(navigationShell: navigationShell);
            },
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: 'home',
                    pageBuilder: (context, state) =>
                        const NoTransitionPage(child: ConsignorHomeScreen()),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: 'shipments',
                    pageBuilder: (context, state) => const NoTransitionPage(
                      child: ConsignorShipmentsScreen(),
                    ),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: 'documents',
                    pageBuilder: (context, state) => const NoTransitionPage(
                      child: ConsignorDocumentsScreen(),
                    ),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: 'profile',
                    pageBuilder: (context, state) =>
                        const NoTransitionPage(child: ConsignorProfileScreen()),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            parentNavigatorKey: _rootNavigatorKey,
            path: 'shipment/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return ConsignorShipmentDetailScreen(shipmentId: id);
            },
          ),
          GoRoute(
            parentNavigatorKey: _rootNavigatorKey,
            path: 'shipment/:id/negotiation',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return ConsignorNegotiationScreen(shipmentId: id);
            },
          ),
          GoRoute(
            parentNavigatorKey: _rootNavigatorKey,
            path: 'shipment/:id/history',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return ConsignorShipmentHistoryScreen(shipmentId: id);
            },
          ),
          GoRoute(
            parentNavigatorKey: _rootNavigatorKey,
            path: 'shipment/:id/gdn',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              final assignmentId = state.uri.queryParameters['assignment'];
              final goodsDescription =
                  state.uri.queryParameters['goods'] ?? 'Shipment';
              if (assignmentId == null || assignmentId.isEmpty) {
                return const Scaffold(
                  body: Center(
                    child: Text('Assignment is required to create GDN.'),
                  ),
                );
              }
              return ConsignorGdnFormScreen(
                shipmentId: id,
                assignmentId: assignmentId,
                goodsDescription: goodsDescription,
              );
            },
          ),
          GoRoute(
            parentNavigatorKey: _rootNavigatorKey,
            path: 'shipment/:id/grn',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              final assignmentId = state.uri.queryParameters['assignment'];
              final assignmentStatus =
                  state.uri.queryParameters['status'] ?? '';
              if (assignmentId == null || assignmentId.isEmpty) {
                return const Scaffold(
                  body: Center(
                    child: Text('Assignment is required to create GRN.'),
                  ),
                );
              }
              return ConsignorGrnFormScreen(
                shipmentId: id,
                assignmentId: assignmentId,
                assignmentStatus: assignmentStatus,
              );
            },
          ),
          GoRoute(
            parentNavigatorKey: _rootNavigatorKey,
            path: 'create',
            builder: (context, state) => const CreateBookingScreen(),
          ),
          GoRoute(
            parentNavigatorKey: _rootNavigatorKey,
            path: 'track/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return TrackingMapScreen(shipmentId: id);
            },
          ),
        ],
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
        ],
      ),
    ],
  );
});
