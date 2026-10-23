
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/widgets/glass_panel.dart';
import '../../../data/services/api_service.dart';
import '../../attendance/screens/attendance_screen.dart';
import '../../focus/screens/focus_screen.dart';
import '../../notes/screens/notes_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../tasks/screens/tasks_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback onLogout;

  const DashboardScreen({
    super.key,
    required this.user,
    required this.onLogout,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  bool _loggingOut = false;
  late Map<String, dynamic> _user;
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _user = _normalizeUser(widget.user);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user != widget.user) {
      _user = _normalizeUser(widget.user);
    }
  }

  Map<String, dynamic> _normalizeUser(
    Map<String, dynamic> source,
  ) {
    dynamic candidate = source;

    for (var i = 0; i < 3 && candidate is Map; i++) {
      final map = Map<String, dynamic>.from(candidate);

      if (map['user'] is Map) {
        candidate = map['user'];
        continue;
      }

      if (map['data'] is Map) {
        candidate = map['data'];
        continue;
      }

      return map;
    }

    if (candidate is Map) {
      return Map<String, dynamic>.from(candidate);
    }

    return source;
  }

  String _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      if (value == null) continue;

      final text = value.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') {
        return text;
      }
    }
    return '';
  }

  String get _name {
    final name = _firstNonEmpty([
      _user['name'],
      _user['fullName'],
      _user['full_name'],
      _user['displayName'],
      _user['display_name'],
      _user['username'],
      _user['userName'],
    ]);

    if (name.isNotEmpty) return name;

    final email = _firstNonEmpty([_user['email']]);
    if (email.contains('@')) return email.split('@').first;

    return 'Student';
  }

  String get _email => _firstNonEmpty([
        _user['email'],
        _user['emailAddress'],
        _user['email_address'],
      ]);

  Future<void> _refreshProfile() async {
    try {
      final response = await ApiService.instance.getCurrentUser();
      if (!mounted) return;

      final freshUser = _normalizeUser(response);

      setState(() {
        _user = {..._user, ...freshUser};
      });
    } catch (_) {
      // Keep existing profile data if the request fails.
    }
  }

  Future<void> _logout() async {
    if (_loggingOut) return;

    setState(() => _loggingOut = true);

    try {
      await ApiService.instance.logout();
    } catch (_) {
      // Return to login even if the server is unavailable.
    }

    if (!mounted) return;
    widget.onLogout();
  }

  void _openFeature(String feature) {
    final Widget? screen = switch (feature) {
      'My Tasks' => const TasksScreen(),
      'Attendance' => const AttendanceScreen(),
      'Focus Zone' => const FocusScreen(),
      'Notes' => const NotesScreen(),
      _ => null,
    };

    if (screen == null) return;

    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (_, animation, secondaryAnimation) => screen,
        transitionsBuilder: (_, animation, secondaryAnimation, child) {
          final curve = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );

          return FadeTransition(
            opacity: curve,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.04, 0),
                end: Offset.zero,
              ).animate(curve),
              child: child,
            ),
          );
        },
      ),
    );
  }

  Future<void> _openProfile() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ProfileScreen(
          initialUser: _user,
          onLogout: widget.onLogout,
        ),
      ),
    );

    if (mounted) await _refreshProfile();
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width > 650;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0x339BAAFF),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: const Color(0x559BAAFF),
                ),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFFB7C1FF),
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Student Hub',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              tooltip: 'Profile',
              onPressed: _openProfile,
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.06),
                side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
              icon: const Icon(Icons.account_circle_outlined),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned(
            top: 30,
            left: -100,
            child: _GlowOrb(
              animation: _glowController,
              color: const Color(0xFF536DFF),
              size: 230,
            ),
          ),
          Positioned(
            top: 350,
            right: -120,
            child: _GlowOrb(
              animation: _glowController,
              color: const Color(0xFF8C55FF),
              size: 250,
            ),
          ),
          Positioned(
            bottom: -100,
            left: 70,
            child: _GlowOrb(
              animation: _glowController,
              color: const Color(0xFF26BFA9),
              size: 190,
            ),
          ),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _refreshProfile,
              color: const Color(0xFFB7C1FF),
              backgroundColor: const Color(0xFF1A2035),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  ScrollReveal(
                    index: 0,
                    child: _buildWelcomeCard(),
                  ),
                  const SizedBox(height: 30),
                  const ScrollReveal(
                    index: 0,
                    child: _SectionHeading(
                      title: 'Your workspace',
                      subtitle: 'Everything you need to stay on track.',
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: wide ? 4 : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 13,
                    mainAxisSpacing: 13,
                    childAspectRatio: wide ? 0.95 : 1.02,
                    children: [
                      ScrollReveal(
                        index: 0,
                        child: _FeatureTile(
                          icon: Icons.check_circle_outline_rounded,
                          title: 'My Tasks',
                          subtitle: 'Plan your work',
                          color: const Color(0xFF9BAAFF),
                          onTap: () => _openFeature('My Tasks'),
                        ),
                      ),
                      ScrollReveal(
                        index: 1,
                        child: _FeatureTile(
                          icon: Icons.event_available_rounded,
                          title: 'Attendance',
                          subtitle: 'Track classes',
                          color: const Color(0xFF63DDC6),
                          onTap: () => _openFeature('Attendance'),
                        ),
                      ),
                      ScrollReveal(
                        index: 2,
                        child: _FeatureTile(
                          icon: Icons.timer_outlined,
                          title: 'Focus Zone',
                          subtitle: 'Study sessions',
                          color: const Color(0xFFFFC477),
                          onTap: () => _openFeature('Focus Zone'),
                        ),
                      ),
                      ScrollReveal(
                        index: 3,
                        child: _FeatureTile(
                          icon: Icons.sticky_note_2_outlined,
                          title: 'Notes',
                          subtitle: 'Save your ideas',
                          color: const Color(0xFFD9A5FF),
                          onTap: () => _openFeature('Notes'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  ScrollReveal(
                    index: 0,
                    child: _buildProfileCard(),
                  ),
                  const SizedBox(height: 18),
                  ScrollReveal(
                    index: 0,
                    child: _buildLogoutButton(),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: Text(
                      'SMALL STEPS. BIG PROGRESS.',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.1,
                        color: Colors.white.withValues(alpha: 0.32),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        final glow = 0.10 + _glowController.value * 0.08;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6D7FFF).withValues(alpha: glow),
                blurRadius: 32,
                spreadRadius: 1,
              ),
            ],
          ),
          child: child,
        );
      },
      child: GlassPanel(
        padding: const EdgeInsets.all(24),
        tint: const Color(0x338B9CFF),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x229BAAFF),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: const Color(0x449BAAFF),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bolt_rounded,
                        size: 14,
                        color: Color(0xFFB7C1FF),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'YOUR STUDY SPACE',
                        style: TextStyle(
                          letterSpacing: 1.5,
                          color: Color(0xFFB7C1FF),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.waving_hand_rounded,
                  color: Color(0xFFFFC477),
                  size: 25,
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              'Hello, $_name',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 30,
                height: 1.15,
                letterSpacing: -0.8,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Make today count. One focused session at a time.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.70),
                height: 1.6,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _openFeature('My Tasks'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF9BAAFF),
                  foregroundColor: const Color(0xFF11162A),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text(
                  'Open My Tasks',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return GlassPanel(
      padding: const EdgeInsets.all(17),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF7F91FF),
                  Color(0xFF7658CF),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7F91FF).withValues(alpha: 0.25),
                  blurRadius: 16,
                ),
              ],
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 27,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _email.isEmpty ? 'Your Student Hub account' : _email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.56),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Edit profile',
            onPressed: _openProfile,
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return OutlinedButton.icon(
      onPressed: _loggingOut ? null : _logout,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFFF929F),
        side: BorderSide(
          color: const Color(0xFFFF929F).withValues(alpha: 0.28),
        ),
        backgroundColor: const Color(0x12FF687A),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      icon: _loggingOut
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.logout_rounded),
      label: Text(
        _loggingOut ? 'Signing out…' : 'Sign out',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeading({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            letterSpacing: -0.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.56),
          ),
        ),
      ],
    );
  }
}

