import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class FaceService {
  // Cette fonction compare le nouveau visage avec TOUS les étudiants de la base
  // Retourne TRUE si le visage existe déjà
  Future<bool> checkFaceAlreadyExists(List<double> newFaceEmbedding) async {
    // 1. On récupère tous les utilisateurs qui ont déjà un scan (embedding != null)
    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('embedding', isNull: false)
        .get();

    // 2. On parcourt chaque utilisateur pour comparer
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;

      // Sécurité : On vérifie que la liste existe bien
      if (data['embedding'] == null) continue;

      // On convertit les données Firebase en liste de chiffres
      List<dynamic> dbEmbeddingDynamic = data['embedding'];
      List<double> dbEmbedding = dbEmbeddingDynamic
          .map((e) => e as double)
          .toList();

      // 3. CALCUL MATHÉMATIQUE (Distance Euclidienne)
      double distance = _calculateEuclideanDistance(
        newFaceEmbedding,
        dbEmbedding,
      );

      // 4. LE SEUIL (Threshold)
      // Si la distance est inférieure à 0.6, c'est la MÊME personne.
      // (Ce chiffre dépend du modèle IA utilisé, souvent entre 0.6 et 1.0)
      if (distance < 0.8) {
        print("Doublon détecté avec l'utilisateur : ${doc.id}");
        return true; // STOP ! Visage déjà connu
      }
    }

    return false; // C'est bon, visage unique
  }

  // Formule mathématique pure pour comparer deux vecteurs
  double _calculateEuclideanDistance(List<double> v1, List<double> v2) {
    if (v1.length != v2.length) return 100.0; // Erreur taille

    double sum = 0.0;
    for (int i = 0; i < v1.length; i++) {
      sum += pow((v1[i] - v2[i]), 2);
    }
    return sqrt(sum);
  }
}
