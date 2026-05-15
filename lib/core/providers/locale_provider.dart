import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_logistics_app/data/storage/locale_preferences.dart';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale?>(
  (ref) => LocaleNotifier(),
);

class LocaleNotifier extends StateNotifier<Locale?> {
  LocaleNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    final code = await LocalePreferences.instance.getLanguageCode();
    if (code == null) return;
    if (code == 'en' || code == 'am') {
      state = Locale(code);
    }
  }

  Future<void> setLocale(String languageCode) async {
    await LocalePreferences.instance.setLanguageCode(languageCode);
    state = Locale(languageCode);
  }
}
