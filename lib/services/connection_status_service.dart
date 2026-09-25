import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../core/api_client.dart';

/// Three-way read of "can this app actually talk to the backend right now":
/// - [offline]: no network interface, or the server hasn't answered at all
///   across the recent check window.
/// - [unstable]: online and the server does answer, but slowly or only
///   intermittently — the kind of connection that half-loads screens.
/// - [good]: online and the server answers quickly and consistently.
enum ConnectionQuality { offline, unstable, good }

/// Watches device network changes (via connectivity_plus) and periodically
/// pings the backend's `/health` route to grade connection quality — the
/// same information the [ConnectionStatusService]'s cloud icon renders for
/// the end user, and that any screen can also read directly.
class ConnectionStatusService extends ChangeNotifier {
  // While healthy, checking every 15s is enough to catch drift. While
  // offline/unstable, that's a bad user experience — recheck every 3s
  // instead so recovery shows up in the UI almost as soon as it happens.
  static const _pingIntervalGood = Duration(seconds: 15);
  static const _pingIntervalDegraded = Duration(seconds: 3);
  static const _pingTimeout = Duration(seconds: 4);
  static const _slowLatencyMs = 1200;
  static const _historySize = 5;

  final ApiClient apiClient;

  ConnectionStatusService(this.apiClient);

  ConnectionQuality quality = ConnectionQuality.good;
  bool hasNetwork = true;
  bool serverReachable = true;
  int? latencyMs;
  DateTime? lastCheckedAt;
  bool checking = false;

  final List<bool> _recentPings = [];

  Timer? _pingTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _started = false;

  // A check already in flight (periodic timer or a previous connectivity
  // event) used to make a new request a no-op — so a Wi-Fi toggle that
  // landed mid-check was silently dropped until the *next* 15s tick. This
  // flag instead queues exactly one rerun for as soon as the current check
  // finishes, so no change is ever lost.
  bool _rerunQueued = false;

  void start() {
    if (_started) return;
    _started = true;
    // The connectivity-change stream is the *only* writer of [hasNetwork]
    // from here on — checkNow()/_runCheck() used to also re-query
    // checkConnectivity() on every ping cycle, and a stale/racy result from
    // that second query could silently overwrite a correct "offline" the
    // event had just set. One seed read up front, then the stream owns it.
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      _onConnectivityEvent,
      onError: (_) {},
    );
    _seedInitialConnectivity();
  }

  Future<void> _seedInitialConnectivity() async {
    try {
      final results = await Connectivity().checkConnectivity();
      hasNetwork = results.any((r) => r != ConnectivityResult.none);
    } catch (_) {
      // Keep the optimistic default and let the first ping decide.
    }
    checkNow();
  }

  void _rescheduleTimer() {
    _pingTimer?.cancel();
    final interval = quality == ConnectionQuality.good ? _pingIntervalGood : _pingIntervalDegraded;
    _pingTimer = Timer(interval, () => checkNow());
  }

  void _onConnectivityEvent(List<ConnectivityResult> results) {
    // Update from the event's own payload immediately instead of waiting for
    // checkNow()'s ping round-trip — this is what makes "Wi-Fi off" reflect
    // in the UI right away rather than on the next periodic tick.
    final networkUp = results.any((r) => r != ConnectivityResult.none);
    if (networkUp != hasNetwork) {
      hasNetwork = networkUp;
      if (!hasNetwork) {
        serverReachable = false;
        latencyMs = null;
        _recentPings.clear();
      }
      quality = _computeQuality();
      lastCheckedAt = DateTime.now();
      notifyListeners();
    }
    checkNow();
  }

  Future<void> checkNow() async {
    if (checking) {
      _rerunQueued = true;
      return;
    }
    checking = true;
    notifyListeners();

    do {
      _rerunQueued = false;
      await _runCheck();
    } while (_rerunQueued);

    checking = false;
    _rescheduleTimer();
    notifyListeners();
  }

  Future<void> _runCheck() async {
    // [hasNetwork] is owned by the connectivity-change stream (see start()) —
    // this only decides whether to bother pinging with whatever the stream
    // last reported, instead of re-querying and risking a stale overwrite.
    if (!hasNetwork) {
      serverReachable = false;
      latencyMs = null;
      _recentPings.clear();
    } else {
      final stopwatch = Stopwatch()..start();
      try {
        await apiClient.ping(timeout: _pingTimeout);
        stopwatch.stop();
        serverReachable = true;
        latencyMs = stopwatch.elapsedMilliseconds;
        _pushResult(true);
      } catch (_) {
        stopwatch.stop();
        serverReachable = false;
        latencyMs = null;
        _pushResult(false);
      }
    }

    quality = _computeQuality();
    lastCheckedAt = DateTime.now();
    notifyListeners();
  }

  void _pushResult(bool success) {
    _recentPings.add(success);
    if (_recentPings.length > _historySize) _recentPings.removeAt(0);
  }

  ConnectionQuality _computeQuality() {
    if (!hasNetwork) return ConnectionQuality.offline;
    if (_recentPings.isNotEmpty && _recentPings.every((r) => !r)) return ConnectionQuality.offline;

    final anyRecentFailure = _recentPings.any((r) => !r);
    final isSlow = latencyMs != null && latencyMs! > _slowLatencyMs;
    if (anyRecentFailure || isSlow) return ConnectionQuality.unstable;
    return ConnectionQuality.good;
  }

  @override
  void dispose() {
    _pingTimer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
