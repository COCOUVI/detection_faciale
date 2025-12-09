import 'package:detection_fasciale/features/login/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'features/register/register_screen.dart'; // On importe notre feature

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
        primarySwatch: Colors.indigo, // Une couleur un peu "Pro"
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
