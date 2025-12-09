import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '/services/cloudinary_service.dart';

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();

  // Contrôleurs Texte
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Variables d'état
  String? _selectedFiliereId;
  File? _photoPrise;
  bool _isLoading = false;

  // Détecteur de visage avec landmarks activés
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableTracking: true,
      minFaceSize: 0.15,
      enableLandmarks: true,
      enableClassification: true,
    ),
  );

  // Service Cloudinary
  final CloudinaryService _cloudinaryService = CloudinaryService();

  @override
  void dispose() {
    _faceDetector.close();
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ========== FONCTION CAMÉRA ==========
  Future<void> _prendrePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 50,
    );

    if (pickedFile != null) {
      setState(() => _photoPrise = File(pickedFile.path));
    }
  }

  // ========== UPLOAD PHOTO VERS CLOUDINARY ==========
  Future<String> _uploadPhoto(File photo, String userId) async {
    try {
      print('🔄 Début upload Cloudinary pour UID: $userId');
      String photoUrl = await _cloudinaryService.uploadPhoto(photo, userId);
      print('✅ Photo uploadée !  URL: $photoUrl');
      return photoUrl;
    } catch (e) {
      print('❌ Erreur upload photo : $e');
      rethrow;
    }
  }

  Future<List<double>?> _extraireEmbedding(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final List<Face> faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        _showSnackBar('Aucun visage détecté');
        return null;
      }
      if (faces.length > 1) {
        _showSnackBar('Plusieurs visages détectés');
        return null;
      }

      Face face = faces.first;

      final rect = face.boundingBox;
      double faceWidth = rect.width;
      double faceHeight = rect.height;
      double faceSize = (faceWidth + faceHeight) / 2;

      double centerX = rect.left + faceWidth / 2;
      double centerY = rect.top + faceHeight / 2;

      List<double> normalizedLandmarks = [];

      final landmarks = [
        face.landmarks[FaceLandmarkType.leftEye],
        face.landmarks[FaceLandmarkType.rightEye],
        face.landmarks[FaceLandmarkType.noseBase],
        face.landmarks[FaceLandmarkType.leftMouth],
        face.landmarks[FaceLandmarkType.rightMouth],
      ];

      for (var landmark in landmarks) {
        if (landmark != null) {
          double nx = (landmark.position.x - centerX) / faceSize;
          double ny = (landmark.position.y - centerY) / faceSize;
          normalizedLandmarks.addAll([nx, ny]);
        } else {
          normalizedLandmarks.addAll([0.0, 0.0]);
        }
      }

      normalizedLandmarks.addAll([
        (face.headEulerAngleX ?? 0.0) / 45.0,
        (face.headEulerAngleY ?? 0.0) / 45.0,
        (face.headEulerAngleZ ?? 0.0) / 45.0,
      ]);

      normalizedLandmarks.add(face.smilingProbability ?? 0.0);
      normalizedLandmarks.add(face.leftEyeOpenProbability ?? 0.5);
      normalizedLandmarks.add(face.rightEyeOpenProbability ?? 0.5);

      print('Embedding normalisé : ${normalizedLandmarks.length} dimensions');
      return normalizedLandmarks;
    } catch (e) {
      print('Erreur embedding : $e');
      _showSnackBar('Erreur lors de l\'analyse du visage');
      return null;
    }
  }

  // ========== CALCUL SIMILARITÉ COSINUS ==========
  double _calculerSimilarite(List<double> embedding1, List<double> embedding2) {
    if (embedding1.length != embedding2.length) {
      print(
        '⚠️ Tailles différentes : ${embedding1.length} vs ${embedding2.length}',
      );
      return 0.0;
    }

    double dotProduct = 0.0;
    double norm1 = 0.0;
    double norm2 = 0.0;

    for (int i = 0; i < embedding1.length; i++) {
      dotProduct += embedding1[i] * embedding2[i];
      norm1 += embedding1[i] * embedding1[i];
      norm2 += embedding2[i] * embedding2[i];
    }

    if (norm1 == 0.0 || norm2 == 0.0) {
      print('⚠️ Norme nulle détectée');
      return 0.0;
    }

    double similarity = dotProduct / (sqrt(norm1) * sqrt(norm2));
    return similarity;
  }

  // ========== VÉRIFIER SI UN VISAGE SIMILAIRE EXISTE DÉJÀ ==========
  Future<bool> _visageDejaEnregistre(List<double> embedding) async {
    try {
      print('🔍 Vérification unicité du visage...');

      QuerySnapshot users = await FirebaseFirestore.instance
          .collection('users')
          .where('embedding', isNotEqualTo: [])
          .get();

      print('   ${users.docs.length} utilisateur(s) à comparer');

      for (var doc in users.docs) {
        try {
          List<double> existingEmbedding = List<double>.from(doc['embedding']);

          double similarity = _calculerSimilarite(embedding, existingEmbedding);

          String nom = doc['nom'] ?? 'N/A';
          String prenom = doc['prenom'] ?? 'N/A';
          print(
            '   📊 Similarité avec $prenom $nom : ${(similarity * 100).toStringAsFixed(2)}%',
          );

          if (similarity > 0.55) {
            print('❌ VISAGE SIMILAIRE DÉTECTÉ !');
            print('   Utilisateur existant : $prenom $nom');

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '❌ Ce visage est déjà enregistré !\nUtilisateur : $prenom $nom\nSimilarité : ${(similarity * 100).toStringAsFixed(0)}%',
                  ),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 5),
                ),
              );
            }

            return true;
          }
        } catch (e) {
          print('⚠️ Erreur comparaison avec document ${doc.id} : $e');
          continue;
        }
      }

      print('✅ Aucun visage similaire trouvé');
      return false;
    } catch (e) {
      print('❌ Erreur vérification unicité : $e');
      return false;
    }
  }

  ///snackbar helper
  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.orange),
      );
    }
  }

  // ========== FONCTION INSCRIPTION ==========
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_photoPrise == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Le scan du visage est OBLIGATOIRE. '),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('\n📸 === ÉTAPE 1 : EXTRACTION EMBEDDING ===');
      List<double>? embedding = await _extraireEmbedding(_photoPrise!);

      if (embedding == null) {
        setState(() => _isLoading = false);
        return;
      }

      print('\n🔍 === ÉTAPE 2 : VÉRIFICATION UNICITÉ ===');
      bool dejaEnregistre = await _visageDejaEnregistre(embedding);

      if (dejaEnregistre) {
        print('❌ Inscription refusée : Visage déjà enregistré');
        setState(() => _isLoading = false);
        return;
      }

      print('\n🔐 === ÉTAPE 3 : CRÉATION COMPTE AUTH ===');
      UserCredential userCred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      String uid = userCred.user!.uid;
      print('✅ UID créé : $uid');

      print('\n📤 === ÉTAPE 4 : UPLOAD PHOTO CLOUDINARY ===');
      String photoUrl = await _uploadPhoto(_photoPrise!, uid);

      print('\n💾 === ÉTAPE 5 : SAUVEGARDE FIRESTORE ===');
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'id': uid,
        'nom': _nomController.text.trim().toUpperCase(),
        'prenom': _prenomController.text.trim(),
        'email': _emailController.text.trim(),
        'role': 'etudiant',
        'filiere_id': _selectedFiliereId,
        'photo_url': photoUrl,
        'embedding': embedding,
        'created_at': FieldValue.serverTimestamp(),
      });

      print('✅ Utilisateur sauvegardé dans Firestore');
      print('\n🎉 === INSCRIPTION RÉUSSIE ===\n');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Bienvenue sur PresenceConnect !'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        _formKey.currentState!.reset();
        setState(() {
          _photoPrise = null;
          _selectedFiliereId = null;
        });
      }
    } on FirebaseAuthException catch (e) {
      print('❌ ERREUR AUTH : ${e.code} - ${e.message}');
      String errorMessage = 'Erreur d\'authentification';
      if (e.code == 'email-already-in-use') {
        errorMessage = '❌ Cet email est déjà utilisé. ';
      } else if (e.code == 'weak-password') {
        errorMessage = '❌ Mot de passe trop faible.';
      } else if (e.code == 'invalid-email') {
        errorMessage = '❌ Email invalide.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    } on FirebaseException catch (e) {
      print('❌ ERREUR FIREBASE : ${e.code} - ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur Firebase : ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e, stackTrace) {
      print('❌ ERREUR INCONNUE : $e');
      print('Stack trace : $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur : ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          GestureDetector(
            onTap: _prendrePhoto,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: _photoPrise == null
                      ? Colors.red[100]
                      : Colors.green[100],
                  backgroundImage: _photoPrise != null
                      ? FileImage(_photoPrise!)
                      : null,
                  child: _photoPrise == null
                      ? const Icon(
                          Icons.camera_alt,
                          size: 30,
                          color: Colors.red,
                        )
                      : null,
                ),
                const SizedBox(height: 5),
                Text(
                  _photoPrise == null
                      ? "Appuyer pour scanner *"
                      : "Visage scanné ! ",
                  style: TextStyle(
                    color: _photoPrise == null ? Colors.red : Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _nomController,
            decoration: const InputDecoration(
              labelText: 'Nom',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
            validator: (v) => v!.isEmpty ? 'Requis' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _prenomController,
            decoration: const InputDecoration(
              labelText: 'Prénom',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(),
            ),
            validator: (v) => v!.isEmpty ? 'Requis' : null,
          ),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('fillieres')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: LinearProgressIndicator());
              }

              List<DropdownMenuItem<String>> filiereItems = snapshot.data!.docs
                  .map((doc) {
                    return DropdownMenuItem(
                      value: doc.id,
                      child: Text(doc['nom']),
                    );
                  })
                  .toList();

              return DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Filière',
                  prefixIcon: Icon(Icons.school),
                  border: OutlineInputBorder(),
                ),
                value: _selectedFiliereId,
                items: filiereItems,
                onChanged: (value) =>
                    setState(() => _selectedFiliereId = value),
                validator: (v) =>
                    v == null ? 'Veuillez choisir une filière' : null,
              );
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(),
            ),
            validator: (v) => v!.contains('@') ? null : 'Email invalide',
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Mot de passe',
              prefixIcon: Icon(Icons.lock),
              border: OutlineInputBorder(),
            ),
            validator: (v) => v!.length < 6 ? '6 caractères min.' : null,
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      "S'inscrire",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
