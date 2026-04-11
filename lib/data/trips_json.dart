import 'dart:convert';

import '../models/trip.dart';

/// Сериализация списка поездок в JSON (локальное хранилище).
abstract final class TripsJson {
  static String encodeList(List<Trip> trips) {
    return jsonEncode(trips.map(_tripToMap).toList());
  }

  static List<Trip> decodeList(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! List<dynamic>) {
      throw const FormatException('Ожидался JSON-массив поездок');
    }
    return decoded.map((e) => _tripFromMap(e as Map<String, dynamic>)).toList();
  }

  static Map<String, dynamic> _tripToMap(Trip t) {
    return {
      'id': t.id,
      'name': t.name,
      'destination': t.destination,
      'startDate': t.startDate.toIso8601String(),
      'endDate': t.endDate.toIso8601String(),
      'days': t.days.map(_dayToMap).toList(),
    };
  }

  static Trip _tripFromMap(Map<String, dynamic> m) {
    return Trip(
      id: m['id'] as String,
      name: m['name'] as String,
      destination: m['destination'] as String,
      startDate: DateTime.parse(m['startDate'] as String),
      endDate: DateTime.parse(m['endDate'] as String),
      days: (m['days'] as List<dynamic>)
          .map((e) => _dayFromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static Map<String, dynamic> _dayToMap(TripDay d) {
    return {
      'title': d.title,
      'date': d.date.toIso8601String(),
      'description': d.description,
      'items': d.items.map(_itemToMap).toList(),
    };
  }

  static TripDay _dayFromMap(Map<String, dynamic> m) {
    return TripDay(
      title: m['title'] as String,
      date: DateTime.parse(m['date'] as String),
      description: m['description'] as String,
      items: (m['items'] as List<dynamic>)
          .map((e) => _itemFromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static Map<String, dynamic> _itemToMap(DayItineraryItem item) {
    switch (item) {
      case PlaceStop(:final id, :final place):
        return {
          'kind': 'placeStop',
          'id': id,
          'place': _placeToMap(place),
        };
      case TravelSegment(
          :final id,
          :final mode,
          :final note,
          :final description,
          :final attachments
        ):
        return {
          'kind': 'travelSegment',
          'id': id,
          'mode': mode.name,
          'note': note,
          'description': description,
          'attachments': attachments.map(_attachmentToMap).toList(),
        };
    }
  }

  static DayItineraryItem _itemFromMap(Map<String, dynamic> m) {
    final kind = m['kind'] as String;
    switch (kind) {
      case 'placeStop':
        return PlaceStop(
          id: m['id'] as String,
          place: _placeFromMap(m['place'] as Map<String, dynamic>),
        );
      case 'travelSegment':
        return TravelSegment(
          id: m['id'] as String,
          mode: _transportModeFrom(m['mode'] as String),
          note: m['note'] as String?,
          description: m['description'] as String?,
          attachments: (m['attachments'] as List<dynamic>? ?? [])
              .map((e) => _attachmentFromMap(e as Map<String, dynamic>))
              .toList(),
        );
      default:
        throw FormatException('Неизвестный kind элемента дня: $kind');
    }
  }

  static Map<String, dynamic> _placeToMap(Place p) {
    return {
      'name': p.name,
      'address': p.address,
      'kind': p.kind.name,
      'notes': p.notes,
      'attachments': p.attachments.map(_attachmentToMap).toList(),
      'customLinks': p.customLinks
          .map((l) => {
                'title': l.title,
                'url': l.url,
              })
          .toList(),
    };
  }

  static Place _placeFromMap(Map<String, dynamic> m) {
    return Place(
      name: m['name'] as String,
      address: m['address'] as String? ?? '',
      kind: _placeKindFrom(m['kind'] as String?),
      notes: m['notes'] as String?,
      attachments: (m['attachments'] as List<dynamic>? ?? [])
          .map((e) => _attachmentFromMap(e as Map<String, dynamic>))
          .toList(),
      customLinks: (m['customLinks'] as List<dynamic>? ?? []).map((e) {
        final lm = e as Map<String, dynamic>;
        return PlaceLink(
          title: lm['title'] as String,
          url: lm['url'] as String,
        );
      }).toList(),
    );
  }

  static PlaceKind _placeKindFrom(String? raw) {
    if (raw == null) {
      return PlaceKind.attraction;
    }
    for (final v in PlaceKind.values) {
      if (v.name == raw) {
        return v;
      }
    }
    return PlaceKind.attraction;
  }

  static TransportMode _transportModeFrom(String raw) {
    for (final v in TransportMode.values) {
      if (v.name == raw) {
        return v;
      }
    }
    return TransportMode.car;
  }

  static Map<String, dynamic> _attachmentToMap(PlaceAttachment a) {
    return {
      'path': a.path,
      if (a.displayLabel != null) 'displayLabel': a.displayLabel,
    };
  }

  static PlaceAttachment _attachmentFromMap(Map<String, dynamic> m) {
    return PlaceAttachment(
      path: m['path'] as String,
      displayLabel: m['displayLabel'] as String?,
    );
  }
}
