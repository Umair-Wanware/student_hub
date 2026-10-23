import 'package:flutter/material.dart';

class StudentHubBackdrop extends StatelessWidget {
  final Widget child;

  const StudentHubBackdrop({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF080D1B),
            Color(0xFF10172B),
            Color(0xFF080D1B),
          ],
          stops: [0, 0.52, 1],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const IgnorePointer(
            child: Stack(
              children: [
                Positioned(
                  top: -130,
                  right: -100,
                  child: _GlowOrb(
                    size: 310,
                    color: Color(0x333D63FF),
                  ),
                ),
                Positioned(
                  top: 330,
                  left: -180,
                  child: _GlowOrb(
                    size: 340,
                    color: Color(0x1F27D9C0),
                  ),
                ),
                Positioned(
                  bottom: -190,
                  right: -80,
                  child: _GlowOrb(
                    size: 360,
                    color: Color(0x1E8A5CFF),
                  ),
                ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowOrb({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 90,
            spreadRadius: 25,
          ),
        ],
      ),
    );
  }
}
