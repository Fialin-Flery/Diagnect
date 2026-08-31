import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:diagnect/models/medical_history_model.dart';
import 'package:diagnect/models/report_model.dart';
import 'package:diagnect/services/auth_manager.dart';
import 'package:diagnect/services/auth_api_service.dart';


class SharingService extends ChangeNotifier {

  SharingService._privateConstructor();

  static final SharingService instance =
  SharingService._privateConstructor();


  final AuthApiService _api =
  AuthApiService();

  final AuthManager _authManager =
      AuthManager.instance;


  WebSocket? _socket;

  StreamSubscription? _socketSubscription;


  String? _roomId;

  String? _patientToken;

  DateTime? _expiresAt;

  Map<String, dynamic>? _activeSession;


  final StreamController<
      Map<String, dynamic>
  > _eventsController =
  StreamController<
      Map<String, dynamic>
  >.broadcast();


  Stream<Map<String, dynamic>>
  get events =>
      _eventsController.stream;

  bool get isConnected =>
      _socket != null;

  String? get roomId =>
      _roomId;

  DateTime? get expiresAt =>
      _expiresAt;

  Map<String, dynamic>? get activeSession =>
      _activeSession;

  bool get hasActiveSession =>
      _activeSession != null;


  // =========================================================
  // PARSE QR
  // =========================================================

  Map<String, String> parseQr(
      String qrText,
      ) {

    final uri =
    Uri.tryParse(
      qrText.trim(),
    );

    if (uri == null) {

      throw Exception(
        'Invalid QR code.',
      );
    }


    if (uri.scheme !=
        'diagnect') {

      throw Exception(
        'This is not a Diagnect QR code.',
      );
    }


    if (uri.host !=
        'patient-connect') {

      throw Exception(
        'Unsupported Diagnect QR code.',
      );
    }


    final pathSegments =
        uri.pathSegments;


    if (pathSegments.isEmpty) {

      throw Exception(
        'QR code does not contain a session.',
      );
    }


    final roomId =
        pathSegments.first;


    final token =
    uri.queryParameters[
    'token'
    ];


    if (roomId.isEmpty ||
        token == null ||
        token.isEmpty) {

      throw Exception(
        'Invalid Diagnect session QR.',
      );
    }


    return {

      'room_id':
      roomId,

      'patient_token':
      token,
    };
  }


  // =========================================================
  // JOIN
  // =========================================================

  Future<Map<String, dynamic>>
  joinSession(
      String qrText,
      ) async {

    final qr =
    parseQr(
      qrText,
    );


    final roomId =
    qr['room_id']!;

    final patientToken =
    qr['patient_token']!;


    final accessToken =
    await _authManager
        .getAccessToken();


    if (accessToken == null ||
        accessToken.isEmpty) {

      throw Exception(
        'No authenticated Diagnect session.',
      );
    }


    final result =
    await _api.joinSharingSession(
      accessToken,
      roomId,
      patientToken,
    );


    _roomId =
        roomId;

    _patientToken =
        patientToken;


    final expires =
    result['expires_at']
        ?.toString();


    if (expires != null) {

      _expiresAt =
          DateTime.tryParse(
            expires,
          );
    }


    _activeSession = Map<String, dynamic>.from(result);

    debugPrint(
      'Active sharing session stored: $_activeSession',
    );

    debugPrint(
      '========================================',
    );

    debugPrint(
      'ACTIVE SHARING SESSION',
    );

    debugPrint(
      'Room ID: $_roomId',
    );

    debugPrint(
      'Doctor: ${result['doctor']}',
    );

    debugPrint(
      'Status: ${result['status']}',
    );

    debugPrint(
      'Expires: ${result['expires_at']}',
    );

    debugPrint(
      'Remaining: ${result['remaining_seconds']}',
    );

    debugPrint(
      '========================================',
    );

    notifyListeners();

    await connect();

    return result;
  }


  // =========================================================
  // CONNECT WEBSOCKET
  // =========================================================

