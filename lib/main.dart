import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:flutter/material.dart';
import 'package:mcp_config_manager/models/server_template.dart';
import 'package:mcp_config_manager/screens/auth_screen.dart';
import 'package:mcp_config_manager/screens/home_screen.dart';
import 'package:mcp_config_manager/services/auth_service.dart';
import 'package:mcp_config_manager/services/template_service.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize templates from cache
  final templateService = TemplateService();
  try {
    final templates = await templateService.getCachedTemplates();
    ServerTemplateRepository.updateTemplates(templates);

    // Start fetching templates in background
    templateService.getTemplates().then((templates) {
      ServerTemplateRepository.updateTemplates(templates);
    });
  } catch (e) {
    print('Error initializing templates: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Model Context Protocol',
      // Updated title to match the design
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      home: const AuthGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        // If the snapshot has user data, then they're logged in
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        // Otherwise, they're not logged in
        return const AuthScreen();
      },
    );
  }
}
