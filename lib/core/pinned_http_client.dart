import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import 'api_config.dart';

/// Builds the [http.Client] used for every REST call to [ApiConfig.apiHost].
///
/// Against the production host (TLS), this pins the connection to
/// `assets/certs/pharmaso_dakahlia_net.pem` — the backend's own self-signed
/// certificate — instead of trusting the system's CA store. There is no CA
/// here, so a system-trust client would otherwise accept literally any
/// certificate presented for that hostname; pinning means only a server
/// holding this exact certificate is accepted, which matters on public
/// wifi/cellular, not just the office LAN.
///
/// Falls back to a plain [http.Client] (system trust, or no TLS at all for
/// the local test backend) if the certificate can't be loaded, so a bundling
/// mistake fails safe into "normal HTTPS" rather than bricking every request.
Future<http.Client> buildApiHttpClient() async {
  if (!ApiConfig.apiUseTls) return http.Client();

  try {
    final context = SecurityContext(withTrustedRoots: false);
    final certBytes = await rootBundle.load('assets/certs/pharmaso_dakahlia_net.pem');
    context.setTrustedCertificatesBytes(certBytes.buffer.asUint8List());
    final httpClient = HttpClient(context: context);
    return IOClient(httpClient);
  } catch (e) {
    debugPrint('[pinned_http_client] Failed to load pinned certificate, falling back to system trust: $e');
    return http.Client();
  }
}
