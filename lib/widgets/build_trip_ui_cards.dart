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
    return Padding(
      padding: EdgeInsets.only(bottom: marginBottom),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.45),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: scheme.outline),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.35,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
