import 'package:global_logistics_app/core/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_logistics_app/core/providers/auth_provider.dart';
import 'package:global_logistics_app/core/providers/driver_tracking_provider.dart';
import 'package:global_logistics_app/core/providers/locale_provider.dart';
import 'package:global_logistics_app/core/router/app_router.dart';
import 'package:global_logistics_app/core/theme/app_theme.dart';

class GlobalLogisticsApp extends ConsumerWidget {
  const GlobalLogisticsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    if (auth.isAuthenticated && auth.role == AppRole.driver) {
      ref.watch(driverTrackingControllerProvider);
    }
    final router = ref.watch(goRouterProvider);
    final locale = ref.watch(localeProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.globalLogisticsPlc,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