class _FeatureTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  State<_FeatureTile> createState() => _FeatureTileState();
}

class _FeatureTileState extends State<_FeatureTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 130),
      lowerBound: 0,
      upperBound: 0.035,
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pressController,
      builder: (context, child) => Transform.scale(
        scale: 1 - _pressController.value,
        child: child,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: (_) => _pressController.forward(),
          onTapUp: (_) => _pressController.reverse(),
          onTapCancel: _pressController.reverse,
          borderRadius: BorderRadius.circular(23),
          child: GlassPanel(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 49,
                  height: 49,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: widget.color.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Icon(
                    widget.icon,
                    size: 26,
                    color: widget.color,
                  ),
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.56),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final Animation<double> animation;
  final Color color;
  final double size;

  const _GlowOrb({
    required this.animation,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final scale = 0.9 + animation.value * 0.16;
        final opacity = 0.08 + animation.value * 0.045;

        return Transform.scale(
          scale: scale,
          child: ImageFiltered(
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
          ),
        );
      },
    );
  }
}

/// Reveals a card when it enters the scroll viewport.
/// Once revealed, the card stays visible instead of replaying
/// the entrance animation on every small scroll movement.
class ScrollReveal extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration duration;

  const ScrollReveal({
    super.key,
    required this.child,
    this.index = 0,
    this.duration = const Duration(milliseconds: 650),
  });

  @override
  State<ScrollReveal> createState() => _ScrollRevealState();
}

class _ScrollRevealState extends State<ScrollReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  ScrollPosition? _scrollPosition;
  bool _visible = false;
  bool _scheduled = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _opacity = curved;
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(curved);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final nextPosition = Scrollable.maybeOf(context)?.position;

    if (_scrollPosition != nextPosition) {
      _scrollPosition?.removeListener(_checkVisibility);
      _scrollPosition = nextPosition;
      _scrollPosition?.addListener(_checkVisibility);
    }

    _scheduleVisibilityCheck();
  }

  void _scheduleVisibilityCheck() {
    if (_scheduled || _visible) return;
    _scheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!mounted || _visible) return;
      _checkVisibility();
    });
  }

  void _checkVisibility() {
    if (!mounted || _visible) return;

    final object = context.findRenderObject();
    if (object is! RenderBox || !object.hasSize) return;

    final top = object.localToGlobal(Offset.zero).dy;
    final bottom = top + object.size.height;
    final screenHeight = MediaQuery.sizeOf(context).height;

    final visibleOnScreen =
        bottom > 0 && top < screenHeight * 0.94;

    if (visibleOnScreen) {
      _reveal();
    }
  }

  void _reveal() {
    if (_visible || !mounted) return;

    _visible = true;

    Future<void>.delayed(
      Duration(milliseconds: widget.index * 100),
      () {
        if (mounted) _controller.forward();
      },
    );
  }

  @override
  void dispose() {
    _scrollPosition?.removeListener(_checkVisibility);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}