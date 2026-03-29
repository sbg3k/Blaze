/// In-memory auth session.
///
/// For now we keep tokens in memory only (no persistence).
/// Replace with secure storage once the backend integration stabilizes.
class AuthSession {
  AuthSession._();

  static final AuthSession instance = AuthSession._();

  String? accessToken;
  String? refreshToken;

  bool get isAuthenticated => accessToken != null && accessToken!.isNotEmpty;

  void setTokens({
    required String accessToken,
    required String refreshToken,
  }) {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }

  void clear() {
    accessToken = null;
    refreshToken = null;
  }
}
