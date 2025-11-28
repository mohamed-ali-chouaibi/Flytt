import 'package:flutter/material.dart';
class AnimatedCheck extends StatefulWidget {
  final Color color;
  final double size;
  final Duration duration;
  final bool autoplay;
  const AnimatedCheck({
    Key? key,
    this.color = const Color(0xFF10B981),
    this.size = 24,
    this.duration = const Duration(milliseconds: 600),
    this.autoplay = true,
  }) : super(key: key);
  @override
  State<AnimatedCheck> createState() => _AnimatedCheckState();
}
class _AnimatedCheckState extends State<AnimatedCheck> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    if (widget.autoplay) {
      _controller.forward();
    }
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: Icon(Icons.check_circle_rounded, color: widget.color, size: widget.size),
      ),
    );
  }
}
