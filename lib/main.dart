import 'package:detection_fasciale/features/home/home.dart';
import 'package:detection_fasciale/features/login/login_screen.dart';
import 'package:detection_fasciale/features/register/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const PresenceConnectApp());
}

class PresenceConnectApp extends StatelessWidget {
  const PresenceConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PresenceConnect',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.indigo,
        ),
      ),
      home: const HomeScreen(), // Page d'accueil
      // Routes nommées (optionnel mais recommandé pour la navigation)
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
