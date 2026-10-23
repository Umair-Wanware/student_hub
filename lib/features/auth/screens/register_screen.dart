
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>> onRegistered;

  const RegisterScreen({
    super.key,
    required this.onRegistered,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  late final AnimationController _entranceController;
  late final AnimationController _glowController;

  late final Animation<double> _headerOpacity;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _panelOpacity;
  late final Animation<Offset> _panelSlide;

  bool _loading = false;
  bool _hidePassword = true;
  bool _hideConfirm = true;
  String? _error;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    _headerOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.50, curve: Curves.easeOut),
    );

    _headerSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.60, curve: Curves.easeOutCubic),
      ),
    );

    _panelOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.20, 0.90, curve: Curves.easeOut),
    );

    _panelSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.20, 0.90, curve: Curves.easeOutCubic),
      ),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _entranceController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = await ApiService.instance.register(
        name: _name.text,
        email: _email.text,
        password: _password.text,
        confirmPassword: _confirm.text,
      );

      if (!mounted) return;

      widget.onRegistered(user);

      if (!mounted) return;
      Navigator.of(context).pop();
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

  Widget _ambientGlow({
    required double size,
    required Color color,
    required double opacity,
  }) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 55, sigmaY: 55),
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

  Widget _visibilityButton({
    required bool hidden,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      tooltip: hidden ? 'Show password' : 'Hide password',
      onPressed: onPressed,
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) {
          return ScaleTransition(
            scale: animation,
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        child: Icon(
          hidden
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          key: ValueKey(hidden),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101526),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Create account',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: Stack(
        children: [
          // Soft ambient light matching the login screen.
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _glowController,
                builder: (context, child) {
                  final t = _glowController.value;

                  return Stack(
                    children: [
                      Positioned(
                        top: 130 + (t * 20),
                        left: -75,
                        child: _ambientGlow(
                          size: 210,
                          color: const Color(0xFF6277FF),
                          opacity: 0.07 + (t * 0.04),
                        ),
                      ),
                      Positioned(
                        bottom: 70 - (t * 18),
                        right: -75,
                        child: _ambientGlow(
                          size: 230,
                          color: const Color(0xFF9C6BFF),
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
                padding: const EdgeInsets.fromLTRB(22, 26, 22, 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Animated registration header.
                      FadeTransition(
                        opacity: _headerOpacity,
                        child: SlideTransition(
                          position: _headerSlide,
                          child: Column(
                            children: [
                              AnimatedBuilder(
                                animation: _glowController,
                                builder: (context, child) {
                                  final glow =
                                      12 + (_glowController.value * 10);

                                  return Container(
                                    width: 76,
                                    height: 76,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1B2440),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: const Color(0xFF9BAAFF)
                                            .withValues(alpha: 0.22),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF8795FF)
                                              .withValues(alpha: 0.10),
                                          blurRadius: glow * 2,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(23),
                                      child: Image.asset(
                                        'assets/app_icon.png',
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stack) {
                                          return const Icon(
                                            Icons.menu_book_rounded,
                                            size: 42,
                                            color: Color(0xFFABB9FF),
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Join Student Hub',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.7,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Create an account to organise your study life.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.62),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Animated glass registration form.
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
                                    'Create your account',
                                    style: TextStyle(
                                      fontSize: 21,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  const Text(
                                    'A better space for your everyday learning.',
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 23),

                                  AppTextField(
                                    controller: _name,
                                    label: 'Full name',
                                    prefixIcon: Icons.person_outline_rounded,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    validator: (value) =>
                                        (value?.trim().isEmpty ?? true)
                                            ? 'Enter your name'
                                            : null,
                                  ),

                                  const SizedBox(height: 14),

                                  AppTextField(
                                    controller: _email,
                                    label: 'Email address',
                                    prefixIcon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) {
                                      final email = value?.trim() ?? '';

                                      if (!email.contains('@') ||
                                          !email.contains('.')) {
                                        return 'Enter a valid email';
                                      }

                                      return null;
                                    },
                                  ),

                                  const SizedBox(height: 14),

                                  AppTextField(
                                    controller: _password,
                                    label: 'Password',
                                    prefixIcon: Icons.lock_outline_rounded,
                                    obscureText: _hidePassword,
                                    suffixIcon: _visibilityButton(
                                      hidden: _hidePassword,
                                      onPressed: () {
                                        setState(() {
                                          _hidePassword = !_hidePassword;
                                        });
                                      },
                                    ),
                                    validator: (value) {
                                      final password = value ?? '';

                                      if (password.length < 12) {
                                        return 'Use at least 12 characters';
                                      }

                                      if (!RegExp(r'[A-Z]')
                                              .hasMatch(password) ||
                                          !RegExp(r'[a-z]')
                                              .hasMatch(password) ||
                                          !RegExp(r'[0-9]')
                                              .hasMatch(password) ||
                                          !RegExp(r'[^A-Za-z0-9]')
                                              .hasMatch(password)) {
                                        return 'Include uppercase, lowercase, number and symbol';
                                      }

                                      return null;
                                    },
                                  ),

                                  const SizedBox(height: 14),

                                  AppTextField(
                                    controller: _confirm,
                                    label: 'Confirm password',
                                    prefixIcon:
                                        Icons.verified_user_outlined,
                                    obscureText: _hideConfirm,
                                    suffixIcon: _visibilityButton(
                                      hidden: _hideConfirm,
                                      onPressed: () {
                                        setState(() {
                                          _hideConfirm = !_hideConfirm;
                                        });
                                      },
                                    ),
                                    validator: (value) =>
                                        value != _password.text
                                            ? 'Passwords do not match'
                                            : null,
                                  ),

                                  if (_error != null) ...[
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent
                                            .withValues(alpha: 0.09),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: Colors.redAccent
                                              .withValues(alpha: 0.22),
                                        ),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Icon(
                                            Icons.error_outline_rounded,
                                            color: Colors.redAccent,
                                            size: 19,
                                          ),
                                          const SizedBox(width: 9),
                                          Expanded(
                                            child: Text(
                                              _error!,
                                              style: const TextStyle(
                                                color: Colors.redAccent,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 22),

                                  PrimaryButton(
                                    label: 'Create Account',
                                    icon: Icons.person_add_alt_rounded,
                                    loading: _loading,
                                    onPressed: _register,
                                  ),

                                  const SizedBox(height: 16),

                                  Text(
                                    'By creating an account, you can start organising your study life in one place.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.42),
                                      fontSize: 11,
                                      height: 1.5,
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
                            letterSpacing: 2.0,
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
}