import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's chosen app UI language (`en` or `am`).
class LocalePreferences {
  LocalePreferences._();
  static final LocalePreferences instance = LocalePreferences._();

  static const _kLanguageCode = 'gl_app_language_code';

  Future<String?> getLanguageCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kLanguageCode);
  }

  Future<void> setLanguageCode(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLanguageCode, languageCode);
  }
}
