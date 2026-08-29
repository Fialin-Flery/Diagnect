import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:diagnect/services/auth_api_service.dart';
import 'package:diagnect/services/local_database.dart';
import 'package:diagnect/services/session_service.dart';
import 'package:diagnect/models/report_model.dart';
import 'package:diagnect/models/medical_history_model.dart';


class AuthManager {
  AuthManager._privateConstructor();

  static final AuthManager instance =
  AuthManager._privateConstructor();

  final AuthApiService _api =
  AuthApiService();

  final LocalDatabase _database =
      LocalDatabase.instance;

  final SessionService _session =
      SessionService.instance;

  // =========================================================
  // RESTORE SESSION
  // =========================================================

  Future<bool> restoreSession() async {
    try {
      final accessToken =
      await _session.getAccessToken();

      final userId =
      await _session.getUserId();

      if (accessToken == null ||
          accessToken.isEmpty ||
          userId == null ||
          userId.isEmpty) {
        return false;
      }

      try {
        await _api.getProfile(
          accessToken,
        );

        return true;
      } catch (e) {
        debugPrint(
          'Access token rejected: $e',
        );
      }

      final refreshToken =
      await _session.getRefreshToken();

      if (refreshToken == null ||
          refreshToken.isEmpty) {
        return false;
      }

      final refreshed =
      await _api.refreshSession(
        refreshToken,
      );

      final newAccessToken =
      refreshed['access_token']
          ?.toString();

      if (newAccessToken == null ||
          newAccessToken.isEmpty) {
        return false;
      }

      final newRefreshToken =
      refreshed['refresh_token']
          ?.toString();

      await _session.saveSession(
        accessToken:
        newAccessToken,
        refreshToken:
        newRefreshToken ??
            refreshToken,
        userId: userId,
      );

      return true;

    } catch (e) {
      debugPrint(
        'Session restoration failed: $e',
      );

      final existingToken =
      await _session.getAccessToken();

      return existingToken != null &&
          existingToken.isNotEmpty;
    }
  }

  // =========================================================
  // CHECK EXISTING SESSION
  // =========================================================

  Future<bool> hasValidSession() async {
    final loggedIn =
    await _session.isLoggedIn();

    if (!loggedIn) {
      return false;
    }

    final session =
    await _database.getSession();

    if (session == null) {
      await clearLocalSession();
      return false;
    }

    return await restoreSession();
  }



  // =========================================================
  // COMPLETE LOGIN
  // =========================================================

  Future<Map<String, dynamic>>
  completeLogin({
    required String verificationId,
    required String aadhaarNumber,
  }) async {
    debugPrint(
      'Creating Diagnect session...',
    );

    final response =
    await _api.createSession(
      verificationId,
      aadhaarNumber,
    );

    final accessToken =
    response['access_token']
        ?.toString();

    final refreshToken =
    response['refresh_token']
        ?.toString();

    final user =
    response['user'];

    final userId =
    user?['id']?.toString();

    if (accessToken == null ||
        accessToken.isEmpty) {
      throw Exception(
        'Backend did not return access token.',
      );
    }

    if (userId == null ||
        userId.isEmpty) {
      throw Exception(
        'Backend did not return user ID.',
      );
    }

    await _session.saveSession(
      accessToken:
      accessToken,
      refreshToken:
      refreshToken,
      userId:
      userId,
    );

    await _database.saveSession(
      userId: userId,
      verificationId:
      verificationId,
    );

    /*
     * Immediately fetch the authoritative
     * profile after authentication.
     */

    try {
      final profile =
      await _api.getProfile(
        accessToken,
      );

      await _database.saveProfile(
        profile,
      );
    } catch (e) {
      debugPrint(
        'Initial profile fetch failed: $e',
      );
    }

    return response;
  }

  // =========================================================
  // ACCESS TOKEN
  // =========================================================

  Future<String?> getAccessToken() async {
    return await _session.getAccessToken();
  }

  // =========================================================
  // USER ID
  // =========================================================

  Future<String?> getUserId() async {
    return await _session.getUserId();
  }

  // =========================================================
  // LOCAL PROFILE
  // =========================================================

  Future<Map<String, dynamic>?>
  getLocalProfile() async {
    final currentUserId =
    await _session.getUserId();

    if (currentUserId == null ||
        currentUserId.isEmpty) {
      return null;
    }

    final profile =
    await _database.getProfile();

    if (profile == null) {
      return null;
    }

    final profileUserId =
    profile['user_id']?.toString();

    if (profileUserId != currentUserId) {
      return null;
    }

    return profile;
  }

