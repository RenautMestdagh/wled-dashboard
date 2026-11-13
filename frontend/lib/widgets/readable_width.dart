import 'package:flutter/widgets.dart';

/// Keeps content at a readable width on tablets and desktop browsers instead of stretching it across the screen.
class ReadableWidth extends StatelessWidget {
  const ReadableWidth({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720), child: child),
    );
  }
}
