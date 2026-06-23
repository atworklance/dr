/// The role a principal holds on the platform. Drives the role-selection step
/// of registration and the post-login routing. Mirrors the backend `UserRole`.
enum UserRole {
  client,
  provider,
  admin;

  String get value => switch (this) {
        UserRole.client => 'client',
        UserRole.provider => 'provider',
        UserRole.admin => 'admin',
      };

  /// Human-readable label for role-selection UI.
  String get label => switch (this) {
        UserRole.client => 'Find a specialist',
        UserRole.provider => 'Offer consultations',
        UserRole.admin => 'Administrator',
      };

  static UserRole fromValue(String raw) => switch (raw) {
        'client' => UserRole.client,
        'provider' => UserRole.provider,
        'admin' => UserRole.admin,
        _ => throw ArgumentError('Unknown user role: $raw'),
      };
}
