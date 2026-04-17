import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/mock_data.dart';
import '../data/trips_persistence.dart';
import '../l10n/app_localizations.dart';
import '../models/trip.dart';
import '../utils/trip_partition.dart';
import '../widgets/build_trip_app_bar.dart';
import 'trip_details_screen.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  final List<Trip> _trips = [...mockTrips];
  bool _upcomingExpanded = true;
  bool _archiveExpanded = true;

  @override
  void initState() {
    super.initState();
    _restoreTrips();
  }

  Future<void> _restoreTrips() async {
    final loaded = await TripsPersistence.loadTrips();
    if (!mounted) {
      return;
    }
    if (loaded != null) {
      setState(() {
        _trips
          ..clear()
          ..addAll(loaded);
      });
    } else {
      await TripsPersistence.saveTrips(_trips);
    }
  }

  void _replaceTrip(Trip updated) {
    setState(() {
      final i = _trips.indexWhere((t) => t.id == updated.id);
      if (i >= 0) {
        _trips[i] = updated;
      }
    });
    TripsPersistence.saveTrips(_trips);
  }

  Future<void> _persistTrips() => TripsPersistence.saveTrips(_trips);

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final dayStart = DateTime(today.year, today.month, today.day);
    final buckets = partitionTrips(_trips, today);

    return Scaffold(
      appBar: const BuildTripAppBar(
        titleText: 'BuildTrip',
        showBackButton: false,
        showBrandIcon: true,
      ),
      body: _trips.isEmpty
          ? Center(child: Text(context.l10n.t('tripsEmpty')))
          : ListView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
              children: [
                if (buckets.active.isNotEmpty) ...[
                  _TripSectionPanel(
                    title: context.l10n.t('sectionNow'),
                    subtitle: '',
                    icon: Icons.today,
                    tone: _SectionTone.upcoming,
                    trips: buckets.active,
                    cardVariant: _TripCardVariant.upcoming,
                    onTripUpdated: _replaceTrip,
                    dayProgressAnchor: dayStart,
                  ),
                  const SizedBox(height: 16),
                ],
                _TripSectionPanel(
                  title: context.l10n.t('sectionUpcoming'),
                  subtitle: context.l10n.t('sectionUpcomingSubtitle'),
                  icon: Icons.schedule_outlined,
                  tone: _SectionTone.upcoming,
                  trips: buckets.upcoming,
                  cardVariant: _TripCardVariant.upcoming,
                  onTripUpdated: _replaceTrip,
                  isCollapsible: true,
                  expanded: _upcomingExpanded,
                  onExpandedChanged: (v) =>
                      setState(() => _upcomingExpanded = v),
                ),
                const SizedBox(height: 16),
                _TripSectionPanel(
                  title: context.l10n.t('sectionArchive'),
                  subtitle: context.l10n.t('sectionArchiveSubtitle'),
                  icon: Icons.archive_outlined,
                  tone: _SectionTone.past,
                  trips: buckets.past,
                  cardVariant: _TripCardVariant.past,
                  onTripUpdated: _replaceTrip,
                  isCollapsible: true,
                  expanded: _archiveExpanded,
                  onExpandedChanged: (v) =>
                      setState(() => _archiveExpanded = v),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTripBottomSheet,
        tooltip: context.l10n.t('newTrip'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddTripBottomSheet() async {
    final createdTrip = await showModalBottomSheet<Trip>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const _AddTripSheet(),
    );
    if (createdTrip == null) {
      return;
    }

    setState(() => _trips.insert(0, createdTrip));
    await _persistTrips();
  }
}

enum _SectionTone { upcoming, past }

String? _dayProgressLabel(BuildContext context, Trip trip, DateTime day) {
  final start =
      DateTime(trip.startDate.year, trip.startDate.month, trip.startDate.day);
  final end = DateTime(trip.endDate.year, trip.endDate.month, trip.endDate.day);
  if (day.isBefore(start) || day.isAfter(end)) {
    return null;
  }
  final n = day.difference(start).inDays + 1;
  final total = end.difference(start).inDays + 1;
  return context.l10n.t(
    'dayOfTotal',
    params: {'day': '$n', 'total': '$total'},
  );
}

class _TripSectionPanel extends StatelessWidget {
  const _TripSectionPanel({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tone,
    required this.trips,
    required this.cardVariant,
    required this.onTripUpdated,
    this.dayProgressAnchor,
    this.isCollapsible = false,
    this.expanded = true,
    this.onExpandedChanged,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final _SectionTone tone;
  final List<Trip> trips;
  final _TripCardVariant cardVariant;
  final ValueChanged<Trip> onTripUpdated;

  /// Если задано, у карточек показывается чип «День N из M» (блок «Сейчас в поездке»).
  final DateTime? dayProgressAnchor;

  final bool isCollapsible;
  final bool expanded;
  final ValueChanged<bool>? onExpandedChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (Color bg, Color border) = switch (tone) {
      _SectionTone.upcoming => (
          scheme.surfaceContainerLow.withValues(alpha: 0.85),
          scheme.primary.withValues(alpha: 0.22),
        ),
      _SectionTone.past => (
          scheme.surfaceContainerHighest.withValues(alpha: 0.55),
          scheme.outline.withValues(alpha: 0.35),
        ),
    };

    final showBody = !isCollapsible || expanded;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: isCollapsible && onExpandedChanged != null
                  ? () => onExpandedChanged!(!expanded)
                  : null,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 22, color: scheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    if (isCollapsible)
                      Icon(
                        expanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        size: 26,
                        color: scheme.onSurfaceVariant,
                      ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOutCubic,
              alignment: Alignment.topCenter,
              child: showBody
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 4),
                        if (trips.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: Icon(
                                Icons.inbox_outlined,
                                size: 32,
                                color: scheme.outline,
                              ),
                            ),
                          )
                        else
                          ...trips.map(
                            (trip) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _TripCard(
                                trip: trip,
                                variant: cardVariant,
                                onTripUpdated: onTripUpdated,
                                dayProgressLabel: dayProgressAnchor != null
                                    ? _dayProgressLabel(
                                        context, trip, dayProgressAnchor!)
                                    : null,
                              ),
                            ),
                          ),
                      ],
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}

enum _TripCardVariant { upcoming, past }

class _TripCard extends StatelessWidget {
  const _TripCard({
    required this.trip,
    required this.variant,
    required this.onTripUpdated,
    this.dayProgressLabel,
  });

  final Trip trip;
  final _TripCardVariant variant;
  final ValueChanged<Trip> onTripUpdated;
  final String? dayProgressLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final days = trip.endDate.difference(trip.startDate).inDays + 1;

    final decoration = switch (variant) {
      _TripCardVariant.upcoming => BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: scheme.surface,
          border:
              Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        ),
      _TripCardVariant.past => BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: scheme.surface.withValues(alpha: 0.92),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.25)),
        ),
    };

    final titleStyle = variant == _TripCardVariant.past
        ? Theme.of(context).textTheme.titleMedium?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.88),
            )
        : Theme.of(context).textTheme.titleMedium;

    final bodyStyle = variant == _TripCardVariant.past
        ? Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            )
        : Theme.of(context).textTheme.bodyMedium;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final updated = await Navigator.of(context).push<Trip>(
            MaterialPageRoute<Trip>(
              builder: (_) => TripDetailsScreen(trip: trip),
            ),
          );
          if (updated != null && context.mounted) {
            onTripUpdated(updated);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: decoration,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text(trip.name, style: titleStyle)),
                    if (dayProgressLabel != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Chip(
                          label: Text(
                            dayProgressLabel!,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: scheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11.5,
                                  height: 1.1,
                                ),
                          ),
                          backgroundColor: scheme.primaryContainer,
                          side: BorderSide(
                            color:
                                scheme.primary.withValues(alpha: 0.45),
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          visualDensity:
                              const VisualDensity(horizontal: -2, vertical: -2),
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          labelPadding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${_formatDate(trip.startDate)} — ${_formatDate(trip.endDate)}',
                  style: bodyStyle,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.timelapse_outlined,
                      size: 16,
                      color: variant == _TripCardVariant.past
                          ? scheme.outline
                          : scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$days ${_dayWord(context, days)}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: variant == _TripCardVariant.past
                                ? scheme.onSurfaceVariant
                                : null,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final dayValue = date.day.toString().padLeft(2, '0');
    final monthValue = date.month.toString().padLeft(2, '0');
    return '$dayValue.$monthValue.${date.year}';
  }

  String _dayWord(BuildContext context, int d) {
    final l10n = context.l10n;
    if (d % 10 == 1 && d % 100 != 11) {
      return l10n.t('days_one');
    }
    if (d % 10 >= 2 && d % 10 <= 4 && (d % 100 < 12 || d % 100 > 14)) {
      return l10n.t('days_few');
    }
    return l10n.t('days_many');
  }
}

