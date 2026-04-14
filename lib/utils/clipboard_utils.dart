import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    const SnackBar(
      content: Text('Скопировано в буфер обмена'),
      duration: Duration(seconds: 2),
    ),
  );
}
