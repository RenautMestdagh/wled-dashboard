import 'package:flutter/material.dart';
import 'dart:async';

class DiscoveryAnimationWidget extends StatefulWidget {
  final bool isDiscovering;

  const DiscoveryAnimationWidget({super.key, required this.isDiscovering});

  @override
  State<DiscoveryAnimationWidget> createState() => _DiscoveryAnimationWidgetState();
}

class _DiscoveryAnimationWidgetState extends State<DiscoveryAnimationWidget> {
  Timer? _animationTimer;
  int _discoveryMilliseconds = 0;
  DateTime? _discoveryStartTime;

  @override
  void initState() {
    super.initState();
    _setupAnimationTimer();
  }

  @override
  void didUpdateWidget(DiscoveryAnimationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reset timer when discovery state changes
    if (widget.isDiscovering != oldWidget.isDiscovering) {
      if (widget.isDiscovering) {
        _discoveryStartTime = DateTime.now();
        _discoveryMilliseconds = 0;
      } else {
        _discoveryMilliseconds = 0;
      }
    }
  }

  void _setupAnimationTimer() {
    _animationTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (widget.isDiscovering && mounted) {
        setState(() {
          _discoveryMilliseconds = DateTime.now().difference(_discoveryStartTime!).inMilliseconds;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isDiscovering) {
      return const Icon(Icons.chevron_right);
    }

    if (_discoveryMilliseconds < 5000) {
      // Show circular progress indicator for first 5 seconds
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          value: _discoveryMilliseconds / 5000,
        ),
      );
    } else {
      // Show spinning icon after 7 seconds
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2, // Thin outline
        ),
      );
    }
  }
}