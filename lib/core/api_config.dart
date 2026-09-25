/// Backend host configuration. Change [apiHost]/[apiPort] to point the app
/// at a different Pharama backend instance.
class ApiConfig {
  static const String apiHost = '10.100.16.37';
  static const int apiPort = 8000;

  static const String baseUrl = 'http://$apiHost:$apiPort/api/v1';

  // Laravel Reverb (WebSocket) connection — see docs/business-logic.md §12a
  // on the backend. Reverb has no process supervisor there yet, so it may
  // not actually be running; RealtimeClient treats any connection failure
  // as non-fatal and callers fall back to their own polling. [reverbAppKey]
  // is a placeholder — set it to the backend's real REVERB_APP_KEY (from
  // its .env, not committed to the repo) once Reverb is confirmed running.
  // Left as the placeholder, RealtimeClient skips connecting entirely.
  static const String reverbAppKey = 'CHANGE_ME_REVERB_APP_KEY';
  static const String reverbHost = apiHost;
  static const int reverbPort = 8080;
  static const bool reverbUseTls = false;
}
