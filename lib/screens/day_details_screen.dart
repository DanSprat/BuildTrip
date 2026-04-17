import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/trip.dart';
import '../utils/day_title_localization.dart';
import '../widgets/build_trip_app_bar.dart';
import '../widgets/itinerary_widgets.dart';
import 'place_details_screen.dart';
import 'travel_segment_details_screen.dart';

class DayDetailsScreen extends StatefulWidget {
  const DayDetailsScreen({
    super.key,
    required this.trip,
    required this.initialDayIndex,
  });

  final Trip trip;
  final int initialDayIndex;

  @override
  State<DayDetailsScreen> createState() => _DayDetailsScreenState();
}

class _DayDetailsScreenState extends State<DayDetailsScreen> {
  late final List<TripDay> _days;
  late int _selectedDayIndex;
  final GlobalKey _routeListBoundaryKey = GlobalKey();

  TripDay get _selectedDay => _days[_selectedDayIndex];

  Trip _tripWithCurrentDays() {
    return widget.trip.copyWith(days: List<TripDay>.from(_days));
  }

  void _popWithUpdatedTrip() {
    Navigator.of(context).pop(_tripWithCurrentDays());
  }

  @override
  void initState() {
    super.initState();
    _days = [...widget.trip.days];
    if (_days.isEmpty) {
      _selectedDayIndex = 0;
    } else {
      _selectedDayIndex = widget.initialDayIndex.clamp(0, _days.length - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_days.isEmpty) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            _popWithUpdatedTrip();
          }
        },
        child: Scaffold(
          appBar: BuildTripAppBar(
            titleText: context.l10n.t('dayLabel'),
            onBackPressed: _popWithUpdatedTrip,
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                context.l10n.t('dayListCorrupted'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
              ),
            ),
          ),
        ),
      );
    }

    final items = _selectedDay.items;
    final resolvedSelectedDayTitle =
        localizeDayTitleIfAuto(context, _selectedDay.title);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _popWithUpdatedTrip();
        }
      },
      child: Scaffold(
        appBar: BuildTripAppBar(
          titleText: resolvedSelectedDayTitle,
          centerTitle: true,
          titleWidget: _DayAppBarTitle(title: resolvedSelectedDayTitle),
          onBackPressed: _popWithUpdatedTrip,
          actions: [
            IconButton(
              tooltip: context.l10n.t('addToItinerary'),
              onPressed: _showAddItinerarySheet,
              style: BuildTripAppBar.toolbarIconStyle(
                  Theme.of(context).colorScheme),
              icon: const Icon(Icons.add_rounded),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DayStrip(
                trip: widget.trip,
                days: _days,
                selectedIndex: _selectedDayIndex,
                onSelect: (i) => setState(() => _selectedDayIndex = i),
                weekdayShort: _weekdayShort,
              ),
              const SizedBox(height: 12),
              _DayContextBanner(
                trip: widget.trip,
                day: _selectedDay,
              ),
              const SizedBox(height: 16),
              _RouteSectionHeading(scheme: Theme.of(context).colorScheme),
              const SizedBox(height: 10),
              Expanded(
                child: Container(
                  key: _routeListBoundaryKey,
                  child: items.isEmpty
                      ? Center(
                          child: Tooltip(
                            message: context.l10n.t('addToItinerary'),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _showAddItinerarySheet,
                                borderRadius: BorderRadius.circular(32),
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Icon(
                                    Icons.add_road,
                                    size: 40,
                                    color:
                                        Theme.of(context).colorScheme.outline,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      : ReorderableListView.builder(
                          itemCount: items.length,
                          onReorder: _onReorderItems,
                          buildDefaultDragHandles: false,
                          dragBoundaryProvider: (context) {
                            final boundaryContext =
                                _routeListBoundaryKey.currentContext;
                            if (boundaryContext != null) {
                              return DragBoundary.forRectOf(boundaryContext);
                            }
                            return DragBoundary.forRectOf(context);
                          },
                          proxyDecorator: (child, index, animation) {
                            final curved = CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                              reverseCurve: Curves.easeInCubic,
                            );
                            return AnimatedBuilder(
                              animation: curved,
                              builder: (context, _) {
                                final t = curved.value;
                                final scheme = Theme.of(context).colorScheme;
                                // Слабый «подъём»: почти без увеличения и с низкой тенью
                                return Transform.scale(
                                  scale: 1.0 + 0.008 * t,
                                  alignment: Alignment.center,
                                  child: Material(
                                    elevation: 1.5 + 2.5 * t,
                                    shadowColor: scheme.shadow
                                        .withValues(alpha: 0.22 * t),
                                    borderRadius: BorderRadius.circular(16),
                                    clipBehavior: Clip.antiAlias,
                                    color: Colors.transparent,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: scheme.primary.withValues(
                                              alpha: 0.35 + 0.2 * t),
                                          width: 1.2 + 0.25 * t,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: scheme.primary
                                                .withValues(alpha: 0.06 * t),
                                            blurRadius: 6 * t,
                                            spreadRadius: 0,
                                            offset: Offset(0, 1 * t),
                                          ),
                                        ],
                                      ),
                                      child: child,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          itemBuilder: (context, index) {
                            final item = items[index];
                            if (item is PlaceStop) {
                              return _buildPlaceRow(
                                context,
                                key: ValueKey('ps_${item.id}'),
                                index: index,
                                stop: item,
                              );
                            }
                            if (item is TravelSegment) {
                              return _buildTravelRow(
                                context,
                                key: ValueKey('ts_${item.id}'),
                                index: index,
                                segment: item,
                              );
                            }
                            throw StateError('Unknown itinerary item');
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceRow(
    BuildContext context, {
    required Key key,
    required int index,
    required PlaceStop stop,
  }) {
    final place = stop.place;
    final visual = PlaceKindVisual.of(context, place.kind);

    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 6),
      child: ReorderableDelayedDragStartListener(
        index: index,
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: visual.border(context), width: 1.2),
          ),
          color: visual.fill(context),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            minVerticalPadding: 0,
            titleAlignment: ListTileTitleAlignment.center,
            leading: SizedBox(
              width: 36,
              height: 36,
              child: Center(
                child: Icon(
                  visual.icon,
                  color: visual.accent,
                ),
              ),
            ),
            title: Text(place.name),
            subtitle: Text(_placeListSubtitle(place)),
            isThreeLine: _placeListSubtitleIsThreeLine(place),
            onTap: () => _openPlaceDetails(index, place),
          ),
        ),
      ),
    );
  }

  Widget _buildTravelRow(
    BuildContext context, {
    required Key key,
    required int index,
    required TravelSegment segment,
  }) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 4),
      child: ReorderableDelayedDragStartListener(
        index: index,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openTravelDetails(index, segment),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              child: TravelRoadStrip(
                mode: segment.mode,
                note: segment.note,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddItinerarySheet() {
    final scheme = Theme.of(context).colorScheme;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: scheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final t = Theme.of(sheetContext).textTheme;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            4,
            20,
            20 + MediaQuery.paddingOf(sheetContext).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.l10n.t('addToItinerary'),
                textAlign: TextAlign.center,
                style: t.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.l10n.t('chooseDayItemType'),
                textAlign: TextAlign.center,
                style: t.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _AddItineraryOptionCard(
                        icon: Icons.place_outlined,
                        title: context.l10n.t('destinationPoint'),
                        subtitle: context.l10n.t('destinationPointSubtitle'),
                        accent: scheme.primary,
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _addPlaceStopAndEdit();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _AddItineraryOptionCard(
                        icon: Icons.alt_route_rounded,
                        title: context.l10n.t('travelSegment'),
                        subtitle: context.l10n.t('travelSegmentSubtitle'),
                        accent: scheme.tertiary,
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _addTravelSegmentAndEdit();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addPlaceStopAndEdit() async {
    final id = 'ps_${DateTime.now().microsecondsSinceEpoch}';
    final newPlace = Place(
      name: context.l10n.t('newPoint'),
      address: '',
      kind: PlaceKind.attraction,
    );
    late int newIndex;
    setState(() {
      final list = [..._selectedDay.items];
      newIndex = list.length;
      list.add(PlaceStop(id: id, place: newPlace));
      _days[_selectedDayIndex] = _selectedDay.copyWith(items: list);
    });
    if (!mounted) {
      return;
    }
    await _openPlaceDetails(newIndex, newPlace);
  }

  Future<void> _openPlaceDetails(int index, Place place) async {
    final result = await Navigator.of(context).push<Object?>(
      MaterialPageRoute<Object?>(
        builder: (_) => PlaceDetailsScreen(place: place),
      ),
    );
    if (!mounted) {
      return;
    }
    if (identical(result, PlaceDetailsScreen.deleteMarker)) {
      setState(() {
        final list = [..._selectedDay.items];
        if (index < list.length) {
          list.removeAt(index);
          _days[_selectedDayIndex] = _selectedDay.copyWith(items: list);
        }
      });
      return;
    }
    if (result is Place) {
      _updatePlaceStop(index, result);
    }
  }

  Future<void> _addTravelSegmentAndEdit() async {
    final id = 'ts_${DateTime.now().microsecondsSinceEpoch}';
    final segment = TravelSegment(
      id: id,
      mode: TransportMode.train,
    );
    late int newIndex;
    setState(() {
      final list = [..._selectedDay.items];
      newIndex = list.length;
      list.add(segment);
      _days[_selectedDayIndex] = _selectedDay.copyWith(items: list);
    });
    await _openTravelDetails(newIndex, segment);
  }

  Future<void> _openTravelDetails(int index, TravelSegment segment) async {
    final result = await Navigator.of(context).push<Object?>(
      MaterialPageRoute<Object?>(
        builder: (_) => TravelSegmentDetailsScreen(segment: segment),
      ),
    );
    if (!mounted) {
      return;
    }
    if (identical(result, TravelSegmentDetailsScreen.deleteMarker)) {
      setState(() {
        final list = [..._selectedDay.items];
        list.removeAt(index);
        _days[_selectedDayIndex] = _selectedDay.copyWith(items: list);
      });
      return;
    }
    if (result is TravelSegment) {
      setState(() {
        final list = [..._selectedDay.items];
        list[index] = result;
        _days[_selectedDayIndex] = _selectedDay.copyWith(items: list);
      });
    }
  }

  void _onReorderItems(int oldIndex, int newIndex) {
    setState(() {
      final list = [..._selectedDay.items];
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = list.removeAt(oldIndex);
      list.insert(newIndex, item);
      _days[_selectedDayIndex] = _selectedDay.copyWith(items: list);
    });
  }

  void _updatePlaceStop(int index, Place updatedPlace) {
    setState(() {
      final list = [..._selectedDay.items];
      final existing = list[index];
      if (existing is! PlaceStop) {
        return;
      }
      list[index] = PlaceStop(id: existing.id, place: updatedPlace);
      _days[_selectedDayIndex] = _selectedDay.copyWith(items: list);
    });
  }

  String _placeListSubtitle(Place place) {
    final addr = place.address.trim();
    final rawNotes = place.notes?.trim();
    final hasNotes = rawNotes != null && rawNotes.isNotEmpty;
    if (hasNotes && addr.isNotEmpty) {
      return '$addr\n$rawNotes';
    }
    if (hasNotes) {
      return rawNotes;
    }
    if (addr.isNotEmpty) {
      return addr;
    }
    return context.l10n.t('addressNotProvided');
  }

  static bool _placeListSubtitleIsThreeLine(Place place) {
    final addr = place.address.trim();
    final rawNotes = place.notes?.trim();
    final hasNotes = rawNotes != null && rawNotes.isNotEmpty;
    return hasNotes && addr.isNotEmpty;
  }

  String _weekdayShort(DateTime date) {
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    return DateFormat('E', localeTag).format(date);
  }
}

/// Заголовок экрана дня: для «День N» — акцент на номере в «капсуле».
class _DayAppBarTitle extends StatelessWidget {
  const _DayAppBarTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final baseStyle = t.titleLarge?.copyWith(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      height: 1.15,
      letterSpacing: -0.55,
      color: Color.lerp(scheme.onSurface, scheme.primary, 0.08),
    );

    return Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: baseStyle,
    );
  }
}

/// Короткое имя месяца для компактных чипов дней (как на экране поездки).
String _monthShortLocalized(BuildContext context, DateTime d) {
  final localeTag = Localizations.localeOf(context).toLanguageTag();
  return DateFormat('MMM', localeTag).format(d);
}

class _AddItineraryOptionCard extends StatelessWidget {
  const _AddItineraryOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Material(
      color: scheme.surface,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: accent.withValues(alpha: 0.28),
          width: 1.2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: accent.withValues(alpha: 0.12),
        highlightColor: accent.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent, size: 26),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: t.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: t.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.25,
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

class _DayStrip extends StatelessWidget {
  const _DayStrip({
    required this.trip,
    required this.days,
    required this.selectedIndex,
    required this.onSelect,
    required this.weekdayShort,
  });

  final Trip trip;
  final List<TripDay> days;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final String Function(DateTime) weekdayShort;

  static const double _stripInnerHeight = 42;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.42),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      child: SizedBox(
        height: _stripInnerHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: days.length,
          separatorBuilder: (context, index) {
            if (!trip.spansMultipleCalendarMonths) {
              return const SizedBox(width: 4);
            }
            final left = days[index].date;
            final right = days[index + 1].date;
            if (left.year == right.year && left.month == right.month) {
              return const SizedBox(width: 4);
            }
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Center(
                child: Container(
                  width: 1,
                  height: 26,
                  decoration: BoxDecoration(
                    color: scheme.outline.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            );
          },
          itemBuilder: (context, index) {
            final day = days[index];
            final isActive = index == selectedIndex;
            return GestureDetector(
              onTap: () => onSelect(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                constraints: const BoxConstraints(minWidth: 48),
                decoration: BoxDecoration(
                  color: isActive
                      ? scheme.primary.withValues(alpha: 0.14)
                      : scheme.surface.withValues(alpha: 0.97),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isActive
                        ? scheme.primary
                        : scheme.outlineVariant.withValues(alpha: 0.5),
                    width: isActive ? 1.5 : 1,
                  ),
                  boxShadow: isActive
                      ? const [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      weekdayShort(day.date),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.1,
                            height: 1.0,
                            color: isActive
                                ? scheme.primary
                                : scheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${day.date.day.toString().padLeft(2, '0')} ${_monthShortLocalized(context, day.date)}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            height: 1.05,
                            color: isActive ? scheme.primary : scheme.onSurface,
                          ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DayContextBanner extends StatelessWidget {
  const _DayContextBanner({
    required this.trip,
    required this.day,
  });

  final Trip trip;
  final TripDay day;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final borderColor = scheme.outlineVariant.withValues(alpha: 0.38);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
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
          DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.place_outlined,
                size: 22,
                color: scheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip.destination,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.15,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatBannerDate(day.date),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  day.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatBannerDate(DateTime date) {
    final dayValue = date.day.toString().padLeft(2, '0');
    final monthValue = date.month.toString().padLeft(2, '0');
    return '$dayValue.$monthValue.${date.year}';
  }
}

class _RouteSectionHeading extends StatelessWidget {
  const _RouteSectionHeading({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Icon(Icons.map_outlined, size: 20, color: scheme.primary),
              const SizedBox(width: 8),
              Text(
                context.l10n.t('route'),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
        Divider(
          height: 1,
          thickness: 1,
          color: scheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ],
    );
  }
}
