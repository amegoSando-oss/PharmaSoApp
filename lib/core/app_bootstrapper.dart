import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'realtime_client.dart';
import '../services/auth_service.dart';
import '../services/notifications_controller.dart';

/// Starts/stops the notifications controller and the Reverb connection as
/// the session comes and goes, so no screen has to remember to do it.
class AppBootstrapper extends StatefulWidget {
  final Widget child;

  const AppBootstrapper({super.key, required this.child});

  @override
  State<AppBootstrapper> createState() => _AppBootstrapperState();
}

class _AppBootstrapperState extends State<AppBootstrapper> {
  late final AuthService _auth;

  @override
  void initState() {
    super.initState();
    _auth = context.read<AuthService>();
    _auth.addListener(_onAuthChanged);
    _onAuthChanged();
  }

  void _onAuthChanged() {
    final user = _auth.currentUser;
    if (_auth.isAuthenticated && user != null) {
      context.read<RealtimeClient>().connect();
      context.read<NotificationsController>().start(user.id);
    } else {
      context.read<NotificationsController>().stop();
      context.read<RealtimeClient>().disconnect();
    }
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
