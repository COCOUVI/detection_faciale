import 'package:flutter/material.dart';
import 'widgets/login_form.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Connexion"),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              // --- Icone & Nom application ---
              const Icon(Icons.lock_person_rounded,
                  size: 80, color: Colors.indigo),
              const SizedBox(height: 10),

              const Text(
                "PresenceConnect",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                  letterSpacing: 1.5,
                ),
              ),

              const Text(
                "Portail Étudiant",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),

              const SizedBox(height: 40),

              // --- Carte avec formulaire ---
              const Card(
                elevation: 5,
                color: Colors.white,
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: LoginForm(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
