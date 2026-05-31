import 'package:flutter/widgets.dart';

import 'generated/app_localizations.dart';

export 'generated/app_localizations.dart';

extension BuildContextL10n on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

String localized(
  BuildContext context, {
  required String id,
  required String en,
}) {
  return Localizations.localeOf(context).languageCode == 'id' ? id : en;
}

String medicineMealTimingLabel(BuildContext context, String value) {
  switch (value) {
    case 'sebelum_makan':
      return context.l10n.mealBefore;
    case 'sesudah_makan':
      return context.l10n.mealAfter;
    case 'saat_makan':
      return context.l10n.mealDuring;
    default:
      return context.l10n.mealFree;
  }
}
