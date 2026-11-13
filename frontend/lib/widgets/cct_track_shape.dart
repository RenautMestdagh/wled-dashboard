import 'package:material_ui/material_ui.dart';

/// A slider track running from warm to cold white, for the color temperature.
class CctTrackShape extends RoundedRectSliderTrackShape {
  const CctTrackShape();

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 2,
  }) {
    final rect = getPreferredRect(parentBox: parentBox, offset: offset, sliderTheme: sliderTheme);
    final gradient = const LinearGradient(colors: [Color(0xFFFFB74D), Colors.white, Color(0xFF90CAF9)]);
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(rect.height / 2)),
      Paint()..shader = gradient.createShader(rect),
    );
  }
}
