import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionService {
  SessionService._privateConstructor();

  static final SessionService instance =
  SessionService._privateConstructor();

  final FlutterSecureStorage _storage =
  const FlutterSecureStorage();

  // =========================================================
  // KEYS
  // =========================================================

  static const String _accessTokenKey =
      'access_token';

  static const String _refreshTokenKey =
      'refresh_token';

  static const String _userIdKey =
      'user_id';

  // =========================================================
  // SAVE SESSION
  // =========================================================

  Future<void> saveSession({
    required String accessToken,
    String? refreshToken,
    required String userId,
  }) async {
    await _storage.write(
      key: _accessTokenKey,
      value: accessToken,
    );

    if (refreshToken != null &&
        refreshToken.isNotEmpty) {
      await _storage.write(
        key: _refreshTokenKey,
        value: refreshToken,
      );
    }

    await _storage.write(
      key: _userIdKey,
      value: userId,
    );
  }

  // =========================================================
  // ACCESS TOKEN
  // =========================================================

  Future<String?> getAccessToken() async {
    return await _storage.read(
      key: _accessTokenKey,
    );
  }

  // =========================================================
  // REFRESH TOKEN
  // =========================================================

  Future<String?> getRefreshToken() async {
    return await _storage.read(
      key: _refreshTokenKey,
    );
  }

  // =========================================================
  // USER ID
  // =========================================================

  Future<String?> getUserId() async {
    return await _storage.read(
      key: _userIdKey,
    );
  }

  // =========================================================
  // CHECK LOGIN
  // =========================================================

  Future<bool> isLoggedIn() async {
    final accessToken =
    await getAccessToken();

    final userId =
    await getUserId();

    return accessToken != null &&
        accessToken.isNotEmpty &&
        userId != null &&
        userId.isNotEmpty;
  }

  // =========================================================
  // CLEAR SESSION
  // =========================================================

  Future<void> clearSession() async {
    await _storage.delete(
      key: _accessTokenKey,
    );

    await _storage.delete(
      key: _refreshTokenKey,
    );

    await _storage.delete(
      key: _userIdKey,
    );
  }
}