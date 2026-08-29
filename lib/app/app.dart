import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:diagnect/services/pending_verification_service.dart';
import 'theme/app_theme.dart';
import 'package:diagnect/features/auth/app_start_page.dart';
import 'package:diagnect/features/auth/login_page.dart';
import 'package:diagnect/features/auth/verification_loading_page.dart';

class DiagnectApp extends StatefulWidget {
  const DiagnectApp({
    super.key,
  });

  @override
  State<DiagnectApp> createState() =>
      _DiagnectAppState();
}

class _DiagnectAppState extends State<DiagnectApp> {

  final AppLinks _appLinks = AppLinks();


  StreamSubscription<Uri>? _linkSubscription;

  final GlobalKey<NavigatorState>
  _navigatorKey =
  GlobalKey<NavigatorState>();

  bool _processingDeepLink = false;

  @override
  void initState() {
    super.initState();

    _initDeepLinks();
  }

  // ---------------------------------------------------------
  // INITIALIZE DEEP LINKS
  // ---------------------------------------------------------

  Future<void> _initDeepLinks() async {

    // ---------------------------------------------------------
    // LINKS RECEIVED WHILE APP IS RUNNING
    // ---------------------------------------------------------

    _linkSubscription =
        _appLinks.uriLinkStream.listen(
              (Uri uri) {

            debugPrint(
              'Deep link received from stream: $uri',
            );

            _handleDeepLink(uri);
          },

          onError: (error) {

            debugPrint(
              'Deep link error: $error',
            );
          },
        );

    // ---------------------------------------------------------
    // LINK THAT LAUNCHED THE APP
    // ---------------------------------------------------------

    try {

      final initialUri =
      await _appLinks.getInitialLink();

      if (initialUri != null) {

        debugPrint(
          'Initial deep link received: $initialUri',
        );

        WidgetsBinding.instance
            .addPostFrameCallback(
              (_) {
            _handleDeepLink(initialUri);
          },
        );
      }

    } catch (e) {

      debugPrint(
        'Initial deep link error: $e',
      );
    }
  }

  // ---------------------------------------------------------
  // HANDLE DIGILOCKER CALLBACK
  // ---------------------------------------------------------

  Future<void> _handleDeepLink(Uri uri) async {

    if (_processingDeepLink) {

      debugPrint(
        'Already processing a deep link.',
      );

      return;
    }

    debugPrint(
      '================================',
    );

    debugPrint(
      'RECEIVED DEEP LINK',
    );

    debugPrint(
      'URI: $uri',
    );

    debugPrint(
      'SCHEME: ${uri.scheme}',
    );

    debugPrint(
      'HOST: ${uri.host}',
    );

    debugPrint(
      'PATH: ${uri.path}',
    );

    debugPrint(
      '================================',
    );

    // -------------------------------------------------------
    // VALIDATE SCHEME
    // -------------------------------------------------------

    if (uri.scheme != 'diagnect') {

      debugPrint(
        'Not a Diagnect deep link.',
      );

      return;
    }

    // -------------------------------------------------------
    // VALIDATE HOST
    // -------------------------------------------------------

    if (uri.host != 'digilocker') {

      debugPrint(
        'Not a DigiLocker deep link.',
      );

      return;
    }

    // -------------------------------------------------------
    // VALIDATE PATH
    // -------------------------------------------------------

    if (uri.path != '/callback') {

      debugPrint(
        'Not a DigiLocker callback.',
      );

      return;
    }

    // -------------------------------------------------------
// GET VERIFICATION ID
// -------------------------------------------------------

    final String? verificationId =
    uri.queryParameters['verification_id'];

    if (verificationId == null ||
        verificationId.isEmpty) {

      debugPrint(
        'No verification_id received.',
      );

      return;
    }

    debugPrint(
      'Verification ID: $verificationId',
    );

// -------------------------------------------------------
// GET PENDING AADHAAR NUMBER
// -------------------------------------------------------

    final String? aadhaarNumber =
        PendingVerificationService.instance.aadhaarNumber;

    if (aadhaarNumber == null ||
        aadhaarNumber.isEmpty) {

      debugPrint(
        'No Aadhaar number found for this verification.',
      );

      return;
    }

    debugPrint(
      'Aadhaar number found for verification.',
    );

    _processingDeepLink = true;

    // -------------------------------------------------------
    // SHOW VERIFICATION LOADING PAGE
    // -------------------------------------------------------

    WidgetsBinding.instance.addPostFrameCallback(
          (_) {

        if (!mounted) {

          _processingDeepLink = false;

          return;
        }

        final navigator =
            _navigatorKey.currentState;

        debugPrint(
          'Navigator state: $navigator',
        );

        if (navigator == null) {

          debugPrint(
            'ERROR: Navigator is null.',
          );

          _processingDeepLink = false;

          return;
        }

        debugPrint(
          'Navigating to VerificationLoadingPage.',
        );

        navigator.pushAndRemoveUntil(

          MaterialPageRoute(
            builder: (_) =>
                VerificationLoadingPage(
                  verificationId: verificationId,
                  aadhaarNumber: aadhaarNumber,
                ),
          ),

              (route) => false,
        );

        debugPrint(
          'VerificationLoadingPage navigation requested.',
        );

        // The loading page now owns the verification process.
        _processingDeepLink = false;
      },
    );
  }

  // ---------------------------------------------------------
  // DISPOSE
  // ---------------------------------------------------------

  @override
  void dispose() {

    _linkSubscription?.cancel();

    super.dispose();
  }

  // ---------------------------------------------------------
  // APP
  // ---------------------------------------------------------

  @override
  Widget build(
      BuildContext context,
      ) {

    return MaterialApp(

      debugShowCheckedModeBanner: false,

      title: 'Diagnect',

      theme: AppTheme.lightTheme,

      navigatorKey: _navigatorKey,

      // -----------------------------------------------------
      // ROUTES
      // -----------------------------------------------------

      routes: {
        '/login': (_) => const LoginPage(),
      },

      home: const AppStartPage(),
    );
  }
}