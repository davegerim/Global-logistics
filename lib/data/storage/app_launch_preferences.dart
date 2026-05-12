import 'package:shared_preferences/shared_preferences.dart';

/// Persists whether the user has already seen the first-launch walkthrough.
/// Logout does not clear this: later cold starts go to [LoginScreen], not
/// [OnboardingScreen], while tokens still restore the session via bootstrap.
class AppLaunchPreferences {
  AppLaunchPreferences._();
  static final AppLaunchPreferences instance = AppLaunchPreferences._();

  static const _kIntroWalkthroughDone = 'gl_intro_walkthrough_done';

  Future<bool> isIntroWalkthroughDone() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kIntroWalkthroughDone) ?? false;
  }

  Future<void> setIntroWalkthroughDone() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kIntroWalkthroughDone, true);
  }
}