  // =========================================================
  // FETCH PROFILE
  // =========================================================

  Future<Map<String, dynamic>>
  fetchProfile() async {
    final token =
    await _session.getAccessToken();

    if (token == null ||
        token.isEmpty) {
      throw Exception(
        'No authenticated session.',
      );
    }

    final profile =
    await _api.getProfile(
      token,
    );

    await _database.saveProfile(
      profile,
    );

    return profile;
  }

  // =========================================================
// PROFILE COMPLETION STATUS
// =========================================================

  Future<bool> isProfileCompleted() async {
    try {
      final profile =
      await fetchProfile();

      final value =
      profile['profile_completed'];

      return value == true;
    } catch (e) {
      debugPrint(
        'Unable to determine profile completion: $e',
      );

      return false;
    }
  }

  // =========================================================
  // UPDATE PROFILE
  // =========================================================

  Future<Map<String, dynamic>>
  updateProfile({
    String? name,
    String? dateOfBirth,
    String? bloodGroup,
  }) async {
    final token =
    await _session.getAccessToken();

    if (token == null ||
        token.isEmpty) {
      throw Exception(
        'No authenticated session.',
      );
    }

    final profile =
    await _api.updateProfile(
      token,
      name: name,
      dateOfBirth:
      dateOfBirth,
      bloodGroup:
      bloodGroup,
    );

    await _database.saveProfile(
      profile,
    );

    return profile;
  }

  // =========================================================
  // ABHA STATUS
  // =========================================================

  Future<Map<String, dynamic>>
  getAbhaStatus() async {
    final token =
    await _session.getAccessToken();

    if (token == null ||
        token.isEmpty) {
      throw Exception(
        'No authenticated session.',
      );
    }

    return await _api.getAbhaStatus(
      token,
    );
  }

  // =========================================================
  // LINK ABHA
  // =========================================================

  Future<Map<String, dynamic>>
  linkAbha() async {
    final token =
    await _session.getAccessToken();

    if (token == null ||
        token.isEmpty) {
      throw Exception(
        'No authenticated session.',
      );
    }

    final result =
    await _api.linkAbha(
      token,
    );

    /*
     * Refresh profile after ABHA
     * linkage because ABHA number
     * may now be present.
     */

    try {
      final profile =
      await _api.getProfile(
        token,
      );

      await _database.saveProfile(
        profile,
      );
    } catch (e) {
      debugPrint(
        'Profile refresh after ABHA linking failed: $e',
      );
    }

    return result;
  }

  // =========================================================
  // CREATE ABHA
  // =========================================================

  Future<Map<String, dynamic>>
  createAbha({
    required String abhaAddress,
  }) async {
    final token =
    await _session.getAccessToken();

    if (token == null ||
        token.isEmpty) {
      throw Exception(
        'No authenticated session.',
      );
    }

    final result =
    await _api.createAbha(
      token,
      abhaAddress:
      abhaAddress,
    );

    try {
      final profile =
      await _api.getProfile(token);

      await _database.saveProfile(
        profile,
      );
    } catch (e) {
      debugPrint(
        'Profile refresh after ABHA creation failed: $e',
      );
    }

    return result;
  }

  // =========================================================
  // MEDICAL HISTORY
  // =========================================================

  Future<MedicalHistoryModel?>
  getLocalMedicalHistory() async {

    final userId =
    await _session.getUserId();

    if (userId == null ||
        userId.isEmpty) {
      return null;
    }

    return await _database
        .getMedicalHistory(
      userId,
    );
  }


  Future<MedicalHistoryModel?>
  fetchMedicalHistory() async {

    final token =
    await _session.getAccessToken();

    if (token == null ||
        token.isEmpty) {
      throw Exception(
        'No authenticated session.',
      );
    }

    final response =
    await _api.getMedicalHistory(
      token,
    );

    final exists =
        response['exists'] == true;

    if (!exists) {
      return null;
    }

    final rawHistory =
    response['medical_history'];

    if (rawHistory
    is! Map<String, dynamic>) {
      return null;
    }

    final history =
    MedicalHistoryModel.fromJson(
      rawHistory,
    );

    final userId =
    await _session.getUserId();

    if (userId != null &&
        userId.isNotEmpty) {
      await _database
          .saveMedicalHistory(
        history,
        userId,
      );
    }

    return history;
  }


