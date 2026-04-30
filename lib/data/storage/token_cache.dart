/// In-memory tokens for synchronous access from [Dio] interceptors.
class TokenCache {
  TokenCache._();
  static final TokenCache instance = TokenCache._();

  String? accessToken;
  String? refreshToken;

  void setTokens({String? access, String? refresh}) {
    if (access != null) accessToken = access;
    if (refresh != null) refreshToken = refresh;
  }

  void clear() {
    accessToken = null;
    refreshToken = null;
  }
}
