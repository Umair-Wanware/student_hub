
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/services/api_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>> onLogin;
  final String? initialError;
  final VoidCallback? onRetry;

  const LoginScreen({
    super.key,
    required this.onLogin,
    this.initialError,
    this.onRetry,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  late final AnimationController _entranceController;
  late final AnimationController _glowController;

  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<Offset> _headingSlide;
  late final Animation<double> _headingOpacity;
  late final Animation<Offset> _panelSlide;
  late final Animation<double> _panelOpacity;

  bool _loading = false;
  bool _hidePassword = true;
  String? _error;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _logoOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );

    _logoScale = Tween<double>(
      begin: 0.72,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutBack),
      ),
    );

    _headingOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.20, 0.65, curve: Curves.easeOut),
    );

    _headingSlide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.20, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    _panelOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.35, 0.90, curve: Curves.easeOut),
    );

    _panelSlide = Tween<Offset>(
      begin: const Offset(0, 0.10),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.30, 0.90, curve: Curves.easeOutCubic),
      ),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _entranceController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = await ApiService.instance.login(
        email: _email.text,
        password: _password.text,
      );

      if (!mounted) return;
      widget.onLogin(user);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error
            .toString()
            .replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _openRegister() async {
    if (!mounted || _loading) return;

    FocusScope.of(context).unfocus();

    await Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        reverseTransitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (context, animation, secondaryAnimation) {
          return RegisterScreen(
            onRegistered: (user) {
              widget.onLogin(user);
            },
          );
        },
        transitionsBuilder: (
          context,
          animation,
          secondaryAnimation,
          child,
        ) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );

          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.04, 0),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Subtle ambient light behind the existing glass UI.
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _glowController,
                builder: (context, child) {
                  final t = _glowController.value;

                  return Stack(
                    children: [
                      Positioned(
                        top: 80 + (t * 24),
                        left: -65,
                        child: _ambientGlow(
                          color: const Color(0xFF6277FF),
                          size: 190,
                          opacity: 0.08 + (t * 0.04),
                        ),
                      ),
                      Positioned(
                        bottom: 80 - (t * 20),
                        right: -70,
                        child: _ambientGlow(
                          color: const Color(0xFF9C6BFF),
                          size: 210,
                          opacity: 0.06 + (t * 0.04),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 30,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Animated app logo.
                      FadeTransition(
                        opacity: _logoOpacity,
                        child: ScaleTransition(
                          scale: _logoScale,
                          child: Center(
                            child: AnimatedBuilder(
                              animation: _glowController,
                              builder: (context, child) {
                                final glow =
                                    14.0 + (_glowController.value * 12);

                                return Container(
                                  width: 86,
                                  height: 86,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(26),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF8C9BFF)
                                            .withValues(alpha: 0.10),
                                        blurRadius: glow * 2,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(26),
                                    child: Image.asset(
                                      'assets/app_icon.png',
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stack) {
                                        return Container(
                                          color: const Color(0xFF1B2440),
                                          alignment: Alignment.center,
                                          child: const Icon(
                                            Icons.menu_book_rounded,
                                            size: 45,
                                            color: Color(0xFFABB9FF),
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
                      ),

                      const SizedBox(height: 22),

                      // Animated title and subtitle.
                      FadeTransition(
                        opacity: _headingOpacity,
                        child: SlideTransition(
                          position: _headingSlide,
                          child: Column(
                            children: [
                              const Text(
                                'Student Hub',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1.0,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Your space to plan, focus, and grow.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  letterSpacing: 0.2,
                                  color: Colors.white.withValues(alpha: 0.65),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Animated glass login panel.
                      FadeTransition(
                        opacity: _panelOpacity,
                        child: SlideTransition(
                          position: _panelSlide,
                          child: GlassPanel(
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text(
                                    'Welcome back',
                                    style: TextStyle(
                                      fontSize: 23,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Sign in to continue to your dashboard.',
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  AppTextField(
                                    controller: _email,
                                    label: 'Email address',
                                    prefixIcon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) {
                                      final email = value?.trim() ?? '';

                                      if (email.isEmpty ||
                                          !email.contains('@')) {
                                        return 'Enter a valid email address';
                                      }

                                      return null;
                                    },
                                  ),

                                  const SizedBox(height: 16),

                                  AppTextField(
                                    controller: _password,
                                    label: 'Password',
                                    prefixIcon: Icons.lock_outline_rounded,
                                    obscureText: _hidePassword,
                                    suffixIcon: IconButton(
                                      tooltip: _hidePassword
                                          ? 'Show password'
                                          : 'Hide password',
                                      onPressed: () {
                                        setState(() {
                                          _hidePassword = !_hidePassword;
                                        });
                                      },
                                      icon: AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        transitionBuilder: (
                                          child,
                                          animation,
                                        ) {
                                          return ScaleTransition(
                                            scale: animation,
                                            child: FadeTransition(
                                              opacity: animation,
                                              child: child,
                                            ),
                                          );
                                        },
                                        child: Icon(
                                          _hidePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          key: ValueKey(_hidePassword),
                                        ),
                                      ),
                                    ),
                                    validator: (value) =>
                                        (value ?? '').isEmpty
                                            ? 'Enter your password'
                                            : null,
                                  ),

                                  if (_error != null ||
                                      widget.initialError != null) ...[
                                    const SizedBox(height: 16),
                                    Text(
                                      _error ?? widget.initialError!,
                                      style: const TextStyle(
                                        color: Colors.redAccent,
                                        fontSize: 13,
                                      ),
                                    ),
                                    if (widget.onRetry != null)
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: TextButton(
                                          onPressed: widget.onRetry,
                                          child: const Text(
                                            'Retry session check',
                                          ),
                                        ),
                                      ),
                                  ],

                                  const SizedBox(height: 22),

                                  // Keep the existing authentication button.
                                  PrimaryButton(
                                    label: 'Sign In',
                                    icon: Icons.arrow_forward_rounded,
                                    loading: _loading,
                                    onPressed: _login,
                                  ),

                                  const SizedBox(height: 14),

                                  AnimatedOpacity(
                                    duration: const Duration(
                                      milliseconds: 200,
                                    ),
                                    opacity: _loading ? 0.5 : 1,
                                    child: TextButton(
                                      onPressed:
                                          _loading ? null : _openRegister,
                                      child: const Text(
                                        "Don't have an account? Create one",
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      FadeTransition(
                        opacity: _panelOpacity,
                        child: Text(
                          'LEARN  •  FOCUS  •  GROW',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.2,
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ambientGlow({
    required Color color,
    required double size,
    required double opacity,
  }) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(
        sigmaX: 55,
        sigmaY: 55,
      ),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: opacity),
        ),
      ),
    );
  }
}