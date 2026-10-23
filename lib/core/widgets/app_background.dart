import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF101526),
            Color(0xFF17182D),
            Color(0xFF090D18),
          ],
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            top: -100,
            right: -70,
            child: _GlowOrb(
              size: 280,
              color: Color(0x558B9CFF),
            ),
          ),
          const Positioned(
            bottom: 30,
            left: -100,
            child: _GlowOrb(
              size: 260,
              color: Color(0x3338D9C5),
            ),
          ),
          SafeArea(child: child),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}
