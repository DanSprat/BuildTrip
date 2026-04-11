import '../models/trip.dart';

/// Разбивает поездки на «сейчас в поездке», «предстоящие» и «завершённые».
/// [reference] — дата «сегодня» (обычно без времени).
class TripBuckets {
  const TripBuckets({
    required this.active,
    required this.upcoming,
    required this.past,
  });

  final List<Trip> active;
  final List<Trip> upcoming;
  final List<Trip> past;
}

TripBuckets partitionTrips(
  Iterable<Trip> trips,
  DateTime reference,
) {
  final dayStart = DateTime(reference.year, reference.month, reference.day);

  final active = <Trip>[];
  final upcoming = <Trip>[];
  final past = <Trip>[];

  for (final trip in trips) {
    final start =
        DateTime(trip.startDate.year, trip.startDate.month, trip.startDate.day);
    final end =
        DateTime(trip.endDate.year, trip.endDate.month, trip.endDate.day);

    final inRange = !dayStart.isBefore(start) && !dayStart.isAfter(end);
    if (inRange) {
      active.add(trip);
    } else if (start.isAfter(dayStart)) {
      upcoming.add(trip);
    } else if (end.isBefore(dayStart)) {
      past.add(trip);
    }
  }

  active.sort((a, b) => a.startDate.compareTo(b.startDate));
  upcoming.sort((a, b) => a.startDate.compareTo(b.startDate));
  past.sort((a, b) => b.startDate.compareTo(a.startDate));

  return TripBuckets(active: active, upcoming: upcoming, past: past);
}
