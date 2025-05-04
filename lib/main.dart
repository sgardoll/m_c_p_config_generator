import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';


import 'package:flutter/material.dart';
import 'package:dreamflow/screens/auth_screen.dart';
import 'package:dreamflow/screens/home_screen.dart';
import 'package:dreamflow/services/auth_service.dart';
import 'theme.dart';

void main() async {
  
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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