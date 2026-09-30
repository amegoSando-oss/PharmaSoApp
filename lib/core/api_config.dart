/// Backend host configuration.
///
/// To switch the whole app between test and production, change
/// [useProduction] below — every network call (REST + Reverb websocket)
/// reads from this file, so nothing else needs to change.
class ApiConfig {
  static const bool useProduction = false;

  // Test environment (local/LAN backend).
  static const String _testHost = '10.100.16.37';
  static const int _testPort = 8000;
  static const bool _testUseTls = false;

  // Production environment (public domain, behind TLS).
  static const String _prodHost = 'pharmaso.dakahlia.net';
  static const int _prodPort = 443;
  static const bool _prodUseTls = true;

  static const String apiHost = useProduction ? _prodHost : _testHost;
  static const int apiPort = useProduction ? _prodPort : _testPort;
  static const bool apiUseTls = useProduction ? _prodUseTls : _testUseTls;

  static final String baseUrl = apiUseTls
      ? 'https://$apiHost/api/v1'
      : 'http://$apiHost:$apiPort/api/v1';

  // Laravel Reverb (WebSocket) connection — see docs/business-logic.md §12a
  // on the backend.
  static const String reverbAppKey = 'pharmaso-local-key';
  static const String reverbHost = apiHost;
  static const int _testReverbPort = 8080;
  static const int _prodReverbPort = 443;
  static const int reverbPort = useProduction ? _prodReverbPort : _testReverbPort;
  static const bool reverbUseTls = useProduction ? true : false;
}
