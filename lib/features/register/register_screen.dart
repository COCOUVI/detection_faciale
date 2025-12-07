import 'package:flutter/material.dart';
import 'widgets/register_form.dart'; // On appelle le formulaire

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Fond légèrement grisé
      appBar: AppBar(
        title: const Text("Inscription"),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- LOGO ET NOM DE L'APP ---
              Icon(Icons.person_pin_circle, size: 80, color: Colors.indigo),
              SizedBox(height: 10),
              Text(
                "PresenceConnect",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                "Portail Étudiant",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              SizedBox(height: 40),

              // --- APPEL DU FORMULAIRE ---
              // C'est ici qu'on injecte la logique complexe
              Card(
                elevation: 5,
                color: Colors.white,
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: RegisterForm(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
