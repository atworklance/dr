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
}
