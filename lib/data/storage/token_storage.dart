import 'package:shared_preferences/shared_preferences.dart';
import 'package:global_logistics_app/data/storage/token_cache.dart';

class TokenStorage {
  TokenStorage._();
  static final TokenStorage instance = TokenStorage._();

  static const _kAccess = 'gl_access_token';
  static const _kRefresh = 'gl_refresh_token';

  Future<void> loadIntoCache() async {
    final p = await SharedPreferences.getInstance();
    TokenCache.instance.accessToken = p.getString(_kAccess);
    TokenCache.instance.refreshToken = p.getString(_kRefresh);
  }

  Future<void> persistTokens({String? access, String? refresh}) async {
    final p = await SharedPreferences.getInstance();
    if (access != null) {
      await p.setString(_kAccess, access);
      TokenCache.instance.accessToken = access;
    }
    if (refresh != null) {
      await p.setString(_kRefresh, refresh);
      TokenCache.instance.refreshToken = refresh;
    }
  }

  Future<void> clearPersisted() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kAccess);
    await p.remove(_kRefresh);
    TokenCache.instance.clear();
  }
}
