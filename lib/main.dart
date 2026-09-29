import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'core/app_bootstrapper.dart';
import 'core/realtime_client.dart';
import 'l10n/generated/app_localizations.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/connection_status_service.dart';
import 'services/data_sync_service.dart';
import 'services/locale_provider.dart';
import 'services/notifications_controller.dart';
import 'services/notifications_service.dart';
import 'services/offers_service.dart';
import 'services/offline_sync_service.dart';
import 'services/quotations_service.dart';
import 'services/reference_cache.dart';
import 'services/sales_orders_service.dart';
import 'theme/app_theme.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // A build-time error anywhere in the tree used to leave a blank/black
    // frame with no way forward — this swaps in a visible, restartable
    // screen instead, and logs errors that Flutter would otherwise only
    // print once and lose.
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      debugPrint('[FlutterError] ${details.exceptionAsString()}');
    };
    ErrorWidget.builder = _startupErrorBuilder;

    final localeProvider = LocaleProvider();
    // Reading the saved language must never be able to block the very first
    // frame forever (e.g. a wedged SharedPreferences platform channel on
    // some devices) — fall back to the default English locale on any
    // failure or timeout instead of stalling startup.
    try {
      await localeProvider.load().timeout(const Duration(seconds: 5));
    } catch (_) {}

    runApp(PharmaSalesApp(localeProvider: localeProvider));
  }, (error, stack) {
    debugPrint('[Uncaught] $error\n$stack');
  });
}

Widget _startupErrorBuilder(FlutterErrorDetails details) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: ColoredBox(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
              const SizedBox(height: 12),
              Text(
                kReleaseMode ? 'Something went wrong. Please restart the app.' : details.exceptionAsString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class PharmaSalesApp extends StatelessWidget {
  final LocaleProvider localeProvider;

  const PharmaSalesApp({super.key, required this.localeProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: localeProvider),
        Provider<ApiClient>(create: (_) => ApiClient()),
        ChangeNotifierProvider(create: (context) => AuthService(context.read<ApiClient>())),
        ChangeNotifierProvider(create: (context) => ConnectionStatusService(context.read<ApiClient>())..start()),
        Provider(create: (context) => OffersService(context.read<ApiClient>())),
        ChangeNotifierProvider(create: (context) => OfflineSyncService(context.read<ApiClient>())),
        Provider(create: (context) => QuotationsService(context.read<ApiClient>())),
        Provider(create: (context) => SalesOrdersService(context.read<ApiClient>())),
        ChangeNotifierProvider(create: (context) => ReferenceCache(context.read<OffersService>())),
        ChangeNotifierProvider(
          create: (context) => DataSyncService(
            context.read<OffersService>(),
            context.read<QuotationsService>(),
            context.read<SalesOrdersService>(),
            context.read<ReferenceCache>(),
            context.read<OfflineSyncService>(),
          ),
        ),
        Provider(create: (context) => RealtimeClient(context.read<ApiClient>())),
        Provider(create: (context) => NotificationsService(context.read<ApiClient>())),
        ChangeNotifierProvider(
          create: (context) => NotificationsController(context.read<NotificationsService>(), context.read<RealtimeClient>()),
        ),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, locale, _) {
          return MaterialApp(
            title: 'PharmaSo',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            locale: locale.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            // A user's system font-scale is exactly what turns a fixed-size
            // card into an overflow (see status_filter_bar.dart) — clamp it
            // app-wide instead of guarding every fixed-height widget.
            builder: (context, child) => MediaQuery.withClampedTextScaling(
              minScaleFactor: 0.85,
              maxScaleFactor: 1.3,
              child: child!,
            ),
            home: const AppBootstrapper(child: SplashScreen()),
          );
        },
      ),
    );
  }
}
