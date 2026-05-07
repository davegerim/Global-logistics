import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_logistics_app/app.dart';
import 'package:global_logistics_app/core/services/push_notification_service.dart';
import 'package:global_logistics_app/data/storage/token_storage.dart';
import 'package:global_logistics_app/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await PushNotificationService.instance.initialize();
  await TokenStorage.instance.loadIntoCache();
  runApp(const ProviderScope(child: GlobalLogisticsApp()));
}
