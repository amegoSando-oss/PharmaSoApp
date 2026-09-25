import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Thin JSON wrapper around [http], mirroring resources/js/core/api.js:
/// bearer-token auth, an Idempotency-Key header on mutating calls, and the
/// same error-message extraction (errors[0].message / errors map / message).
class ApiClient {
  // Without a timeout, an unreachable host leaves callers hanging far past
  // any UI's own timing (e.g. the splash screen's session-restore check),
  // since dart:io's own connect timeout can run well past a minute.
  static const _timeout = Duration(seconds: 10);

  String? _token;

  String? get token => _token;

  void setToken(String? token) {
    _token = token;
    debugPrint('[ApiClient] setToken(${token == null ? 'null' : '${token.substring(0, 8)}...len${token.length}'}) on $hashCode');
  }

  String _idempotencyKey(String prefix) {
    final rand = Random().nextInt(0xFFFFFF).toRadixString(36);
    return '$prefix-${DateTime.now().millisecondsSinceEpoch}-$rand';
  }

  Map<String, String> _headers({bool mutating = false, String prefix = 'action'}) {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (_token != null) headers['Authorization'] = 'Bearer $_token';
    if (mutating) headers['Idempotency-Key'] = _idempotencyKey(prefix);
    return headers;
  }

  Uri _uri(String path, [Map<String, dynamic>? params]) {
    final query = <String, String>{};
    params?.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty) {
        query[key] = value.toString();
      }
    });
    return Uri.parse('${ApiConfig.baseUrl}$path').replace(
      queryParameters: query.isEmpty ? null : query,
    );
  }

  dynamic _decode(http.Response response) {
    debugPrint('[ApiClient] ${response.request?.method} ${response.request?.url} -> ${response.statusCode} (client $hashCode, token ${_token == null ? 'MISSING' : 'present len ${_token!.length}'})');
    final contentType = response.headers['content-type'] ?? '';
    dynamic payload;
    if (contentType.contains('application/json') && response.body.isNotEmpty) {
      payload = jsonDecode(response.body);
    } else {
      payload = response.body;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_extractError(payload, response.statusCode), statusCode: response.statusCode);
    }
    return payload;
  }

  String _extractError(dynamic payload, int statusCode) {
    if (payload is Map) {
      final errors = payload['errors'];
      if (errors is List && errors.isNotEmpty && errors.first is Map && errors.first['message'] != null) {
        return errors.first['message'].toString();
      }
      if (errors is Map && errors.isNotEmpty) {
        final firstField = errors.values.first;
        if (firstField is List && firstField.isNotEmpty) return firstField.first.toString();
      }
      if (payload['message'] != null) return payload['message'].toString();
    }
    return 'Request failed ($statusCode)';
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? params}) async {
    final response = await http.get(_uri(path, params), headers: _headers()).timeout(_timeout);
    return _decode(response);
  }

  /// Unauthenticated reachability probe for [ConnectionStatusService] — hits
  /// the backend's public `/health` route so a missing/expired token never
  /// makes the server look unreachable.
  Future<void> ping({Duration timeout = const Duration(seconds: 6)}) async {
    final response = await http.get(_uri('/health')).timeout(timeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException('Health check failed', statusCode: response.statusCode);
    }
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body, String prefix = 'action'}) async {
    final response = await http.post(
      _uri(path),
      headers: _headers(mutating: true, prefix: prefix),
      body: jsonEncode(body ?? {}),
    ).timeout(_timeout);
    return _decode(response);
  }

  Future<dynamic> patch(String path, {Map<String, dynamic>? body, String prefix = 'action'}) async {
    final response = await http.patch(
      _uri(path),
      headers: _headers(mutating: true, prefix: prefix),
      body: jsonEncode(body ?? {}),
    ).timeout(_timeout);
    return _decode(response);
  }

  Future<dynamic> delete(String path, {String prefix = 'action'}) async {
    final response = await http.delete(_uri(path), headers: _headers(mutating: true, prefix: prefix)).timeout(_timeout);
    return _decode(response);
  }

  /// For binary responses (e.g. the quotation PDF), which aren't JSON.
  Future<Uint8List> getBytes(String path) async {
    final headers = _headers()..['Accept'] = '*/*';
    final response = await http.get(_uri(path), headers: headers).timeout(const Duration(seconds: 30));
    debugPrint('[ApiClient] GET ${response.request?.url} -> ${response.statusCode} (bytes: ${response.bodyBytes.length})');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_extractError(null, response.statusCode), statusCode: response.statusCode);
    }
    return response.bodyBytes;
  }
}
