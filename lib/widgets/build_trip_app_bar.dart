import 'package:flutter/material.dart';

/// Единая шапка: заметная кнопка назад, лёгкий фон и разделитель с контентом.
class BuildTripAppBar extends StatelessWidget implements PreferredSizeWidget {
  const BuildTripAppBar({
    super.key,
    required this.titleText,
    this.actions,
    this.showBackButton = true,
    this.showBrandIcon = false,
    this.centerTitle = false,
    this.titleWidget,
    this.onBackPressed,
  });

  final String titleText;
  final List<Widget>? actions;

  /// Если задано, кнопка «назад» вызывает его вместо [Navigator.maybePop].
  final VoidCallback? onBackPressed;

  /// Заголовок по центру экрана (между кнопками), а не слева после «назад».
  final bool centerTitle;

  /// Свой виджет заголовка; если null — обычный [Text] с [titleText].
  final Widget? titleWidget;

  /// Показывать стрелку «назад», если в стеке есть маршрут для pop.
  final bool showBackButton;

  /// На корневом экране — маленькая иконка приложения слева от заголовка.
  final bool showBrandIcon;

  /// Единый размер, форма и цвет для кнопок в шапке (назад, действия справа).
  /// [destructive] — для удаления и прочих опасных действий.
  static ButtonStyle toolbarIconStyle(
    ColorScheme scheme, {
    bool destructive = false,
  }) {
    final fg = destructive ? scheme.error : scheme.primary;
    final bg = destructive
        ? scheme.error.withValues(alpha: 0.12)
        : scheme.primary.withValues(alpha: 0.12);
    return IconButton.styleFrom(
      iconSize: 22,
      visualDensity: VisualDensity.compact,
      fixedSize: const Size(40, 40),
      minimumSize: const Size(40, 40),
      maximumSize: const Size(40, 40),
      padding: EdgeInsets.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      backgroundColor: bg,
      foregroundColor: fg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final canPop = Navigator.canPop(context);
    final showBack = showBackButton && canPop;

    final titleStyle = theme.textTheme.titleLarge?.copyWith(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      height: 1.15,
      letterSpacing: -0.55,
      color: Color.lerp(
        scheme.onSurface,
        scheme.primary,
        0.08,
      ),
    );

    final titleChild = titleWidget ??
        Text(
          titleText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: titleStyle,
        );

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow.withValues(alpha: 0.72),
          border: Border(
            bottom: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: kToolbarHeight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
              child: centerTitle
                  ? _CenteredTitleBar(
                      scheme: scheme,
                      showBack: showBack,
                      showBrandIcon: showBrandIcon,
                      actions: actions,
                      titleText: titleText,
                      titleChild: titleChild,
                      onBackPressed: onBackPressed,
                    )
                  : Row(
                      children: [
                        if (showBack) ...[
                          IconButton(
                            tooltip: MaterialLocalizations.of(context)
                                .backButtonTooltip,
                            onPressed: onBackPressed ??
                                () => Navigator.maybePop(context),
                            style: BuildTripAppBar.toolbarIconStyle(scheme),
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                          const SizedBox(width: 10),
                        ] else if (showBrandIcon) ...[
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                'assets/images/app_icon.png',
                                width: 30,
                                height: 30,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ] else
                          const SizedBox(width: 8),
                        Expanded(
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: titleChild,
                          ),
                        ),
                        if (actions != null) ...actions!,
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CenteredTitleBar extends StatelessWidget {
  const _CenteredTitleBar({
    required this.scheme,
    required this.showBack,
    required this.showBrandIcon,
    required this.actions,
    required this.titleText,
    required this.titleChild,
    this.onBackPressed,
  });

  final ColorScheme scheme;
  final bool showBack;
  final bool showBrandIcon;
  final List<Widget>? actions;
  final String titleText;
  final Widget titleChild;
  final VoidCallback? onBackPressed;

  static const double _titleSidePadding = 52;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      alignment: Alignment.center,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (showBack) ...[
              IconButton(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: onBackPressed ?? () => Navigator.maybePop(context),
                style: BuildTripAppBar.toolbarIconStyle(scheme),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(width: 10),
            ] else if (showBrandIcon) ...[
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/app_icon.png',
                    width: 30,
                    height: 30,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ] else
              const SizedBox(width: 8),
            const Spacer(),
            if (actions != null) ...actions!,
          ],
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: _titleSidePadding),
            child: Semantics(
              header: true,
              label: titleText,
              child: DefaultTextStyle(
                style: DefaultTextStyle.of(context).style,
                textAlign: TextAlign.center,
                child: titleChild,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
