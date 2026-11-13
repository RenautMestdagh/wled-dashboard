import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

/// A hue (angle) and saturation (distance from the center) wheel, always at full brightness.
class ColorWheel extends StatefulWidget {
  const ColorWheel({super.key, required this.label, required this.color, required this.onChangeEnd, this.size = 220});

  final String label;
  final Color color;
  final ValueChanged<Color> onChangeEnd;
  final double size;

  @override
  State<ColorWheel> createState() => _ColorWheelState();
}

class _ColorWheelState extends State<ColorWheel> {
  late HSVColor _color = _fullValue(widget.color);

  static HSVColor _fullValue(Color color) => HSVColor.fromColor(color).withValue(1);

  @override
  void didUpdateWidget(ColorWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.color != widget.color) _color = _fullValue(widget.color);
  }

  void _pick(Offset position) {
    final radius = widget.size / 2;
    final offset = position - Offset(radius, radius);
    final hue = (math.atan2(offset.dy, offset.dx) * 180 / math.pi + 360) % 360;
    setState(() => _color = HSVColor.fromAHSV(1, hue, (offset.distance / radius).clamp(0, 1), 1));
  }

  void _end() => widget.onChangeEnd(_color.toColor());

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.label,
      child: GestureDetector(
        onPanStart: (details) => _pick(details.localPosition),
        onPanUpdate: (details) => _pick(details.localPosition),
        onPanEnd: (_) => _end(),
        onTapUp: (details) {
          _pick(details.localPosition);
          _end();
        },
        child: CustomPaint(size: Size.square(widget.size), painter: _WheelPainter(_color)),
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  _WheelPainter(this.color);

  final HSVColor color;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 2;
    final center = Offset(radius, radius);

    canvas
      ..drawCircle(
        center,
        radius,
        Paint()
          ..shader = ui.Gradient.sweep(
            center,
            [for (var hue = 0; hue <= 360; hue += 60) HSVColor.fromAHSV(1, hue % 360, 1, 1).toColor()],
            [for (var stop = 0; stop <= 6; stop++) stop / 6],
          ),
      )
      ..drawCircle(
        center,
        radius,
        Paint()..shader = ui.Gradient.radial(center, radius, [Colors.white, Colors.white.withAlpha(0)]),
      );

    final angle = color.hue * math.pi / 180;
    final marker = center + Offset(math.cos(angle), math.sin(angle)) * color.saturation * radius;
    canvas
      ..drawCircle(marker, 12, Paint()..color = color.toColor())
      ..drawCircle(
        marker,
        12,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
  }

  @override
  bool shouldRepaint(_WheelPainter oldDelegate) => oldDelegate.color != color;
}
