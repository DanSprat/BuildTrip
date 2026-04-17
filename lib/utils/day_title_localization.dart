import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';

final List<RegExp> _kAutoDayTitlePatterns = <RegExp>[
  RegExp(r'^day\s+(\d+)\s*$', caseSensitive: false),
  RegExp(r'^день\s+(\d+)\s*$', caseSensitive: false),
  RegExp(r'^jour\s+(\d+)\s*$', caseSensitive: false),
  RegExp(r'^d[ií]a\s+(\d+)\s*$', caseSensitive: false),
  RegExp(r'^(\d+)\s*日目$'),
];

String localizeDayTitleIfAuto(BuildContext context, String rawTitle) {
  final trimmed = rawTitle.trim();
  for (final pattern in _kAutoDayTitlePatterns) {
    final match = pattern.firstMatch(trimmed);
    if (match == null) {
      continue;
    }
    final dayNumber = match.group(1);
    if (dayNumber == null) {
      continue;
    }
    return context.l10n.t('dayTitle', params: {'day': dayNumber});
  }
  return rawTitle;
}