class _AddTripSheet extends StatefulWidget {
  const _AddTripSheet();

  @override
  State<_AddTripSheet> createState() => _AddTripSheetState();
}

class _AddTripSheetState extends State<_AddTripSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _destinationController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final formInputs = InputDecorationTheme(
      filled: true,
      fillColor: scheme.surface,
      floatingLabelAlignment: FloatingLabelAlignment.start,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.42)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.42)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary, width: 1.35),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.error.withValues(alpha: 0.85)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.error, width: 1.25),
      ),
    );

    final dateButtonStyle = OutlinedButton.styleFrom(
      foregroundColor: scheme.onSurface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.55)),
    );

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(inputDecorationTheme: formInputs),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.t('newTrip'),
                    style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(
                  l10n.t('newTripSubtitle'),
                  style: t.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: l10n.t('tripName')),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? l10n.t('enterTitle')
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _destinationController,
                  decoration: InputDecoration(
                    labelText: l10n.t('tripDestination'),
                    hintText: l10n.t('tripDestinationHint'),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? l10n.t('enterDestination')
                      : null,
                ),
                const SizedBox(height: 14),
                Text(l10n.t('dates'), style: t.labelLarge),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  style: dateButtonStyle,
                  onPressed: _pickDateRange,
                  icon: Icon(
                    Icons.calendar_month_outlined,
                    size: 20,
                    color: scheme.primary,
                  ),
                  label: Text(
                    _dateRangeLabel(context),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _QuickRangeChip(
                      label: context.l10n.t('quickRangeWeekend'),
                      onTap: () => _applyQuickRange(2),
                    ),
                    _QuickRangeChip(
                      label: context.l10n.t('quickRangeWeek'),
                      onTap: () => _applyQuickRange(7),
                    ),
                    _QuickRangeChip(
                      label: context.l10n.t('quickRangeTwoWeeks'),
                      onTap: () => _applyQuickRange(14),
                    ),
                  ],
                ),
                if (_startDate != null && _endDate != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.timelapse_outlined,
                          size: 18,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          context.l10n.t(
                            'tripDuration',
                            params: {'days': _tripDaysCount().toString()},
                          ),
                          style: t.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(l10n.t('addTrip')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final initialStart = _startDate ?? now;
    final initialEnd = _endDate ?? initialStart;
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      builder: (context, child) {
        final scheme = Theme.of(context).colorScheme;
        return Theme(
          data: Theme.of(context).copyWith(
            datePickerTheme: DatePickerThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              rangeSelectionBackgroundColor: scheme.primaryContainer,
              rangeSelectionOverlayColor:
                  WidgetStatePropertyAll(scheme.primary.withValues(alpha: 0.1)),
              dayShape: WidgetStatePropertyAll(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startDate = DateTime(
          picked.start.year,
          picked.start.month,
          picked.start.day,
        );
        _endDate = DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day,
        );
      });
    }
  }

  void _submit() {
    final l10n = context.l10n;
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid || _startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.t('fillAllFields'))),
      );
      return;
    }

    final start =
        DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
    final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
    final totalDays = end.difference(start).inDays + 1;
    final generatedDays = List<TripDay>.generate(totalDays, (index) {
      final currentDate = start.add(Duration(days: index));
      return TripDay(
        title: l10n.t('dayTitle', params: {'day': '${index + 1}'}),
        date: currentDate,
        description: l10n.t('dayTitle', params: {'day': '${index + 1}'}),
        items: const [],
      );
    });

    final trip = Trip(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      destination: _destinationController.text.trim(),
      startDate: start,
      endDate: end,
      days: generatedDays,
    );

    Navigator.of(context).pop(trip);
  }

  String _formatDate(DateTime date) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return DateFormat('dd.MM.yyyy', locale).format(date);
  }

  String _dateRangeLabel(BuildContext context) {
    if (_startDate == null || _endDate == null) {
      return context.l10n.t('pickTripDates');
    }
    return '${_formatDate(_startDate!)} — ${_formatDate(_endDate!)}';
  }

  int _tripDaysCount() {
    if (_startDate == null || _endDate == null) {
      return 0;
    }
    return _endDate!.difference(_startDate!).inDays + 1;
  }

  void _applyQuickRange(int days) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(Duration(days: days - 1));
    setState(() {
      _startDate = start;
      _endDate = end;
    });
  }
}

class _QuickRangeChip extends StatelessWidget {
  const _QuickRangeChip({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: const Icon(Icons.auto_awesome_outlined, size: 16),
      label: Text(label),
      onPressed: onTap,
    );
  }
}