  Future<void> connect() async {

    if (_socket != null) {
      return;
    }


    if (_roomId == null ||
        _patientToken == null) {

      throw Exception(
        'No sharing session available.',
      );
    }


    final wsUrl =
    _buildWebSocketUrl(
      _roomId!,
      _patientToken!,
    );


    debugPrint(
      'Connecting sharing WebSocket:',
    );

    debugPrint(
      wsUrl,
    );


    final socket =
    await WebSocket.connect(
      wsUrl,
    );


    _socket =
        socket;


    _socketSubscription =
        socket.listen(

              (dynamic message) {

            try {

              final decoded =
              jsonDecode(
                message.toString(),
              );


              if (decoded
              is Map<String, dynamic>) {

                _eventsController
                    .add(
                  decoded,
                );


                _handleEvent(
                  decoded,
                );
              }

            } catch (e) {

              debugPrint(
                'Invalid sharing message: $e',
              );
            }
          },


          onDone: () {

            debugPrint(
              'Sharing WebSocket closed.',
            );

            _socket =
            null;
          },


          onError: (error) {

            debugPrint(
              'Sharing WebSocket error: $error',
            );

            _socket =
            null;
          },
        );


    // Send patient's local information
    // immediately after connecting.

    await sendPatientData();
  }


  // =========================================================
  // BUILD WS URL
  // =========================================================

  String _buildWebSocketUrl(
      String roomId,
      String token,
      ) {

    const base =
        'ws://10.109.209.36:8000';


    return
      '$base/api/sharing/ws/'
          '${Uri.encodeComponent(roomId)}'
          '?role=patient'
          '&token=${Uri.encodeComponent(token)}';
  }


  // =========================================================
  // SEND PATIENT DATA
  // =========================================================

  Future<void>
  sendPatientData() async {

    if (_socket == null) {
      throw Exception(
        'Sharing WebSocket is not connected.',
      );
    }


    final profile =
    await _authManager
        .getLocalProfile();


    final medicalHistory =
    await _authManager
        .getLocalMedicalHistory();


    final reports =
    await _authManager
        .getReports();


    final data = {

      'profile':
      profile,

      'medical_history':
      medicalHistory?.toJson(),

      'reports':
      reports
          .map(
        _reportToShareableJson,
      )
          .toList(),
    };


    _socket!.add(
      jsonEncode({

        'type':
        'PATIENT_DATA',

        'data':
        data,
      }),
    );
  }


  // =========================================================
  // REPORT JSON
  // =========================================================

  Map<String, dynamic>
  _reportToShareableJson(
      ReportModel report,
      ) {

    return {

      'id':
      report.id,

      'title':
      report.title,

      'hospital':
      report.hospital,

      'type':
      report.type,

      'description':
      report.description,

      'file_type':
      report.fileType,

      'report_date':
      report.reportDate,

      'created_at':
      report.createdAt,

      // IMPORTANT:
      //
      // Do NOT send local filesystem paths.
      //
      // They are meaningless on the doctor's computer.

      'has_files':
      report.filePaths.isNotEmpty,
    };
  }


  // =========================================================
  // EVENTS
  // =========================================================

  void _handleEvent(
      Map<String, dynamic> event,
      ) {
    final type =
    event['type']?.toString();

    debugPrint(
      'Sharing event received: $event',
    );

    switch (type) {

      case 'PATIENT_JOINED':

        if (_activeSession == null) {
          _activeSession = {};
        }

        _activeSession!['patient_connected'] =
            event['patient_connected'] == true;

        notifyListeners();

        break;

      case 'DIAGNOSIS_SAVED':

        debugPrint(
          'Doctor saved diagnosis.',
        );

        break;

      case 'SESSION_ENDED':

        debugPrint(
          'Sharing session ended.',
        );

        _activeSession = null;

        notifyListeners();

        disconnect();

        break;

      case 'SESSION_EXPIRED':

        debugPrint(
          'Sharing session expired.',
        );

        _activeSession = null;

        notifyListeners();

        disconnect();

        break;

      default:

        debugPrint(
          'Unknown sharing event: $type',
        );
    }
  }


  // =========================================================
  // DISCONNECT
  // =========================================================

  Future<void> disconnect() async {
    await _socketSubscription
        ?.cancel();

    _socketSubscription =
    null;

    await _socket?.close();

    _socket =
    null;

    _roomId =
    null;

    _patientToken =
    null;

    _expiresAt =
    null;

    _activeSession =
    null;

    notifyListeners();
  }


  // =========================================================
  // DISPOSE
  // =========================================================

  Future<void> dispose() async {

    await disconnect();

    await _eventsController
        .close();
  }
}