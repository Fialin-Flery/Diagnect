import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';


class DeepLinkService {
  final AppLinks _appLinks = AppLinks();

  StreamSubscription<Uri>? _subscription;

  Future<void> initialize({
    required Function(Uri uri) onLink,
  }) async {

    // Listen for links while app is running/resumed
    _subscription = _appLinks.uriLinkStream.listen(
          (uri) {
        debugPrint('==============================');
        debugPrint('RECEIVED DEEP LINK');
        debugPrint('URI: $uri');
        debugPrint('==============================');

        onLink(uri);
      },
      onError: (error) {
        debugPrint('Deep link error: $error');
      },
    );

    // Handle link that launched/relaunched the app
    try {
      final initialUri = await _appLinks.getInitialLink();

      if (initialUri != null) {
        debugPrint('==============================');
        debugPrint('RECEIVED INITIAL DEEP LINK');
        debugPrint('URI: $initialUri');
        debugPrint('==============================');

        onLink(initialUri);
      }
    } catch (e) {
      debugPrint('Initial deep link error: $e');
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}