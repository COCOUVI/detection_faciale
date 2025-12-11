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
  bool _obscurePassword = true;

  // Détecteur de visage
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
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  // ========== FONCTION INSCRIPTION ==========
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_photoPrise == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Le scan du visage est OBLIGATOIRE.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
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
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Bienvenue sur PresenceConnect ! Votre compte a été créé avec succès.',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
        
        // Réinitialiser le formulaire avec animation
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          _formKey.currentState!.reset();
          setState(() {
            _photoPrise = null;
            _selectedFiliereId = null;
            _obscurePassword = true;
          });
        }
      }
    } on FirebaseAuthException catch (e) {
      print('❌ ERREUR AUTH : ${e.code} - ${e.message}');
      String errorMessage = 'Erreur d\'authentification';
      if (e.code == 'email-already-in-use') {
        errorMessage = '❌ Cet email est déjà utilisé.';
      } else if (e.code == 'weak-password') {
        errorMessage = '❌ Mot de passe trop faible.';
      } else if (e.code == 'invalid-email') {
        errorMessage = '❌ Email invalide.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on FirebaseException catch (e) {
      print('❌ ERREUR FIREBASE : ${e.code} - ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur Firebase : ${e.message}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e, stackTrace) {
      print('❌ ERREUR INCONNUE : $e');
      print('Stack trace : $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur : ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && _obscurePassword,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF1F2937),
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 14,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.only(right: 12),
            child: Icon(
              icon,
              color: const Color(0xFF4F46E5),
              size: 22,
            ),
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: const Color(0xFF9CA3AF),
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF4F46E5),
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildPhotoSection() {
    return GestureDetector(
      onTap: _prendrePhoto,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: _photoPrise == null
                ? const Color(0xFFFEF2F2)
                : const Color(0xFFF0F9FF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _photoPrise == null
                  ? const Color(0xFFFECACA)
                  : const Color(0xFFBAE6FD),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: _photoPrise == null
                    ? const Color(0xFFFECACA).withOpacity(0.3)
                    : const Color(0xFFBAE6FD).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_photoPrise != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.file(
                    _photoPrise!,
                    width: 116,
                    height: 116,
                    fit: BoxFit.cover,
                  ),
                ),
              if (_photoPrise == null)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFECACA),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 32,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Scanner',
                      style: TextStyle(
                        color: Color(0xFFDC2626),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              Positioned(
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _photoPrise == null
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF059669),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _photoPrise == null ? 'OBLIGATOIRE' : 'VALIDÉ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Photo
          Center(
            child: Column(
              children: [
                _buildPhotoSection(),
                const SizedBox(height: 8),
                Text(
                  'Reconnaissance faciale requise',
                  style: TextStyle(
                    color: const Color(0xFF6B7280),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Informations personnelles
          const Text(
            'Informations personnelles',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Remplissez vos informations de base',
            style: TextStyle(
              fontSize: 14,
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 20),

          // Champs Nom et Prénom
          Row(
            children: [
              Expanded(
                child: _buildFormField(
                  controller: _nomController,
                  label: 'Nom',
                  icon: Icons.person_rounded,
                  validator: (v) => v!.isEmpty ? 'Ce champ est requis' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFormField(
                  controller: _prenomController,
                  label: 'Prénom',
                  icon: Icons.person_outline_rounded,
                  validator: (v) => v!.isEmpty ? 'Ce champ est requis' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Filière
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('fillieres')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'Aucune filière disponible',
                        style: TextStyle(color: Color(0xFF6B7280)),
                      ),
                    ),
                  );
                }

                List<DropdownMenuItem<String>> filiereItems = snapshot.data!.docs
                    .map((doc) {
                      return DropdownMenuItem(
                        value: doc.id,
                        child: Text(
                          doc['nom'],
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      );
                    })
                    .toList();

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Filière',
                      labelStyle: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 14,
                      ),
                      prefixIcon: Container(
                        margin: const EdgeInsets.only(right: 12),
                        child: const Icon(
                          Icons.school_rounded,
                          color: Color(0xFF4F46E5),
                          size: 22,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF4F46E5),
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                    ),
                    value: _selectedFiliereId,
                    items: filiereItems,
                    onChanged: (value) =>
                        setState(() => _selectedFiliereId = value),
                    validator: (v) =>
                        v == null ? 'Veuillez choisir une filière' : null,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF1F2937),
                    ),
                    dropdownColor: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    icon: const Icon(
                      Icons.arrow_drop_down_rounded,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // Email
          _buildFormField(
            controller: _emailController,
            label: 'Email universitaire',
            icon: Icons.email_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v!.isEmpty) return 'Ce champ est requis';
              if (!v.contains('@') || !v.contains('.')) {
                return 'Format email invalide';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Mot de passe
          _buildFormField(
            controller: _passwordController,
            label: 'Mot de passe',
            icon: Icons.lock_rounded,
            isPassword: true,
            validator: (v) {
              if (v!.isEmpty) return 'Ce champ est requis';
              if (v.length < 6) {
                return 'Minimum 6 caractères';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: Color(0xFF6B7280),
              ),
              const SizedBox(width: 8),
              Text(
                'Minimum 6 caractères',
                style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFF6B7280),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Bouton d'inscription
          SizedBox(
            width: double.infinity,
            child: MouseRegion(
              cursor: _isLoading
                  ? SystemMouseCursors.wait
                  : SystemMouseCursors.click,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isLoading
                        ? [const Color(0xFF9CA3AF), const Color(0xFF9CA3AF)]
                        : [const Color(0xFF10B981), const Color(0xFF34D399)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: _isLoading
                      ? []
                      : [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isLoading)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      else
                        const Icon(
                          Icons.person_add_alt_1_rounded,
                          size: 22,
                        ),
                      const SizedBox(width: 12),
                      Text(
                        _isLoading ? 'Traitement...' : 'Créer mon compte',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Sécurité
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.security_rounded,
                  color: const Color(0xFF4F46E5),
                  size: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Vos données sont sécurisées avec un cryptage de niveau bancaire',
                    style: TextStyle(
                      fontSize: 13,
                      color: const Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}