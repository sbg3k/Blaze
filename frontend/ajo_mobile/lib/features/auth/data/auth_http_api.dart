import '../../../core/network/api_client.dart';

class AuthHttpApi {
  AuthHttpApi({required this.client});

  final ApiClient client;

  Future<void> signup({
    required String email,
    required String username,
    required String firstName,
    required String lastName,
    required String password,
  }) async {
    await client.postJson(
      '/auth/signup',
      body: <String, dynamic>{
        'email': email,
        'username': username,
        'first_name': firstName,
        'last_name': lastName,
        'password': password,
      },
      auth: false,
    );
  }

  Future<void> verifyOtp({
    required String email,
    required String otp,
    String purpose = 'email_verification',
  }) async {
    await client.postJson(
      '/auth/verify-otp',
      body: <String, dynamic>{
        'email': email,
        'otp': otp,
        'purpose': purpose,
      },
      auth: false,
    );
  }

  Future<void> resendOtp({
    required String email,
    String purpose = 'email_verification',
  }) async {
    await client.postJson(
      '/auth/resend-otp',
      body: <String, dynamic>{
        'email': email,
        'purpose': purpose,
      },
      auth: false,
    );
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final res = await client.postJson(
      '/auth/login',
      body: <String, dynamic>{
        'email': email,
        'password': password,
      },
      auth: false,
    );

    final access = res['access_token']?.toString();
    final refresh = res['refresh_token']?.toString();
    if (access == null || refresh == null) {
      throw ApiException('Invalid login response', body: res);
    }

    // Store tokens in the shared session so subsequent requests (groups) can be authenticated.
    client.session.setTokens(accessToken: access, refreshToken: refresh);
  }

  Future<void> forgotPassword({required String email}) async {
    await client.postJson(
      '/auth/forgot-password',
      body: <String, dynamic>{
        'email': email,
      },
      auth: false,
    );
  }

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String password,
  }) async {
    await client.postJson(
      '/auth/reset-password',
      body: <String, dynamic>{
        'email': email,
        'otp': otp,
        'password': password,
      },
      auth: false,
    );
  }

  Future<void> logout() async {
    final refresh = client.session.refreshToken;
    if (refresh != null && refresh.isNotEmpty) {
      await client.postJson(
        '/auth/logout',
        body: <String, dynamic>{'refresh_token': refresh},
      );
    }
    client.session.clear();
  }
}

