import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/mock_data.dart';
import '../data/trips_persistence.dart';
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
          ? const Center(child: Text('Нет поездок. Добавьте первую!'))
          : ListView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 90),
              children: [
                if (buckets.active.isNotEmpty) ...[
                  _TripSectionPanel(
                    title: 'Сейчас в поездке',
                    subtitle: 'Поездки, в которые попадает сегодняшняя дата',
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
                  title: 'Предстоящие',
                  subtitle: 'Запланированные поездки',
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
                  title: 'Архив',
                  subtitle: 'Завершённые поездки',
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
        tooltip: 'Новая поездка',
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

String? _dayProgressLabel(Trip trip, DateTime day) {
  final start =
      DateTime(trip.startDate.year, trip.startDate.month, trip.startDate.day);
  final end = DateTime(trip.endDate.year, trip.endDate.month, trip.endDate.day);
  if (day.isBefore(start) || day.isAfter(end)) {
    return null;
  }
  final n = day.difference(start).inDays + 1;
  final total = end.difference(start).inDays + 1;
  return 'День $n из $total';
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
                        const SizedBox(height: 8),
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
                                        trip, dayProgressAnchor!)
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
                      '$days ${_dayWord(days)}',
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

  String _dayWord(int d) {
    if (d % 10 == 1 && d % 100 != 11) {
      return 'день';
    }
    if (d % 10 >= 2 && d % 10 <= 4 && (d % 100 < 12 || d % 100 > 14)) {
      return 'дня';
    }
    return 'дней';
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
    _destinationController.addListener(_onDestinationChanged);
  }

  void _onDestinationChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _destinationController.removeListener(_onDestinationChanged);
    _nameController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                Text('Новая поездка',
                    style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(
                  'Название, направление и даты',
                  style: t.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Название'),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Введите название'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _destinationController,
                  decoration: const InputDecoration(
                    labelText: 'Страна или город',
                    hintText: 'Например: Швейцария, Цюрих',
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Введите направление'
                      : null,
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: _destinationController.text.trim().isEmpty
                        ? null
                        : () => _openDestinationInMaps(
                            _destinationController.text.trim()),
                    icon: Icon(
                      Icons.map_outlined,
                      size: 20,
                      color: _destinationController.text.trim().isEmpty
                          ? scheme.onSurfaceVariant.withValues(alpha: 0.45)
                          : scheme.primary,
                    ),
                    label: Text(
                      'Открыть в картах',
                      style: TextStyle(
                        color: _destinationController.text.trim().isEmpty
                            ? scheme.onSurfaceVariant
                            : scheme.primary,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text('Даты', style: t.labelLarge),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: dateButtonStyle,
                        onPressed: _pickStartDate,
                        icon: Icon(Icons.calendar_today_outlined,
                            size: 20, color: scheme.primary),
                        label: Text(
                          _startDate == null
                              ? 'Начало'
                              : _formatDate(_startDate!),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: dateButtonStyle,
                        onPressed: _pickEndDate,
                        icon: Icon(Icons.event_outlined,
                            size: 20, color: scheme.primary),
                        label: Text(
                          _endDate == null ? 'Конец' : _formatDate(_endDate!),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ],
                ),
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
                    child: const Text('Добавить поездку'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openDestinationInMaps(String query) async {
    final encoded = Uri.encodeComponent(query);
    final mapUri =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$encoded');
    if (!await launchUrl(mapUri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось открыть карты')),
        );
      }
    }
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? now,
      firstDate: _startDate ?? DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  void _submit() {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid || _startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заполните все поля и выберите даты.')),
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
        title: 'День ${index + 1}',
        date: currentDate,
        description: 'План на день ${index + 1}.',
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
    final dayValue = date.day.toString().padLeft(2, '0');
    final monthValue = date.month.toString().padLeft(2, '0');
    return '$dayValue.$monthValue.${date.year}';
  }
}
