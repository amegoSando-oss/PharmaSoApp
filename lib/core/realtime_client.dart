import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'api_client.dart';
import 'api_config.dart';

typedef RealtimeHandler = void Function(Map<String, dynamic> payload);

/// Minimal Pusher-protocol client speaking directly to Laravel Reverb over
/// a plain WebSocket — mirrors resources/js/core/echo.js's `realtime`
/// object (same channel names, same event names, same private-channel auth
/// flow via /broadcasting/auth with a Bearer token) without depending on a
/// package built for pusher.com's hosted cluster API (which doesn't expose
/// a custom host/port for a self-hosted server like Reverb).
///
/// Every failure mode here (bad key, Reverb not running, socket drop) is
/// swallowed and just leaves the app without push updates — callers are
/// expected to also run their own polling fallback, exactly like the web
/// app's 90s NotificationBell/list-view timers.
class RealtimeClient {
  final ApiClient apiClient;

  RealtimeClient(this.apiClient);

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  String? _socketId;
  bool _connected = false;
  bool _manuallyDisconnected = false;
  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;

  final Set<String> _pendingChannels = {};
  final Map<String, Map<String, List<RealtimeHandler>>> _handlers = {};

  bool get _enabled => ApiConfig.reverbAppKey != 'CHANGE_ME_REVERB_APP_KEY';

  void connect() {
    final reconnectPending = _reconnectTimer?.isActive ?? false;
    if (!_enabled || _channel != null || reconnectPending) return;
    _manuallyDisconnected = false;
    _open();
  }

  void disconnect() {
    _manuallyDisconnected = true;
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _connected = false;
    _socketId = null;
  }

  void _open() {
    try {
      final scheme = ApiConfig.reverbUseTls ? 'wss' : 'ws';
      final uri = Uri.parse(
        '$scheme://${ApiConfig.reverbHost}:${ApiConfig.reverbPort}/app/${ApiConfig.reverbAppKey}'
        '?protocol=7&client=flutter&version=1.0',
      );
      final channel = WebSocketChannel.connect(uri);
      _channel = channel;
      // WebSocketChannel.connect() returns synchronously and connects in the
      // background — a failure (host unreachable, refused, Reverb not
      // running) is reported through `ready`, not necessarily through
      // `stream`. Without this, a failed *first* attempt would leave
      // _channel permanently non-null with a dead connection: connect()'s
      // `_channel != null` guard would then block every future retry
      // forever, silently killing real-time for the rest of the session.
      channel.ready.catchError((_) => _scheduleReconnect());
      _subscription = channel.stream.listen(
        _onMessage,
        onError: (_) => _scheduleReconnect(),
        onDone: () => _scheduleReconnect(),
        cancelOnError: true,
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_channel == null) return; // already handled by an earlier call this tick
    _connected = false;
    _socketId = null;
    _channel = null;
    if (_manuallyDisconnected) return;
    _reconnectTimer?.cancel();
    _reconnectAttempt = (_reconnectAttempt + 1).clamp(0, 6);
    final delay = Duration(seconds: 2 * _reconnectAttempt);
    _reconnectTimer = Timer(delay, _open);
  }

  void _onMessage(dynamic raw) {
    Map<String, dynamic> frame;
    try {
      frame = jsonDecode(raw as String) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    final event = frame['event'] as String?;
    final rawData = frame['data'];
    final data = rawData is String
        ? (jsonDecode(rawData.isEmpty ? '{}' : rawData) as Map<String, dynamic>? ?? const {})
        : (rawData as Map<String, dynamic>? ?? const {});

    if (event == 'pusher:connection_established') {
      _socketId = data['socket_id']?.toString();
      _connected = true;
      _reconnectAttempt = 0;
      for (final channel in _pendingChannels.toList()) {
        _sendSubscribe(channel);
      }
      return;
    }
    if (event == 'pusher:error' || event == null) return;

    final channelName = frame['channel'] as String?;
    if (channelName == null) return;
    final callbacks = _handlers[channelName]?[event];
    if (callbacks == null) return;
    for (final cb in callbacks.toList()) {
      try {
        cb(data);
      } catch (e, st) {
        debugPrint('[RealtimeClient] handler for $channelName/$event threw: $e\n$st');
      }
    }
  }

  Future<void> _sendSubscribe(String channelName) async {
    final channel = _channel;
    if (channel == null || !_connected) return;
    final isPrivate = channelName.startsWith('private-');
    String? auth;
    if (isPrivate) {
      auth = await _authorize(channelName);
      if (auth == null) return; // couldn't authorize — skip, will retry on next reconnect
      // The socket may have reconnected (a new _channel) or dropped again
      // while the auth round-trip was in flight — resubscribing already
      // happens for the new connection, so sending on the stale one here
      // would be redundant at best and a write-to-closed-sink at worst.
      if (!identical(_channel, channel) || !_connected) return;
    }
    try {
      channel.sink.add(jsonEncode({
        'event': 'pusher:subscribe',
        'data': {'channel': channelName, 'auth': ?auth},
      }));
    } catch (_) {
      // Sink already closed under us — the next reconnect will resubscribe.
    }
  }

  Future<String?> _authorize(String channelName) async {
    final token = apiClient.token;
    if (token == null || _socketId == null) return null;
    try {
      final payload = await apiClient.post('/broadcasting/auth', body: {
        'socket_id': _socketId,
        'channel_name': channelName,
      });
      return (payload as Map<String, dynamic>)['auth']?.toString();
    } catch (_) {
      return null;
    }
  }

  /// Subscribe to a public "resource changed" ping channel (e.g.
  /// "price-offers") and its `live-update` event. Returns an unsubscribe fn.
  VoidCallback onLiveUpdate(String channelName, RealtimeHandler handler) {
    return _on(channelName, 'live-update', handler);
  }

  /// Subscribe to the signed-in user's private notification stream.
  VoidCallback onNotification(int userId, RealtimeHandler handler) {
    return _on('private-notifications.$userId', 'notification.created', handler);
  }

  VoidCallback _on(String channelName, String event, RealtimeHandler handler) {
    final wasSubscribed = _pendingChannels.contains(channelName);
    _pendingChannels.add(channelName);
    (_handlers[channelName] ??= {}).putIfAbsent(event, () => []).add(handler);

    connect();
    if (!wasSubscribed) _sendSubscribe(channelName);

    return () {
      final channelHandlers = _handlers[channelName];
      channelHandlers?[event]?.remove(handler);
      final stillUsed = channelHandlers?.values.any((list) => list.isNotEmpty) ?? false;
      if (!stillUsed) {
        _pendingChannels.remove(channelName);
        _handlers.remove(channelName);
        if (_connected) {
          try {
            _channel?.sink.add(jsonEncode({
              'event': 'pusher:unsubscribe',
              'data': {'channel': channelName},
            }));
          } catch (_) {
            // Socket already gone — nothing left to unsubscribe from.
          }
        }
      }
    };
  }
}
