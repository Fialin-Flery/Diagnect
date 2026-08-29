import 'package:flutter/material.dart';

import 'package:diagnect/features/auth/login_page.dart';
import 'package:diagnect/features/home/home_page.dart';
import 'package:diagnect/features/profile/profile_setup_page.dart';
import 'package:diagnect/services/auth_manager.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
  });

  @override
  State<AuthGate> createState() =>
      _AuthGateState();
}

class _AuthGateState
    extends State<AuthGate> {

  final AuthManager _authManager =
      AuthManager.instance;

  bool _loading = true;

  bool _loggedIn = false;

  bool _profileComplete = false;

  @override
  void initState() {
    super.initState();

    _restore();
  }

  // =========================================================
  // RESTORE
  // =========================================================

  Future<void> _restore() async {

    try {

      final loggedIn =
      await _authManager
          .restoreSession();

      if (!loggedIn) {

        if (!mounted) {
          return;
        }

        setState(() {
          _loggedIn = false;
          _loading = false;
        });

        return;
      }

      Map<String, dynamic>?
      profile;

      try {

        profile =
        await _authManager
            .fetchProfile();

      } catch (_) {

        profile =
        await _authManager
            .getLocalProfile();
      }

      final complete =
          profile?[
          'profile_completed'] ==
              true;

      if (!mounted) {
        return;
      }

      setState(() {

        _loggedIn = true;

        _profileComplete =
            complete;

        _loading = false;

      });

    } catch (e) {

      debugPrint(
        'AuthGate error: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {

        _loggedIn = false;

        _loading = false;

      });
    }
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
      BuildContext context,
      ) {

    if (_loading) {

      return const Scaffold(
        body: Center(
          child:
          CircularProgressIndicator(),
        ),
      );
    }

    if (!_loggedIn) {

      return const LoginPage();
    }

    if (!_profileComplete) {

      return const ProfileSetupPage();
    }

    return const HomePage();
  }
}