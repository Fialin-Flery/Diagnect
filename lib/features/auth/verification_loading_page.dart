import 'dart:async';

import 'package:flutter/material.dart';
import 'package:diagnect/services/auth_manager.dart';
import 'package:diagnect/services/auth_api_service.dart';
import 'package:diagnect/features/home/home_page.dart';
import '../../app/theme/app_colors.dart';
import 'package:diagnect/features/auth/login_page.dart';
import 'package:diagnect/features/profile/profile_setup_page.dart';

class VerificationLoadingPage extends StatefulWidget {
  const VerificationLoadingPage({
    super.key,
    required this.verificationId,
    required this.aadhaarNumber,
  });

  final String verificationId;
  final String aadhaarNumber;

  @override
  State<VerificationLoadingPage> createState() =>
      _VerificationLoadingPageState();
}

class _VerificationLoadingPageState
    extends State<VerificationLoadingPage> {

  final AuthApiService _authApiService = AuthApiService();
  final AuthManager _authManager = AuthManager.instance;
  Timer? _retryTimer;

  bool _checking = false;

  int _attempt = 0;

  // Maximum number of status checks.
  static const int _maxAttempts = 10;

  // Time between status checks.
  static const Duration _retryDelay =
  Duration(seconds: 2);

  String _message = 'Verifying your identity...';

  @override
  void initState() {
    super.initState();

    // Start checking after the page has been built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVerificationStatus();
    });
  }

  // ---------------------------------------------------------
  // CHECK VERIFICATION STATUS
  // ---------------------------------------------------------

  Future<void> _checkVerificationStatus() async {

    // Prevent two checks from running at the same time.
    if (_checking) {
      return;
    }

    if (!mounted) {
      return;
    }

    if (_attempt >= _maxAttempts) {
      _goToLogin(
        status: 'VERIFICATION_TIMEOUT',
      );
      return;
    }

    _checking = true;

    _attempt++;

    setState(() {
      _message =
      'Checking verification status...';
    });

    debugPrint(
      '========================================',
    );

    debugPrint(
      'VERIFICATION STATUS CHECK',
    );

    debugPrint(
      'Verification ID: ${widget.verificationId}',
    );

    debugPrint(
      'Attempt: $_attempt / $_maxAttempts',
    );

    try {

      final response =
      await _authApiService.getDigiLockerStatus(
        widget.verificationId,
      );

      debugPrint(
        'Backend status response: $response',
      );

      final cashfree =
      response['cashfree'];

      final String status =
          cashfree?['status']
              ?.toString()
              .toUpperCase() ??
              'ERROR';

      debugPrint(
        'ACTUAL CASHFREE STATUS: $status',
      );

      // -----------------------------------------------------
      // SUCCESS
      // -----------------------------------------------------

      if (status == 'AUTHENTICATED') {

        debugPrint(
          '========================================',
        );

        debugPrint(
          'VERIFICATION SUCCESSFUL',
        );

        _checking = false;

        if (!mounted) {
          return;
        }

        try {

          setState(() {
            _message =
            'Setting up your secure account...';
          });

          // -------------------------------------------------------
          // CREATE DIAGNECT SESSION
          // -------------------------------------------------------

          await _authManager.completeLogin(
            verificationId:
            widget.verificationId,
            aadhaarNumber:
            widget.aadhaarNumber,
          );

          debugPrint(
            'Diagnect session created.',
          );

          // -------------------------------------------------------
          // FETCH PROFILE
          // -------------------------------------------------------

          try {

            setState(() {
              _message =
              'Loading your health profile...';
            });

            final profile =
            await _authManager.fetchProfile();

            debugPrint(
              'Profile retrieved: $profile',
            );

          } catch (e) {

            /*
       * Do NOT fail login just because profile
       * retrieval failed.
       *
       * We already have a valid session.
       */

            debugPrint(
              'Profile retrieval failed: $e',
            );
          }

          // -------------------------------------------------------
          // CHECK PROFILE COMPLETION
          // -------------------------------------------------------

          if (!mounted) {
            return;
          }

          final profile =
          await _authManager.getLocalProfile();

          final profileCompleted =
              profile?['profile_completed'] == true;

          if (profileCompleted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => const HomePage(),
              ),
                  (route) => false,
            );
          } else {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => const ProfileSetupPage(),
              ),
                  (route) => false,
            );
          }

        } catch (e, stackTrace) {

          debugPrint(
            'Unable to create Diagnect session: $e',
          );

          debugPrint(
            'STACK TRACE: $stackTrace',
          );

          if (!mounted) {
            return;
          }

          _goToLogin(
            status: 'SESSION_CREATION_FAILED',
          );
        }

        return;
      }

      // -----------------------------------------------------
      // TERMINAL FAILURE STATES
      // -----------------------------------------------------

      if (_isFailureStatus(status)) {

        debugPrint(
          'Verification failed with status: $status',
        );

        _checking = false;

        if (!mounted) {
          return;
        }

        _goToLogin(
          status: status,
        );

        return;
      }

      // -----------------------------------------------------
      // STILL PROCESSING
      // -----------------------------------------------------

      debugPrint(
        'Verification still in progress.',
      );

      _checking = false;

      if (!mounted) {
        return;
      }

      setState(() {
        _message =
        'Verification is still in progress...';
      });

      _scheduleNextCheck();

    } catch (e, stackTrace) {

      debugPrint(
        'Error checking verification status: $e',
      );

      debugPrint(
        'STACK TRACE: $stackTrace',
      );

      _checking = false;

      if (!mounted) {
        return;
      }

      setState(() {
        _message =
        'Unable to check verification status.\n'
            'Retrying...';
      });

      // Network/server errors should not immediately
      // send the user back to login.
      _scheduleNextCheck();
    }
  }

  // ---------------------------------------------------------
  // DETERMINE FAILURE STATUS
  // ---------------------------------------------------------

  bool _isFailureStatus(String status) {

    const failureStatuses = {
      'FAILED',
      'FAILURE',
      'USER_CANCELLED',
      'CANCELLED',
      'EXPIRED',
      'REJECTED',
      'VERIFICATION_FAILED',
    };

    return failureStatuses.contains(status);
  }

  // ---------------------------------------------------------
  // SCHEDULE NEXT CHECK
  // ---------------------------------------------------------

  void _scheduleNextCheck() {

    _retryTimer?.cancel();

    if (_attempt >= _maxAttempts) {

      debugPrint(
        'Maximum verification attempts reached.',
      );

      _goToLogin(
        status: 'VERIFICATION_TIMEOUT',
      );

      return;
    }

    debugPrint(
      'Next verification check in '
          '${_retryDelay.inSeconds} seconds.',
    );

    _retryTimer = Timer(
      _retryDelay,
          () {
        if (!mounted) {
          return;
        }

        _checkVerificationStatus();
      },
    );
  }

  // ---------------------------------------------------------
  // GO TO LOGIN
  // ---------------------------------------------------------

  void _goToLogin({
    required String status,
  }) {

    if (!mounted) {
      return;
    }

    debugPrint(
      'Navigating back to LoginPage.',
    );

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => LoginPage(
          verificationFailed: true,
          verificationStatus: status,
        ),
      ),
          (route) => false,
    );
  }

  // ---------------------------------------------------------
  // DISPOSE
  // ---------------------------------------------------------

  @override
  void dispose() {

    _retryTimer?.cancel();

    super.dispose();
  }

  // ---------------------------------------------------------
  // UI
  // ---------------------------------------------------------

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      body: SafeArea(

        child: Center(

          child: Padding(

            padding: const EdgeInsets.symmetric(
              horizontal: 32,
            ),

            child: Column(

              mainAxisAlignment:
              MainAxisAlignment.center,

              children: [

                // -------------------------------------------
                // LOGO
                // -------------------------------------------

                Image.asset(
                  'assets/images/diagnect_logo.png',
                  height: 100,
                  filterQuality: FilterQuality.high,
                ),

                const SizedBox(height: 24),

                Image.asset(
                  'assets/images/diagnect_text.png',
                  height: 42,
                  filterQuality: FilterQuality.high,
                ),

                const SizedBox(height: 48),

                // -------------------------------------------
                // LOADING INDICATOR
                // -------------------------------------------

                const SizedBox(
                  width: 45,
                  height: 45,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                  ),
                ),

                const SizedBox(height: 32),

                // -------------------------------------------
                // TITLE
                // -------------------------------------------

                const Text(
                  'Verifying your identity',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
                ),

                const SizedBox(height: 12),

                // -------------------------------------------
                // STATUS MESSAGE
                // -------------------------------------------

                Text(
                  _message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: AppColors.secondaryText,
                  ),
                ),

                const SizedBox(height: 20),

                // -------------------------------------------
                // ATTEMPT COUNT
                // -------------------------------------------

                Text(
                  'Please wait...',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.secondaryText,
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}