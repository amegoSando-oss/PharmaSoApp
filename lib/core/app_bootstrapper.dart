import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'realtime_client.dart';
import '../services/auth_service.dart';
import '../services/connection_status_service.dart';
import '../services/data_sync_service.dart';
import '../services/notifications_controller.dart';
import '../services/offline_sync_service.dart';

/// Starts/stops the notifications controller and the Reverb connection as
/// the session comes and goes, so no screen has to remember to do it. Also
/// drives the offline-sync protocol's background maintenance: whenever the
/// backend becomes reachable again, top up any salesman's reserved serials
/// (Step 1) and flush whatever price offer requests were queued while
/// offline (Step 3) — see OfflineSyncService's doc comment. On top of that,
/// pulls a fresh full copy of this rep's read-only data (customers,
/// warehouses, items, price lists, effective prices, and their own price
/// offer requests/quotations/sales orders) on login and on every
/// offline -> reachable edge, via DataSyncService, so those screens have
/// something current to fall back on the next time the app goes offline.
class AppBootstrapper extends StatefulWidget {
  final Widget child;

  const AppBootstrapper({super.key, required this.child});

  @override
  State<AppBootstrapper> createState() => _AppBootstrapperState();
}

class _AppBootstrapperState extends State<AppBootstrapper> {
  late final AuthService _auth;
  late final ConnectionStatusService _connection;
  bool _wasReachable = false;

  @override
  void initState() {
    super.initState();
    _auth = context.read<AuthService>();
    _auth.addListener(_onAuthChanged);
    _onAuthChanged();

    _connection = context.read<ConnectionStatusService>();
    _wasReachable = _connection.serverReachable;
    _connection.addListener(_onConnectionChanged);

    context.read<OfflineSyncService>().init().catchError((_) {});
  }

  void _onAuthChanged() {
    final user = _auth.currentUser;
    if (_auth.isAuthenticated && user != null) {
      context.read<RealtimeClient>().connect();
      context.read<NotificationsController>().start(user.id);
      // Fire-and-forget, same reasoning as _onConnectionChanged below — a
      // fresh login or a restored session is the other moment (besides
      // reconnecting) this rep's data is worth refreshing in full.
      context.read<DataSyncService>().syncAll().catchError((_) {});
    } else {
      context.read<NotificationsController>().stop();
      context.read<RealtimeClient>().disconnect();
    }
  }

  void _onConnectionChanged() async {
    final reachable = _connection.serverReachable;
    // Only act on the offline -> reachable edge, not on every ping tick.
    if (reachable && !_wasReachable && _auth.isAuthenticated) {
      // Re-checks or silently renews the saved token FIRST now that there's
      // a connection to check it against, before initiating background sync.
      try {
        await _auth.revalidateTokenIfNeeded();
      } catch (_) {}

      if (_auth.isAuthenticated) {
        final sync = context.read<OfflineSyncService>();
        // Fire-and-forget: neither call should ever crash the app if the
        // network drops again mid-request or the backend rejects a reserve
        // (e.g. a permission mismatch) — errors here are silently retried on
        // the next reconnect rather than surfaced, since there's no screen
        // in context to show them on.
        sync.syncPending().catchError((_) {});
        sync.ensureReservationsForKnownSalesmen().catchError((_) {});
        context.read<DataSyncService>().syncAll().catchError((_) {});
      }
    }
    _wasReachable = reachable;
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    _connection.removeListener(_onConnectionChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
