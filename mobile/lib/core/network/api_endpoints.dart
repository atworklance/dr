/// Centralised, strongly-typed registry of backend route paths. The base URL is
/// overridable at build time via `--dart-define=API_BASE_URL=...`.
///
/// Defaults to the Android-emulator loopback alias (10.0.2.2) pointing at the
/// local Dr.Plus API. Use `http://127.0.0.1:4000/api/v1` for iOS simulators.
abstract final class ApiEndpoints {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:4000/api/v1',
  );

  /// Socket.io origin (the server root, without the `/api/v1` path). Override
  /// with `--dart-define=SOCKET_URL=...`, otherwise derived from [baseUrl].
  static String get socketUrl {
    const override = String.fromEnvironment('SOCKET_URL', defaultValue: '');
    return override.isNotEmpty ? override : Uri.parse(baseUrl).origin;
  }

  // --- Auth ---------------------------------------------------------------
  static const String registerClient = '/auth/register/client';
  static const String registerProvider = '/auth/register/provider';
  static const String login = '/auth/login';
  static const String me = '/auth/me';

  // --- Specialist (provider) search --------------------------------------
  static const String providers = '/providers';
  static String providerById(String id) => '/providers/$id';

  // --- Appointments / booking --------------------------------------------
  static const String appointments = '/appointments';
  static String appointmentById(String id) => '/appointments/$id';
  static String payAppointment(String id) => '/appointments/$id/pay';

  // --- Live video session -------------------------------------------------
  static String videoToken(String id) => '/appointments/$id/video/token';
  static String videoStart(String id) => '/appointments/$id/video/start';
  static String videoEnd(String id) => '/appointments/$id/video/end';
}
