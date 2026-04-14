import 'package:flutter/material.dart';

import '../models/trip.dart';

class PlaceKindVisual {
  const PlaceKindVisual({
    required this.icon,
    required this.accent,
  });

  final IconData icon;
  final Color accent;

  static PlaceKindVisual of(BuildContext context, PlaceKind kind) {
    final scheme = Theme.of(context).colorScheme;
    return switch (kind) {
      PlaceKind.attraction => PlaceKindVisual(
          icon: Icons.attractions_outlined,
          accent: scheme.tertiary,
        ),
      PlaceKind.hotel => PlaceKindVisual(
          icon: Icons.hotel_class_outlined,
          accent: scheme.secondary,
        ),
      PlaceKind.arrivalPoint => PlaceKindVisual(
          icon: Icons.flight_land_outlined,
          accent: scheme.primary,
        ),
      PlaceKind.food => PlaceKindVisual(
          icon: Icons.restaurant_outlined,
          accent: Color.lerp(scheme.secondary, scheme.error, 0.35) ??
              scheme.secondary,
        ),
    };
  }

  /// Подписи для списков и форм (RU).
  static String labelRu(PlaceKind kind) {
    return switch (kind) {
      PlaceKind.attraction => 'Достопримечательность',
      PlaceKind.hotel => 'Отель',
      PlaceKind.arrivalPoint => 'Пункт прибытия',
      PlaceKind.food => 'Место для еды',
    };
  }

  /// Удобный порядок в селекторах типа места.
  static const List<PlaceKind> pickerOrder = [
    PlaceKind.attraction,
    PlaceKind.arrivalPoint,
    PlaceKind.hotel,
    PlaceKind.food,
  ];

  Color fill(BuildContext context) => accent.withValues(alpha: 0.08);

  Color border(BuildContext context) => accent.withValues(alpha: 0.42);
}

class TransportVisual {
  const TransportVisual({
    required this.icon,
    required this.accent,
  });

  final IconData icon;
  final Color accent;

  static TransportVisual of(BuildContext context, TransportMode mode) {
    final scheme = Theme.of(context).colorScheme;
    return switch (mode) {
      TransportMode.plane => TransportVisual(
          icon: Icons.flight_outlined,
          accent: scheme.primary,
        ),
      TransportMode.car => TransportVisual(
          icon: Icons.directions_car_outlined,
          accent: scheme.tertiary,
        ),
      TransportMode.train => TransportVisual(
          icon: Icons.train_outlined,
          accent: scheme.secondary,
        ),
    };
  }

  static String label(TransportMode mode) {
    return switch (mode) {
      TransportMode.plane => 'Самолёт',
      TransportMode.car => 'Авто',
      TransportMode.train => 'Поезд',
    };
  }

  /// Порядок в селекторах типа транспорта.
  static const List<TransportMode> pickerOrder = [
    TransportMode.plane,
    TransportMode.car,
    TransportMode.train,
  ];
}

class TravelRoadStrip extends StatelessWidget {
  const TravelRoadStrip({
    super.key,
    required this.mode,
    this.note,
  });

  final TransportMode mode;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final transport = TransportVisual.of(context, mode);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: transport.accent.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: transport.accent.withValues(alpha: 0.35)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            children: [
              SizedBox(
                height: 28,
                child: Row(
                  children: [
                    Expanded(
                      child: CustomPaint(
                        painter: _RoadDashPainter(
                          color: transport.accent.withValues(alpha: 0.45),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        transport.icon,
                        size: 22,
                        color: transport.accent,
                      ),
                    ),
                    Expanded(
                      child: CustomPaint(
                        painter: _RoadDashPainter(
                          color: transport.accent.withValues(alpha: 0.45),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (note != null && note!.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    note!.trim(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
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

class _RoadDashPainter extends CustomPainter {
  _RoadDashPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dash = 6.0;
    const gap = 5.0;
    final y = size.height / 2;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(
          Offset(x, y), Offset((x + dash).clamp(0, size.width), y), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _RoadDashPainter oldDelegate) =>
      oldDelegate.color != color;
}
