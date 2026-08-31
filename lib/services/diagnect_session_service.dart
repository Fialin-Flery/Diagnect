
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class DiagnectSessionService extends ChangeNotifier {
  DiagnectSessionService._privateConstructor();

  static final DiagnectSessionService instance =
  DiagnectSessionService._privateConstructor();

  WebSocketChannel? _channel;

  StreamSubscription? _subscription;

// =========================================================
// CURRENT ACTIVE SESSION
// =========================================================

  Map<String, dynamic>? _activeSession;

  Map<String, dynamic>? get activeSession =>
      _activeSession;

  bool get hasActiveSession =>
      _activeSession != null;

// =========================================================
// CONNECT
// =========================================================

  void connect({
    required String sessionId,
    required String accessToken,
  }) {
    disconnect();

    final uri = Uri.parse(
      'ws://10.109.209.36:8000/ws/session/$sessionId'
          '?token=${Uri.encodeComponent(accessToken)}',
    );

    debugPrint(
      'Connecting to Diagnect session WebSocket:',
    );

    debugPrint(uri.toString());

    _channel = WebSocketChannel.connect(uri);

    _subscription = _channel!.stream.listen(
      _handleMessage,

      onError: (error) {
        debugPrint(
          'Diagnect WebSocket error: $error',
        );
      },

      onDone: () {
        debugPrint(
          'Diagnect WebSocket disconnected.',
        );

        _channel = null;
        _subscription = null;
      },

      cancelOnError: false,
    );
  }

// =========================================================
// HANDLE MESSAGE
// =========================================================

  Future<void> _handleMessage(
      dynamic rawMessage,
      ) async {

    try {
      final decoded =
      jsonDecode(rawMessage.toString());

      if (decoded is! Map<String, dynamic>) {
        return;
      }

      final event =
      decoded['event']?.toString();

      debugPrint(
        'Diagnect WebSocket event: $event',
      );

      switch (event) {

// ---------------------------------------------------
// SESSION STARTED
// ---------------------------------------------------

        case 'session_joined':
          _handleSessionJoined(decoded);
          break;

// ---------------------------------------------------
// DOCTOR CONNECTED
// ---------------------------------------------------

        case 'doctor_connected':
          _handleDoctorConnected(decoded);
          break;

// ---------------------------------------------------
// SESSION EXPIRED
// ---------------------------------------------------

        case 'session_expired':
          _handleSessionExpired();
          break;

// ---------------------------------------------------
// SESSION CLOSED
// ---------------------------------------------------

        case 'session_closed':
          _handleSessionExpired();
          break;

// ---------------------------------------------------
// DIAGNOSIS SAVED
// ---------------------------------------------------

        case 'diagnosis_saved':
          await _handleDiagnosisSaved(decoded);
          break;

        default:
          debugPrint(
            'Unknown WebSocket event: $event',
          );
      }

    } catch (e) {

      debugPrint(
        'Unable to process WebSocket message: $e',
      );
    }
  }

// =========================================================
// SESSION JOINED
// =========================================================

  void _handleSessionJoined(
      Map<String, dynamic> event,
      ) {

    final session =
    event['session'];

    if (session is! Map<String, dynamic>) {
      debugPrint(
        'Invalid session_joined payload.',
      );

      return;
    }

    _activeSession =
    Map<String, dynamic>.from(session);

    notifyListeners();
  }

// =========================================================
// DOCTOR CONNECTED
// =========================================================

  void _handleDoctorConnected(
      Map<String, dynamic> event,
      ) {

    if (_activeSession == null) {
      _activeSession = {};
    }

    final doctor =
    event['doctor'];

    if (doctor is Map<String, dynamic>) {
      _activeSession!['doctor'] =
          doctor;
    }

    _activeSession!['doctor_connected'] =
    true;

    notifyListeners();
  }

// =========================================================
// SESSION EXPIRED / CLOSED
// =========================================================

  void _handleSessionExpired() {

    debugPrint(
      'Diagnect active session ended.',
    );

    _activeSession = null;

    notifyListeners();

    disconnect();
  }

// =========================================================
// DIAGNOSIS SAVED
// =========================================================

  Future<void> _handleDiagnosisSaved(
      Map<String, dynamic> event,
      ) async {

    debugPrint(
      'Diagnosis saved event received.',
    );

    final diagnosis =
    event['diagnosis'];

    if (diagnosis
    is! Map<String, dynamic>) {

      debugPrint(
        'Invalid diagnosis payload.',
      );

      return;
    }

/*
     * IMPORTANT:
     *
     * The actual saving into the patient's
     * local Reports database is handled by
     * AuthManager.
     */

    await _saveDiagnosisToLocalReports(
      diagnosis,
    );

/*
     * The doctor's session is finished
     * once diagnosis has been saved.
     */

    _activeSession = null;

    notifyListeners();

    disconnect();
  }

// =========================================================
// SAVE DIAGNOSIS TO LOCAL REPORTS
// =========================================================

  Future<void> _saveDiagnosisToLocalReports(
      Map<String, dynamic> diagnosis,
      ) async {

/*
     * This callback will be connected to
     * AuthManager.
     *
     * We deliberately do not put database
     * code directly inside the WebSocket
     * service.
     */

    if (_diagnosisCallback != null) {

      await _diagnosisCallback!(
        diagnosis,
      );
    }
  }

// =========================================================
// DIAGNOSIS CALLBACK
// =========================================================

  Future<void> Function(
      Map<String, dynamic>,
      )? _diagnosisCallback;

  void registerDiagnosisCallback(
      Future<void> Function(
          Map<String, dynamic>,
          ) callback,
      ) {

    _diagnosisCallback =
        callback;
  }

// =========================================================
// DISCONNECT
// =========================================================

  void disconnect() {

    _subscription?.cancel();

    _subscription = null;

    try {
      _channel?.sink.close();
    } catch (_) {}

    _channel = null;
  }

// =========================================================
// DISPOSE
// =========================================================

  @override
  void dispose() {

    disconnect();

    super.dispose();
  }
}

