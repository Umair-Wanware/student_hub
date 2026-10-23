import 'package:flutter/material.dart';

import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> initialUser;
  final VoidCallback onLogout;

  const ProfileScreen({
    super.key,
    required this.initialUser,
    required this.onLogout,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _email;
  final _formKey = GlobalKey<FormState>();

  bool _saving = false;
  bool _loggingOut = false;
  String? _message;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(
      text: widget.initialUser['name']?.toString() ?? '',
    );
    _email = TextEditingController(
      text: widget.initialUser['email']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _message = null;
      _error = null;
    });

    try {
      await ApiService.instance.updateProfile(
        name: _name.text,
        email: _email.text,
      );
      if (!mounted) return;
      setState(() => _message = 'Your profile was updated.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _logout() async {
    setState(() => _loggingOut = true);
    try {
      await ApiService.instance.logout();
    } catch (_) {
      // Return to the login screen even if the server is unreachable.
    }

    if (!mounted) return;
    widget.onLogout();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Your Profile',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 42,
                  backgroundColor: Color(0x338B9CFF),
                  child: Icon(
                    Icons.person_rounded,
                    size: 44,
                    color: Color(0xFFB7C1FF),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _name.text.isEmpty ? 'Student' : _name.text,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 22),
                GlassPanel(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Account details',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 20),
                        AppTextField(
                          controller: _name,
                          label: 'Full name',
                          prefixIcon: Icons.person_outline_rounded,
                          textCapitalization: TextCapitalization.words,
                          validator: (v) => (v?.trim().isEmpty ?? true)
                              ? 'Enter your name'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        AppTextField(
                          controller: _email,
                          label: 'Email address',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            final value = v?.trim() ?? '';
                            if (!value.contains('@')) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        ),
                        if (_message != null) ...[
                          const SizedBox(height: 14),
                          Text(
                            _message!,
                            style: const TextStyle(color: Color(0xFF70DFC3)),
                          ),
                        ],
                        if (_error != null) ...[
                          const SizedBox(height: 14),
                          Text(
                            _error!,
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ],
                        const SizedBox(height: 20),
                        PrimaryButton(
                          label: 'Save Changes',
                          icon: Icons.check_rounded,
                          loading: _saving,
                          onPressed: _save,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _loggingOut ? null : _logout,
                  icon: const Icon(Icons.logout_rounded),
                  label: Text(_loggingOut ? 'Signing out…' : 'Sign out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
