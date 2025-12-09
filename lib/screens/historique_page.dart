import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoriquePage extends StatelessWidget {
  const HistoriquePage({super.key});

  // Récupération du cours associé
  Future<Map<String, dynamic>> getCours(String coursId) async {
    final doc = await FirebaseFirestore.instance
        .collection("cours")
        .doc(coursId)
        .get();

    return doc.data() ?? {};
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text("Utilisateur non connecté"),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Historique des pointages"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("presences")
            .where("etudiant_id", isEqualTo: user.uid)
            .orderBy("timestamp", descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const Center(
              child: Text("Aucun pointage enregistré"),
            );
          }

          final docs = snap.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final coursId = data["cours_id"] ?? "";
              final date = data["timestamp"]?.toString() ?? "—";

              return FutureBuilder<Map<String, dynamic>>(
                future: getCours(coursId),
                builder: (context, coursSnap) {
                  if (!coursSnap.hasData) {
                    return const ListTile(
                      title: Text("Chargement..."),
                    );
                  }

                  final cours = coursSnap.data!;
                  final nomCours = cours["nom_cours"] ?? "Cours inconnu";
                  final salle = cours["salle"] ?? "Non indiqué";

                  return Card(
                    margin: const EdgeInsets.all(10),
                    child: ListTile(
                      leading: const Icon(Icons.check_circle, color: Colors.green),
                      title: Text(nomCours),
                      subtitle: Text(
                        "Salle : $salle\nDate : $date",
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
