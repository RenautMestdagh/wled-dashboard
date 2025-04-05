import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

class ColorPicker extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<Color> onColorChangeEnd;
  final double size;

  const ColorPicker({
    Key? key,
    required this.initialColor,
    required this.onColorChanged,
    required this.onColorChangeEnd,
    this.size = 200,
  }) : super(key: key);

  @override
  _ColorPickerState createState() => _ColorPickerState();
}

class _ColorPickerState extends State<ColorPicker> {
  late Color _currentColor;

  @override
  void initState() {
    super.initState();
    _currentColor = widget.initialColor;
  }

  @override
  void didUpdateWidget(covariant ColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialColor != widget.initialColor) {
      setState(() {
        _currentColor = widget.initialColor;
      });
    }
  }

  void _updateColor(Color color) {
    setState(() {
      _currentColor = color;
    });
    widget.onColorChanged(color);
  }

  void _onInteractionEnd(Color color) {
    widget.onColorChangeEnd(color);
  }

  void _onInteractionStart(Offset localOffset, BuildContext context) {
    _handleCircularPan(localOffset, context);
  }

  void setColor(Color color) {
    setState(() {
      _currentColor = color;
    });
    widget.onColorChanged(color);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onPanStart: (details) => _onInteractionStart(details.localPosition, context),
          onPanUpdate: (details) => _handleCircularPan(details.localPosition, context),
          onPanEnd: (details) => _onInteractionEnd(_currentColor),
          onTapDown: (details) => _onInteractionStart(details.localPosition, context),
          onTapUp: (details) => _onInteractionEnd(_currentColor),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(51),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: CustomPaint(
              painter: _CircularColorPickerPainter(_currentColor),
            ),
          ),
        ),
      ],
    );
  }

  void _handleCircularPan(Offset localOffset, BuildContext context) {
    final double radius = widget.size / 2;
    final Offset center = Offset(radius, radius);
    final Offset position = localOffset - center;

    final double distance = position.distance;
    final double angle = -math.atan2(position.dy, -position.dx);
    double normalizedAngle = (angle + math.pi) % (2 * math.pi);

    // Convert to 0-360 range
    final double hue = (normalizedAngle / (2 * math.pi)) * 360;
    final double saturation = (distance / radius).clamp(0.0, 1.0);
    final double value = 1.0;

    final HSVColor hsvColor = HSVColor.fromAHSV(1.0, hue, saturation, value);
    _updateColor(hsvColor.toColor());
  }
}

class _CircularColorPickerPainter extends CustomPainter {
  final Color currentColor;

  _CircularColorPickerPainter(this.currentColor);

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);

    final Paint gradientPaint = Paint()
      ..shader = ui.Gradient.sweep(
        center,
        List.generate(360, (i) => HSVColor.fromAHSV(1, i.toDouble(), 1, 1).toColor()),
        List.generate(360, (i) => i / 359),
        TileMode.clamp,
      );

    final Paint whiteCenterPaint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        radius,
        [Colors.white, Colors.white.withAlpha(230), Colors.white.withAlpha(51), Colors.transparent],
        [0.0, 0.2, 0.75, 1.0],
      );

    canvas.drawCircle(center, radius, gradientPaint);
    canvas.drawCircle(center, radius, whiteCenterPaint);

    final HSVColor hsv = HSVColor.fromColor(currentColor);
    final double angle = (hsv.hue * math.pi / 180);
    final double distance = hsv.saturation * radius;

    final Offset cursorPosition = Offset(
      center.dx + distance * math.cos(angle),
      center.dy + distance * math.sin(angle),
    );

    final Paint outerCursorPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final Paint innerCursorPaint = Paint()
      ..color = currentColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(cursorPosition, 12, outerCursorPaint);
    canvas.drawCircle(cursorPosition, 10, innerCursorPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}