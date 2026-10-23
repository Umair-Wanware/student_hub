import 'package:flutter/material.dart';
import 'auth_gate.dart';
import 'core/theme/student_hub_theme.dart';
import 'core/widgets/student_hub_backdrop.dart';
import 'boot_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StudentHubApp());
}

class StudentHubApp extends StatelessWidget {
  const StudentHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Hub',
      debugShowCheckedModeBanner: false,

      // Liquid Glass theme
      theme: StudentHubTheme.dark,
      darkTheme: StudentHubTheme.dark,
      themeMode: ThemeMode.dark,

      // Shared background across all screens and routes
      builder: (context, child) {
        return StudentHubBackdrop(
          child: child ?? const SizedBox.shrink(),
        );
      },

      // Preserves your authentication flow
      home: BootScreen(
        homeBuilder: (_) => AuthGate(),
      ),
    );
  }
}
