import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_logistics_app/app.dart';
import 'package:global_logistics_app/data/storage/token_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TokenStorage.instance.loadIntoCache();
  runApp(const ProviderScope(child: GlobalLogisticsApp()));
}
