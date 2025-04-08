import 'package:flutter/material.dart';

class CCTSliderTrackShape extends RoundedRectSliderTrackShape {
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
        double additionalActiveTrackHeight = 0,
      }) {
    // Create a gradient from warm (amber) to cool (blue) for the CCT slider
    final LinearGradient gradient = LinearGradient(
      colors: const [
        Color(0xFFFFB74D), // Warm/amber color (2700K)
        Colors.white,      // Neutral (4000K)
        Color(0xFF90CAF9), // Cool/blue color (6500K)
      ],
    );

    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    // Background track
    final Paint backgroundTrackPaint = Paint()
      ..color = sliderTheme.disabledActiveTrackColor!
      ..style = PaintingStyle.fill;

    // Active track with gradient
    final Paint activeTrackPaint = Paint()
      ..shader = gradient.createShader(trackRect)
      ..style = PaintingStyle.fill;

    // Draw the tracks
    final Radius trackRadius = Radius.circular(trackRect.height / 2);
    final Rect activeTrackRect = Rect.fromLTRB(
      trackRect.left,
      trackRect.top,
      thumbCenter.dx,
      trackRect.bottom,
    );

    // Draw background track
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(trackRect, trackRadius),
      backgroundTrackPaint,
    );

    // Draw active track with gradient
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(activeTrackRect, trackRadius),
      activeTrackPaint,
    );
  }
}