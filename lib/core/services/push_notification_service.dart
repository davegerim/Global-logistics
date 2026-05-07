import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:global_logistics_app/firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('FCM background message: ${message.messageId}');
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('FCM permission status: ${settings.authorizationStatus}');

    final token = await _messaging.getToken();
    if (token != null && token.isNotEmpty) {
      debugPrint('FCM token: $token');
    }

    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('FCM token refreshed: $newToken');
    });

    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('FCM foreground message: ${message.messageId}');
    });
  }
}
