import 'package:flutter/material.dart';

import 'package:diagnect/app/theme/app_colors.dart';
import 'package:diagnect/features/auth/login_page.dart';
import 'package:diagnect/features/home/home_page.dart';
import 'package:diagnect/services/auth_manager.dart';
import 'package:diagnect/features/profile/profile_setup_page.dart';

class AppStartPage extends StatefulWidget {
  const AppStartPage({
    super.key,
  });

  @override
  State<AppStartPage> createState() =>
      _AppStartPageState();
}

class _AppStartPageState
    extends State<AppStartPage> {

  final AuthManager _authManager =
      AuthManager.instance;

  @override
  void initState() {
    super.initState();

    _initializeApp();
  }

  // =========================================================
  // INITIALIZE
  // =========================================================

  Future<void> _initializeApp() async {

    try {

      final restored =
      await _authManager.restoreSession();

      if (!mounted) {
        return;
      }

      if (restored) {

        // ------------------ ---------------------------------
        // SESSION RESTORED
        // ---------------------------------------------------


        if (!mounted) {
          return;
        }

        /*
         * If there is no cached profile,
         * HomePage can fetch it from the backend.
         */

        Map<String, dynamic>? profile;

        try {
          profile =
          await _authManager.fetchProfile();
        } catch (e) {
          debugPrint(
            'Profile fetch failed: $e',
          );

          profile =
          await _authManager.getLocalProfile();
        }

        final profileCompleted =
            profile?['profile_completed'] == true;

        if (!mounted) {
          return;
        }

        if (profileCompleted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) =>
              const HomePage(),
            ),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) =>
              const ProfileSetupPage(),
            ),
          );
        }

      } else {

        // ---------------------------------------------------
        // NO VALID SESSION
        // ---------------------------------------------------

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) =>
            const LoginPage(),
          ),
        );
      }

    } catch (e) {

      debugPrint(
        'App initialization error: $e',
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
          const LoginPage(),
        ),
      );
    }
  }

  // =========================================================
  // UI
  // =========================================================

  @override
  Widget build(
      BuildContext context,
      ) {

    return Scaffold(
      backgroundColor:
      AppColors.background,

      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment:
            MainAxisAlignment.center,

            children: [

              Image.asset(
                'assets/images/diagnect_logo.png',
                height: 100,
                filterQuality:
                FilterQuality.high,
              ),

              const SizedBox(height: 24),

              Image.asset(
                'assets/images/diagnect_text.png',
                height: 42,
                filterQuality:
                FilterQuality.high,
              ),

              const SizedBox(height: 40),

              const SizedBox(
                width: 35,
                height: 35,
                child:
                CircularProgressIndicator(
                  strokeWidth: 3,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Securing your health wallet...',
                style: TextStyle(
                  fontSize: 14,
                  color:
                  AppColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}