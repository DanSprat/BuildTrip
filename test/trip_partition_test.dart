import 'package:build_trip/models/trip.dart';
import 'package:build_trip/utils/trip_partition.dart';
import 'package:flutter_test/flutter_test.dart';

Trip _t(
  String id,
  DateTime start,
  DateTime end,
) {
  return Trip(
    id: id,
    name: id,
    destination: 'X',
    startDate: start,
    endDate: end,
    days: const [],
  );
}

void main() {
  group('partitionTrips', () {
    test('reference day inside range is active', () {
      final trips = [
        _t('a', DateTime(2026, 4, 1), DateTime(2026, 4, 30)),
        _t('b', DateTime(2026, 6, 1), DateTime(2026, 6, 10)),
      ];
      final b = partitionTrips(trips, DateTime(2026, 4, 9));
      expect(b.active.map((e) => e.id).toList(), ['a']);
      expect(b.upcoming.map((e) => e.id).toList(), ['b']);
      expect(b.past, isEmpty);
    });

    test('single-day trip active on that day', () {
      final trips = [_t('one', DateTime(2026, 5, 1), DateTime(2026, 5, 1))];
      final b = partitionTrips(trips, DateTime(2026, 5, 1));
      expect(b.active.length, 1);
      expect(b.upcoming, isEmpty);
      expect(b.past, isEmpty);
    });

    test('ended trip goes to past', () {
      final trips = [_t('old', DateTime(2025, 1, 1), DateTime(2025, 1, 5))];
      final b = partitionTrips(trips, DateTime(2026, 4, 9));
      expect(b.active, isEmpty);
      expect(b.upcoming, isEmpty);
      expect(b.past.length, 1);
    });

    test('future trip is upcoming only', () {
      final trips = [_t('f', DateTime(2026, 12, 1), DateTime(2026, 12, 7))];
      final b = partitionTrips(trips, DateTime(2026, 4, 9));
      expect(b.active, isEmpty);
      expect(b.upcoming.length, 1);
      expect(b.past, isEmpty);
    });

    test('active is sorted by start date', () {
      final trips = [
        _t('second', DateTime(2026, 4, 8), DateTime(2026, 4, 12)),
        _t('first', DateTime(2026, 4, 1), DateTime(2026, 4, 30)),
      ];
      final b = partitionTrips(trips, DateTime(2026, 4, 9));
      expect(b.active.map((e) => e.id).toList(), ['first', 'second']);
    });
  });
}
