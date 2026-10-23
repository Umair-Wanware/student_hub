
import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

class BootScreen extends StatefulWidget {
  final WidgetBuilder homeBuilder;

  const BootScreen({
    super.key,
    required this.homeBuilder,
  });

  @override
  State<BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<BootScreen>
    with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final AnimationController _glowController;

  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _titleOpacity;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _taglineOpacity;

  Timer? _navigationTimer;
  bool _finished = false;

  @override
  void initState() {
    super.initState();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    _logoOpacity = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );

    _logoScale = Tween<double>(
      begin: 0.78,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(
          0.0,
          0.65,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    _titleOpacity = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.30, 0.75, curve: Curves.easeOut),
    );

    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.22),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(
          0.25,
          0.75,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    _taglineOpacity = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.60, 1.0, curve: Curves.easeOut),
    );

    _introController.forward();

    // Keep the splash visible briefly, then open the existing app.
    _navigationTimer = Timer(
      const Duration(milliseconds: 2600),
      _openHome,
    );
  }

  void _openHome() {
    if (!mounted || _finished) return;

    setState(() {
      _finished = true;
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _introController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101426),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 550),
        reverseDuration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: _finished
            ? KeyedSubtree(
                key: const ValueKey('home'),
                child: Builder(builder: widget.homeBuilder),
              )
            : _buildSplash(),
      ),
    );
  }

  Widget _buildSplash() {
    return SizedBox.expand(
      key: const ValueKey('splash'),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Dark navy background.
          const ColoredBox(
            color: Color(0xFF101426),
          ),

          // Soft ambient light.
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              final t = _glowController.value;

              return Stack(
                children: [
                  Positioned(
                    top: MediaQuery.sizeOf(context).height * 0.22,
                    left: MediaQuery.sizeOf(context).width * 0.18,
                    child: _blurredGlow(
                      size: 210 + (t * 30),
                      color: const Color(0xFF596BFF),
                      opacity: 0.10 + (t * 0.06),
                    ),
                  ),
                  Positioned(
                    bottom: MediaQuery.sizeOf(context).height * 0.20,
                    right: -35,
                    child: _blurredGlow(
                      size: 190 + (t * 25),
                      color: const Color(0xFF9B6BFF),
                      opacity: 0.07 + (t * 0.05),
                    ),
                  ),
                ],
              );
            },
          ),

          // Main logo and text.
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeTransition(
                  opacity: _logoOpacity,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: AnimatedBuilder(
                      animation: _glowController,
                      builder: (context, child) {
                        final glow = 12 +
                            (_glowController.value * 12);

                        return Container(
                          width: 112,
                          height: 112,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF8795FF)
                                    .withValues(alpha: 0.13),
                                blurRadius: glow * 2,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: Image.asset(
                              'assets/app_icon.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stack) {
                                return Container(
                                  color: const Color(0xFF1B2440),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.menu_book_rounded,
                                    size: 58,
                                    color: Color(0xFFB9C5FF),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                FadeTransition(
                  opacity: _titleOpacity,
                  child: SlideTransition(
                    position: _titleSlide,
                    child: const Text(
                      'Student Hub',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.8,
                        color: Color(0xFFF4F5FF),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                FadeTransition(
                  opacity: _taglineOpacity,
                  child: const Text(
                    'Your space to learn and grow.',
                    style: TextStyle(
                      fontSize: 14,
                      letterSpacing: 0.25,
                      color: Color(0xFFA7B0D0),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Small loading indicator at the bottom.
          Positioned(
            left: 0,
            right: 0,
            bottom: 64,
            child: FadeTransition(
              opacity: _taglineOpacity,
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: const Color(0xFFB5C0FF)
                        .withValues(alpha: 0.8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blurredGlow({
    required double size,
    required Color color,
    required double opacity,
  }) {
    return IgnorePointer(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: 65,
          sigmaY: 65,
        ),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: opacity),
          ),
        ),
      ),
    );
  }
}