
import 'dart:convert';

import 'package:http/http.dart' as http;

class AuthApiService {
  static const String baseUrl =
      'http://10.64.183.36:8000/api';

// =========================================================
// COMMON HEADERS
// =========================================================

  Map<String, String> _headers({
    String? token,
  }) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null &&
        token.isNotEmpty) {
      headers['Authorization'] =
      'Bearer $token';
    }

    return headers;
  }

// =========================================================
// START DIGILOCKER
// =========================================================

  Future<Map<String, dynamic>>
  startDigiLocker(
      String aadhaarNumber,
      ) async {
    final response = await http.post(
      Uri.parse(
        '$baseUrl/auth/digilocker/start',
      ),
      headers: _headers(),
      body: jsonEncode({
        'aadhaar_number':
        aadhaarNumber,
        'consent': true,
      }),
    );

    final data =
    _decodeResponse(response);

    if (response.statusCode != 200) {
      throw Exception(
        data['detail'] ??
            'DigiLocker verification failed',
      );
    }

    return data;
  }

// =========================================================
// CREATE DIGILOCKER URL
// =========================================================

  Future<Map<String, dynamic>>
  createDigiLockerUrl(
      String verificationId,
      String userFlow,
      ) async {

    final response = await http.post(
      Uri.parse(
        '$baseUrl/auth/digilocker/create-url',
      ),
      headers: _headers(),
      body: jsonEncode({
        'verification_id': verificationId,
        'user_flow': userFlow,
      }),
    );

    print('========== DIGILOCKER CREATE URL ==========');
    print('STATUS: ${response.statusCode}');
    print('BODY: ${response.body}');
    print('============================================');

    final data = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw Exception(
        data['detail'] ??
            'Unable to create DigiLocker URL',
      );
    }

    return data;
  }

// =========================================================
// DIGILOCKER STATUS
// =========================================================

  Future<Map<String, dynamic>>
  getDigiLockerStatus(
      String verificationId,
      ) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/auth/digilocker/status/'
            '${Uri.encodeComponent(verificationId)}',
      ),
      headers: _headers(),
    );

    final data =
    _decodeResponse(response);

    if (response.statusCode != 200) {
      throw Exception(
        data['detail'] ??
            'Unable to check DigiLocker verification status',
      );
    }

    return data;
  }

// =========================================================
// CREATE SESSION
// =========================================================

  Future<Map<String, dynamic>>
  createSession(
      String verificationId,
      String aadhaarNumber,
      ) async {
    final response = await http.post(
      Uri.parse(
        '$baseUrl/auth/session',
      ),
      headers: _headers(),
      body: jsonEncode({
        'verification_id':
        verificationId,
        'aadhaar_number':
        aadhaarNumber,
      }),
    );

    final data =
    _decodeResponse(response);

    if (response.statusCode != 200) {
      throw Exception(
        data['detail'] ??
            'Unable to create Diagnect session',
      );
    }

    return data;
  }

// =========================================================
// REFRESH SESSION
// =========================================================

  Future<Map<String, dynamic>>
  refreshSession(
      String refreshToken,
      ) async {
    final response = await http.post(
      Uri.parse(
        '$baseUrl/auth/refresh',
      ),
      headers: _headers(),
      body: jsonEncode({
        'refresh_token':
        refreshToken,
      }),
    );

    final data =
    _decodeResponse(response);

    if (response.statusCode != 200) {
      throw Exception(
        data['detail'] ??
            'Session refresh failed',
      );
    }

    return data;
  }

// =========================================================
// LOGOUT
// =========================================================

  Future<void> logout(
      String token,
      ) async {
    final response = await http.post(
      Uri.parse(
        '$baseUrl/auth/logout',
      ),
      headers: _headers(
        token: token,
      ),
    );

    if (response.statusCode >= 400) {
      final data =
      _decodeResponse(response);

      throw Exception(
        data['detail'] ??
            'Unable to logout',
      );
    }
  }