  Future<bool>
  saveMedicalHistory(
      MedicalHistoryModel history,
      ) async {

    final token =
    await _session.getAccessToken();

    if (token == null ||
        token.isEmpty) {
      throw Exception(
        'No authenticated session.',
      );
    }

    final response =
    await _api.saveMedicalHistory(
      token,
      history.toJson(),
    );

    final rawHistory =
    response['medical_history'];

    if (rawHistory
    is! Map<String, dynamic>) {
      throw Exception(
        'Backend did not return saved medical history.',
      );
    }

    final savedHistory =
    MedicalHistoryModel.fromJson(
      rawHistory,
    );

    final userId =
    await _session.getUserId();

    if (userId == null ||
        userId.isEmpty) {
      throw Exception(
        'No authenticated user.',
      );
    }

    await _database
        .saveMedicalHistory(
      savedHistory,
      userId,
    );

    return savedHistory.completed;
  }


  // =========================================================
// REPORTS
// =========================================================

  Future<List<ReportModel>> getReports() async {
    final userId =
    await _session.getUserId();

    if (userId == null ||
        userId.isEmpty) {
      return [];
    }

    return await _database.getReports(
      userId,
    );
  }

// =========================================================
// COPY FILE INTO APP STORAGE
// =========================================================

  Future<String> _copyReportFile(
      String sourcePath,
      ) async {
    final source = File(sourcePath);

    if (!await source.exists()) {
      throw Exception(
        'Selected file no longer exists:\n$sourcePath',
      );
    }

    final directory =
    await getApplicationDocumentsDirectory();

    final reportsDirectory =
    Directory(
      path.join(
        directory.path,
        'medical_reports',
      ),
    );

    if (!await reportsDirectory.exists()) {
      await reportsDirectory.create(
        recursive: true,
      );
    }

    final extension =
    path.extension(sourcePath);

    final baseName =
    path.basenameWithoutExtension(
      sourcePath,
    );

    final filename =
        '${DateTime.now().microsecondsSinceEpoch}'
        '_$baseName'
        '$extension';

    final destination =
    path.join(
      reportsDirectory.path,
      filename,
    );

    final copied =
    await source.copy(destination);

    return copied.path;
  }

// =========================================================
// ADD REPORT
// =========================================================

  Future<void> addReport({
    required String title,
    String? hospital,
    required String type,
    String? description,
    List<String> filePaths = const [],
    String? fileType,
    required String reportDate,
  }) async {
    final userId =
    await _session.getUserId();

    if (userId == null ||
        userId.isEmpty) {
      throw Exception(
        'No authenticated user.',
      );
    }

    final storedPaths =
    <String>[];

    /*
   * Copy EVERY file into permanent
   * application storage.
   */

    for (final sourcePath in filePaths) {
      if (sourcePath.trim().isEmpty) {
        continue;
      }

      final storedPath =
      await _copyReportFile(
        sourcePath,
      );

      storedPaths.add(
        storedPath,
      );
    }

    final now =
    DateTime.now()
        .toUtc()
        .toIso8601String();

    final report =
    ReportModel(
      userId: userId,

      title: title,

      hospital:
      hospital,

      type: type,

      description:
      description,

      filePath:
      storedPaths.isNotEmpty
          ? storedPaths.first
          : null,

      filePaths:
      storedPaths,

      fileType:
      fileType,

      reportDate:
      reportDate,

      createdAt:
      now,
    );

    await _database.insertReport(
      report,
    );
  }

// =========================================================
// DELETE REPORT
// =========================================================

  Future<void> deleteReport(
      int reportId,
      ) async {
    final userId =
    await _session.getUserId();

    if (userId == null ||
        userId.isEmpty) {
      throw Exception(
        'No authenticated user.',
      );
    }

    final reports =
    await _database.getReports(
      userId,
    );

    final report =
    reports.firstWhere(
          (item) => item.id == reportId,
      orElse: () => throw Exception(
        'Report not found.',
      ),
    );

    /*
   * Delete every physical file.
   */

    for (final filePath
    in report.filePaths) {
      try {
        final file =
        File(filePath);

        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint(
          'Unable to delete report file: $e',
        );
      }
    }

    /*
   * Then delete database record.
   */

    await _database.deleteReport(
      reportId,
      userId,
    );
  }

  // =========================================================
  // LOGOUT
  // =========================================================

  Future<void> logout() async {
    final token =
    await _session.getAccessToken();

    if (token != null &&
        token.isNotEmpty) {
      try {
        await _api.logout(token);
      } catch (e) {
        debugPrint(
          'Backend logout failed: $e',
        );
      }
    }

    // Do not delete medical reports.
    await _session.clearSession();
    await _database.clearSessionData();
  }

  // =========================================================
  // CLEAR LOCAL SESSION
  // =========================================================

  Future<void> clearLocalSession() async {
    await _session.clearSession();
    await _database.clearAll();
  }
}