import 'package:flutter/material.dart';

import 'data/services/api_service.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _loading = true;
  Map<String, dynamic>? _user;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      await ApiService.instance.initialize();
      final user = await ApiService.instance.getCurrentUser();

      if (!mounted) return;
      setState(() {
        _user = user;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  void _onLogin(Map<String, dynamic> user) {
    setState(() {
      _user = user;
      _error = null;
    });
  }

  void _onLogout() {
    setState(() => _user = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF8797FF)),
        ),
      );
    }

    if (_user != null) {
      return DashboardScreen(
        user: _user!,
        onLogout: _onLogout,
      );
    }

    return LoginScreen(
      onLogin: _onLogin,
      initialError: _error,
      onRetry: _loadUser,
    );
  }
}
