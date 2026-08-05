import 'package:flutter/material.dart';

class FloatingWidget extends StatefulWidget {
  final Widget child;
  const FloatingWidget({super.key, required this.child});

  @override
  State<FloatingWidget> createState() => _FloatingWidgetState();
}

class _FloatingWidgetState extends State<FloatingWidget> {
  double _value = 0.0;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: _value),
      duration: const Duration(seconds: 1),
      onEnd: () {
        if (mounted) {
          setState(() {
            _value = _value == 0.0 ? 3.0 : 0.0;
          });
        }
      },
      builder: (context, offset, child) {
        return Transform.translate(
          offset: Offset(0, -offset),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class PulseWidget extends StatefulWidget {
  final Widget child;
  const PulseWidget({super.key, required this.child});

  @override
  State<PulseWidget> createState() => _PulseWidgetState();
}

class _PulseWidgetState extends State<PulseWidget> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 1.0, end: _scale),
      duration: const Duration(milliseconds: 900),
      onEnd: () {
        if (mounted) {
          setState(() {
            _scale = _scale == 1.0 ? 1.15 : 1.0;
          });
        }
      },
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class RotateWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  const RotateWidget({super.key, required this.child, this.duration = const Duration(seconds: 4)});

  @override
  State<RotateWidget> createState() => _RotateWidgetState();
}

class _RotateWidgetState extends State<RotateWidget> {
  double _angle = 0.0;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: _angle),
      duration: widget.duration,
      onEnd: () {
        if (mounted) {
          setState(() {
            _angle += 6.28318;
          });
        }
      },
      builder: (context, angle, child) {
        return Transform.rotate(
          angle: angle,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
