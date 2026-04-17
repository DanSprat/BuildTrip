import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';

/// Копирует непустую строку и показывает подтверждение.
Future<void> copyToClipboard(BuildContext context, String? text) async {
  final s = text?.trim() ?? '';
  if (s.isEmpty) {
    return;
  }
  await Clipboard.setData(ClipboardData(text: s));
  if (!context.mounted) {
    return;
  }
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(context.l10n.t('copiedToClipboard')),
      duration: const Duration(seconds: 2),
    ),
  );
}