// =========================================================
// GET PROFILE
// =========================================================

  Future<Map<String, dynamic>>
  getProfile(
      String token,
      ) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/profile',
      ),
      headers: _headers(
        token: token,
      ),
    );

    final data =
    _decodeResponse(response);

    if (response.statusCode != 200) {
      throw Exception(
        data['detail'] ??
            'Unable to retrieve profile',
      );
    }

    return data;
  }

// =========================================================
// UPDATE PROFILE
// =========================================================

  Future<Map<String, dynamic>>
  updateProfile(
      String token, {
        String? name,
        String? dateOfBirth,
        String? bloodGroup,
      }) async {
    final body =
    <String, dynamic>{};

    if (name != null) {
      body['name'] = name;
    }

    if (dateOfBirth != null) {
      body['date_of_birth'] =
          dateOfBirth;
    }

    if (bloodGroup != null) {
      body['blood_group'] =
          bloodGroup;
    }

    final response = await http.patch(
      Uri.parse(
        '$baseUrl/profile',
      ),
      headers: _headers(
        token: token,
      ),
      body: jsonEncode(body),
    );

    final data =
    _decodeResponse(response);

    if (response.statusCode != 200) {
      throw Exception(
        data['detail'] ??
            'Unable to update profile',
      );
    }

    return data;
  }

// =========================================================
// MEDICAL HISTORY
// =========================================================

  Future<Map<String, dynamic>>
  getMedicalHistory(
      String token,
      ) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/medical-history',
      ),
      headers: _headers(
        token: token,
      ),
    );

    final data =
    _decodeResponse(response);

    if (response.statusCode != 200) {
      throw Exception(
        data['detail'] ??
            'Unable to retrieve medical history',
      );
    }

    return data;
  }

// =========================================================
// SAVE MEDICAL HISTORY
// =========================================================

  Future<Map<String, dynamic>>
  saveMedicalHistory(
      String token,
      Map<String, dynamic> history,
      ) async {
    final response = await http.put(
      Uri.parse(
        '$baseUrl/medical-history',
      ),
      headers: _headers(
        token: token,
      ),
      body: jsonEncode(history),
    );

    final data =
    _decodeResponse(response);

    if (response.statusCode != 200) {
      throw Exception(
        data['detail'] ??
            'Unable to save medical history',
      );
    }

    return data;
  }

// =========================================================
// ABHA STATUS
// =========================================================

  Future<Map<String, dynamic>>
  getAbhaStatus(
      String token,
      ) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/abha/status',
      ),
      headers: _headers(
        token: token,
      ),
    );

    final data =
    _decodeResponse(response);

    if (response.statusCode != 200) {
      throw Exception(
        data['detail'] ??
            'Unable to retrieve ABHA status',
      );
    }

    return data;
  }

// =========================================================
// LINK ABHA
// =========================================================

  Future<Map<String, dynamic>>
  linkAbha(
      String token,
      ) async {
    final response = await http.post(
      Uri.parse(
        '$baseUrl/abha/link',
      ),
      headers: _headers(
        token: token,
      ),
    );

    final data =
    _decodeResponse(response);

    if (response.statusCode != 200) {
      throw Exception(
        data['detail'] ??
            'Unable to link ABHA',
      );
    }

    return data;
  }

// =========================================================
// CREATE ABHA
// =========================================================

  Future<Map<String, dynamic>>
  createAbha(
      String token, {
        required String abhaAddress,
      }) async {
    final response = await http.post(
      Uri.parse(
        '$baseUrl/abha/create',
      ),
      headers: _headers(
        token: token,
      ),
      body: jsonEncode({
        'abha_address':
        abhaAddress,
      }),
    );

    final data =
    _decodeResponse(response);

    if (response.statusCode != 200) {
      throw Exception(
        data['detail'] ??
            'Unable to create ABHA',
      );
    }

    return data;
  }

// =========================================================
// RESPONSE DECODER
// =========================================================

  Map<String, dynamic>
  _decodeResponse(
      http.Response response,
      ) {
    try {
      final decoded =
      jsonDecode(response.body);

      if (decoded
      is Map<String, dynamic>) {
        return decoded;
      }

      return {
        'data': decoded,
      };
    } catch (_) {
      return {
        'detail':
        response.body.isEmpty
            ? 'Unknown server error'
            : response.body,
      };
    }
  }
}

