import 'package:flutter/widgets.dart';
import 'package:global_logistics_app/l10n/app_localizations.dart';

export 'package:global_logistics_app/l10n/app_localizations.dart';

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
