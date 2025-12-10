import 'package:flutter/material.dart';
import 'package:detection_fasciale/features/home/widgets/widget_home.dart';
import 'package:detection_fasciale/features/login/login_screen.dart';
import 'package:detection_fasciale/features/register/register_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  void _navigateToLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _navigateToRegister(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PresenceConnect'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.indigo,
      ),
      body: HomeWidget(
        onLoginPressed: () => _navigateToLogin(context),
        onRegisterPressed: () => _navigateToRegister(context),
      ),
      // Optionnel : Footer avec des informations
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: const Text(
          '© 2024 PresenceConnect - Tous droits réservés',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),
    );
  }
}
