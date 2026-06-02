import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import 'generated/app_localizations.dart';

export 'generated/app_localizations.dart';

extension BuildContextL10n on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  Locale get locale => Localizations.localeOf(this);
  String get localeTag => locale.languageCode;
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

String formatLongDate(BuildContext context, DateTime date) {
  return DateFormat('EEEE, d MMM yyyy', context.localeTag).format(date);
}

String formatMonthYear(BuildContext context, DateTime date) {
  return DateFormat('MMM yyyy', context.localeTag).format(date);
}

String formatShortDate(BuildContext context, DateTime date) {
  return DateFormat('EEE, d MMM', context.localeTag).format(date);
}

List<String> localizedWeekdayShortLabels(BuildContext context) {
  final baseMonday = DateTime(2026, 6, 1);
  final format = DateFormat('EEE', context.localeTag);
  return List.generate(
    7,
    (index) => format.format(baseMonday.add(Duration(days: index))),
  );
}
