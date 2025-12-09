import 'package:flutter/material.dart';
import 'screens/historique_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Ce fichier sera génér

void main() {
   WidgetsFlutterBinding.ensureInitialized();
  
  // Initialise Firebase avec les options générées
  Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App de Présence',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HistoriquePage(), // Ou ta page d'accueil
      routes: {
        '/historique': (context) => HistoriquePage(),
      },
    );
  }
}