import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/trip.dart';
import '../utils/day_title_localization.dart';
import '../widgets/build_trip_app_bar.dart';
import 'day_details_screen.dart';

class TripDetailsScreen extends StatefulWidget {
  const TripDetailsScreen({
    super.key,
    required this.trip,
  });

  final Trip trip;

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  late Trip _trip;

  @override
  void initState() {
    super.initState();
    _trip = widget.trip;
  }

  void _popWithTrip() {
    Navigator.of(context).pop(_trip);
  }

  Future<void> _openDay(int index) async {
    final updated = await Navigator.of(context).push<Trip>(
      MaterialPageRoute<Trip>(
        builder: (_) => DayDetailsScreen(
          trip: _trip,
          initialDayIndex: index,
        ),
      ),
    );
    if (updated != null && mounted) {
      setState(() => _trip = updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _popWithTrip();
        }
      },
      child: Scaffold(
        appBar: BuildTripAppBar(
          titleText: _trip.name,
          onBackPressed: _popWithTrip,
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TripHeroSummary(trip: _trip),
              const SizedBox(height: 14),
              Expanded(
                child: _trip.days.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            context.l10n.t('tripNoDays'),
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ),
                      )
                    : ListView(
                        padding: EdgeInsets.zero,
                        children: _dayListTiles(
                          context,
                          _trip,
                          DateTime.now(),
                          _openDay,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

bool _isSameCalendarDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

List<Widget> _dayListTiles(
  BuildContext context,
  Trip trip,
  DateTime now,
  Future<void> Function(int index) onOpenDay,
) {
  final today = DateTime(now.year, now.month, now.day);
  final out = <Widget>[];
  for (var i = 0; i < trip.days.length; i++) {
    final day = trip.days[i];
    final d = DateTime(day.date.year, day.date.month, day.date.day);
    out.add(
      _DayRowTile(
        day: day,
        isToday: _isSameCalendarDay(today, d),
        onTap: () => onOpenDay(i),
      ),
    );
    if (i < trip.days.length - 1) {
      out.add(const SizedBox(height: 8));
    }
  }
  return out;
}

class _TripHeroSummary extends StatelessWidget {
  const _TripHeroSummary({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final outline = scheme.outlineVariant.withValues(alpha: 0.42);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: outline),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.flight_takeoff_rounded,
            size: 28,
            color: scheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip.destination,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${_formatTripDate(trip.startDate)} — ${_formatTripDate(trip.endDate)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTripDate(DateTime date) {
    final dayValue = date.day.toString().padLeft(2, '0');
    final monthValue = date.month.toString().padLeft(2, '0');
    return '$dayValue.$monthValue.${date.year}';
  }
}

class _DayRowTile extends StatelessWidget {
  const _DayRowTile({
    required this.day,
    required this.onTap,
    this.isToday = false,
  });

  final TripDay day;
  final VoidCallback onTap;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final resolvedDayTitle = localizeDayTitleIfAuto(context, day.title);
    final scheme = Theme.of(context).colorScheme;
    final outline = isToday
        ? scheme.primary.withValues(alpha: 0.42)
        : scheme.outlineVariant.withValues(alpha: 0.35);
    final fill = isToday
        ? scheme.primaryContainer.withValues(alpha: 0.62)
        : scheme.surfaceContainerHighest.withValues(alpha: 0.55);
    final accent =
        isToday ? scheme.primary : scheme.primary.withValues(alpha: 0.72);
    final monthColor = isToday
        ? scheme.onPrimaryContainer.withValues(alpha: 0.85)
        : scheme.onSurfaceVariant;

    return Material(
      color: fill,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: outline, width: isToday ? 1.2 : 1),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 4,
              child: ColoredBox(color: accent),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 44,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          day.date.day.toString().padLeft(2, '0'),
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: scheme.primary,
                                    height: 1.15,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _monthShortLocalized(context, day.date),
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: monthColor,
                                    fontWeight: FontWeight.w600,
                                    height: 1.1,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text.rich(
                          TextSpan(
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  height: 1.2,
                                ),
                            children: [
                              TextSpan(text: resolvedDayTitle),
                              if (isToday) ...[
                                TextSpan(
                                  text: ' · ',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        color: scheme.onSurfaceVariant,
                                        height: 1.2,
                                      ),
                                ),
                                TextSpan(
                                  text: context.l10n.t('today'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        color: scheme.primary,
                                        fontWeight: FontWeight.w800,
                                        height: 1.2,
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          day.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    height: 1.35,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Короткое название месяца для строки дня.
String _monthShortLocalized(BuildContext context, DateTime d) {
  final localeTag = Localizations.localeOf(context).toLanguageTag();
  return DateFormat('MMM', localeTag).format(d);
}
