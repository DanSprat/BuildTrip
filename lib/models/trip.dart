enum PlaceKind {
  attraction,
  hotel,
  arrivalPoint,
  food,
}

enum TransportMode {
  plane,
  car,
  train,
}

class PlaceAttachment {
  const PlaceAttachment({
    required this.path,
    this.displayLabel,
  });

  final String path;
  final String? displayLabel;

  String get label {
    final trimmed = displayLabel?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      return trimmed;
    }
    return _basename(path);
  }

  static String _basename(String p) {
    final normalized = p.replaceAll('\\', '/');
    if (!normalized.contains('/')) {
      return normalized;
    }
    return normalized.split('/').last;
  }

  PlaceAttachment copyWith({
    String? path,
    String? displayLabel,
  }) {
    return PlaceAttachment(
      path: path ?? this.path,
      displayLabel: displayLabel ?? this.displayLabel,
    );
  }
}

class Place {
  const Place({
    required this.name,
    required this.address,
    this.kind = PlaceKind.attraction,
    this.notes,
    this.attachments = const [],
    this.customLinks = const [],
  });

  final String name;
  final String address;
  final PlaceKind kind;
  final String? notes;
  final List<PlaceAttachment> attachments;
  final List<PlaceLink> customLinks;

  Place copyWith({
    String? name,
    String? address,
    PlaceKind? kind,
    String? notes,
    List<PlaceAttachment>? attachments,
    List<PlaceLink>? customLinks,
  }) {
    return Place(
      name: name ?? this.name,
      address: address ?? this.address,
      kind: kind ?? this.kind,
      notes: notes ?? this.notes,
      attachments: attachments ?? this.attachments,
      customLinks: customLinks ?? this.customLinks,
    );
  }

  String get stableKey => '${name}_$address';
}

class PlaceLink {
  const PlaceLink({
    required this.title,
    required this.url,
  });

  final String title;
  final String url;
}

sealed class DayItineraryItem {
  const DayItineraryItem();
}

class PlaceStop extends DayItineraryItem {
  const PlaceStop({
    required this.id,
    required this.place,
  });

  final String id;
  final Place place;
}

class TravelSegment extends DayItineraryItem {
  const TravelSegment({
    required this.id,
    this.mode = TransportMode.car,
    this.note,
    this.description,
    this.attachments = const [],
  });

  final String id;
  final TransportMode mode;
  final String? note;
  final String? description;
  final List<PlaceAttachment> attachments;

  TravelSegment copyWith({
    String? id,
    TransportMode? mode,
    String? note,
    String? description,
    List<PlaceAttachment>? attachments,
  }) {
    return TravelSegment(
      id: id ?? this.id,
      mode: mode ?? this.mode,
      note: note ?? this.note,
      description: description ?? this.description,
      attachments: attachments ?? this.attachments,
    );
  }
}

class TripDay {
  const TripDay({
    required this.title,
    required this.date,
    required this.description,
    required this.items,
  });

  final String title;
  final DateTime date;
  final String description;
  final List<DayItineraryItem> items;

  TripDay copyWith({
    String? title,
    DateTime? date,
    String? description,
    List<DayItineraryItem>? items,
  }) {
    return TripDay(
      title: title ?? this.title,
      date: date ?? this.date,
      description: description ?? this.description,
      items: items ?? this.items,
    );
  }
}

class Trip {
  const Trip({
    required this.id,
    required this.name,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.days,
  });

  final String id;
  final String name;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final List<TripDay> days;

  Trip copyWith({
    String? id,
    String? name,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    List<TripDay>? days,
  }) {
    return Trip(
      id: id ?? this.id,
      name: name ?? this.name,
      destination: destination ?? this.destination,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      days: days ?? this.days,
    );
  }
}

extension TripCalendarExtent on Trip {
  /// Поездка пересекает границу календарного месяца (по датам начала и конца).
  bool get spansMultipleCalendarMonths {
    return startDate.year != endDate.year || startDate.month != endDate.month;
  }
}
