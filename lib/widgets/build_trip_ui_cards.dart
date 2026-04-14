import 'package:flutter/material.dart';

/// Карточка-секция (просмотр и редактирование места / перемещения).
class BuildTripSectionCard extends StatelessWidget {
  const BuildTripSectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.marginBottom = 12,
    this.titleTrailing,
  });

  final IconData icon;
  final String title;
  final Widget child;

  /// Элемент справа в строке заголовка (например, кнопка действия).
  final Widget? titleTrailing;

  /// Отступ снизу до следующей секции (у последней карточки можно задать 0).
  final double marginBottom;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(bottom: marginBottom),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: scheme.outlineVariant.withValues(
              alpha: isDark ? 0.62 : 0.45,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? scheme.onSurface.withValues(alpha: 0.14)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: scheme.primary.withValues(alpha: 0.9),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: t.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.25,
                    ),
                  ),
                ),
                if (titleTrailing != null) titleTrailing!,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

/// Пустое состояние внутри секции.
class BuildTripEmptyHint extends StatelessWidget {
  const BuildTripEmptyHint({
    super.key,
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hintBg = isDark
        ? scheme.surfaceContainerHighest.withValues(alpha: 0.58)
        : scheme.surfaceContainerHighest.withValues(alpha: 0.4);
    final hintBorder = scheme.outlineVariant.withValues(
      alpha: isDark ? 0.55 : 0.4,
    );
    final iconColor = isDark
        ? Color.lerp(scheme.primary, scheme.onSurfaceVariant, 0.42)!
        : scheme.outline;
    final textColor = isDark
        ? Color.lerp(scheme.onSurfaceVariant, scheme.onSurface, 0.22)!
        : scheme.onSurfaceVariant;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: hintBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: hintBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: textColor,
                    height: 1.35,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
