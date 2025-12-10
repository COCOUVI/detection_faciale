import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:intl/intl.dart';

class PresenceScreen extends StatefulWidget {
  const PresenceScreen({Key? key}) : super(key: key);

  @override
  _PresenceScreenState createState() => _PresenceScreenState();
}

class _PresenceScreenState extends State<PresenceScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: false,
      enableLandmarks: true,
      enableClassification: true,
      minFaceSize: 0.15,
      enableTracking: true,
    ),
  );

  // CONSTANTES POUR LES SEUILS
  static const double RECOGNITION_THRESHOLD =
      0.7; // 70% pour reconnaître l'utilisateur
  static const double DUPLICATE_THRESHOLD =
      0.85; // 85% pour détecter les doublons

  bool _isScanning = false;
  bool _presenceMarked = false;
  String _currentCourseId = '';
  String _currentCourseName = '';
  String _errorMessage = '';
  String? _currentUserId;
  String? _userFiliereId;
  List<Map<String, dynamic>> _todayCourses = [];
  bool _isLoading = true;
  File? _scannedPhoto;
  List<double>? _userEmbedding;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _faceDetector.close();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() => _currentUserId = user.uid);
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        _userFiliereId = userData['filiere_id'] as String?;

        if (userData['embedding'] != null) {
          _userEmbedding = List<double>.from(userData['embedding']);
          print('Embedding chargé: ${_userEmbedding!.length} dimensions');
        } else {
          print('Aucun embedding trouvé pour l\'utilisateur');
        }

        await _loadTodayCourses();
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadTodayCourses() async {
    if (_userFiliereId == null) return;

    final now = DateTime.now();

    try {
      final querySnapshot = await _firestore
          .collection('cours')
          .where('filiere_id', isEqualTo: _userFiliereId)
          .get();

      final courses = <Map<String, dynamic>>[];

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        try {
          if (data['heure_debut'] != null && data['heure_fin'] != null) {
            final heureDebut = (data['heure_debut'] as Timestamp).toDate();
            final heureFin = (data['heure_fin'] as Timestamp).toDate();

            if (_isCourseRelevantForDemo(heureDebut, heureFin, now)) {
              courses.add({
                'id': doc.id,
                'cours_id': doc.id,
                'nom_cours': data['nom_cours'] ?? '',
                'heure_debut': heureDebut,
                'heure_fin': heureFin,
                'salle': data['salle'] ?? '',
                'filiere_id': data['filiere_id'] ?? _userFiliereId,
                'is_now': _isCourseCurrent(heureDebut, heureFin, now),
              });
            }
          }
        } catch (e) {
          print('Erreur traitement cours ${doc.id}: $e');
        }
      }

      if (courses.isEmpty) {
        _simulateDemoCourse();
        return;
      }

      courses.sort(
        (a, b) => (a['heure_debut'] as DateTime).compareTo(
          (b['heure_debut'] as DateTime),
        ),
      );

      setState(() => _todayCourses = courses);
      await _checkCurrentCourse();
    } catch (e) {
      print('Erreur chargement cours: $e');
      _simulateDemoCourse();
    }
  }

  bool _isCourseRelevantForDemo(
    DateTime heureDebut,
    DateTime heureFin,
    DateTime now,
  ) {
    final isToday =
        heureDebut.year == now.year &&
        heureDebut.month == now.month &&
        heureDebut.day == now.day;
    final isWithin24Hours = heureDebut.isBefore(
      now.add(const Duration(days: 1)),
    );
    final is2025Course = heureDebut.year == 2025;
    return isToday || isWithin24Hours || is2025Course;
  }

  bool _isCourseCurrent(DateTime heureDebut, DateTime heureFin, DateTime now) {
    final startWindow = heureDebut.subtract(const Duration(minutes: 60));
    final endWindow = heureFin.add(const Duration(minutes: 60));
    return now.isAfter(startWindow) && now.isBefore(endWindow);
  }

  void _simulateDemoCourse() {
    final now = DateTime.now();
    final demoCourse = {
      'id': 'demo_course_java',
      'cours_id': 'FWzyLBcO6ne6tHdHRlqR',
      'nom_cours': 'Programmation Java (Démo)',
      'heure_debut': now.subtract(const Duration(minutes: 45)),
      'heure_fin': now.add(const Duration(hours: 1, minutes: 15)),
      'salle': 'B204',
      'filiere_id': _userFiliereId ?? '',
      'is_now': true,
    };

    setState(() {
      _todayCourses = [demoCourse];
      _errorMessage = 'Mode démonstration - Cours simulé pour la présentation';
    });

    _checkCurrentCourse();
  }

  Future<void> _checkCurrentCourse() async {
    final now = DateTime.now();

    if (_todayCourses.isEmpty) {
      setState(() => _errorMessage = 'Aucun cours disponible');
      return;
    }

    for (var course in _todayCourses) {
      final heureDebut = course['heure_debut'] as DateTime;
      final heureFin = course['heure_fin'] as DateTime;

      if (_isCourseCurrent(heureDebut, heureFin, now)) {
        setState(() {
          _currentCourseId = course['cours_id'];
          _currentCourseName = course['nom_cours'];
          _errorMessage = course['is_now'] ? '' : 'Cours bientôt terminé';
        });
        await _checkIfPresenceAlreadyMarked();
        return;
      }
    }

    final firstCourse = _todayCourses.first;
    setState(() {
      _currentCourseId = firstCourse['cours_id'];
      _currentCourseName = firstCourse['nom_cours'];
      _errorMessage =
          'Prochain cours: ${DateFormat('HH:mm').format(firstCourse['heure_debut'])}';
    });
    await _checkIfPresenceAlreadyMarked();
  }

  Future<void> _checkIfPresenceAlreadyMarked() async {
    if (_currentCourseId.isEmpty || _currentUserId == null) return;

    try {
      final presenceQuery = await _firestore
          .collection('presences')
          .where('cours_id', isEqualTo: _currentCourseId)
          .where('etudiant_id', isEqualTo: _currentUserId)
          .get();

      if (presenceQuery.docs.isNotEmpty) {
        setState(() {
          _presenceMarked = true;
          _errorMessage = 'Vous avez déjà marqué votre présence pour ce cours';
        });
      } else {
        setState(() {
          _presenceMarked = false;
        });
      }
    } catch (e) {
      print('Erreur vérification présence: $e');
    }
  }

  // ----------------- FACE EMBEDDING -----------------
  Future<List<double>?> _extraireEmbedding(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        _showSnackBar('Aucun visage détecté');
        return null;
      }
      if (faces.length > 1) {
        _showSnackBar('Plusieurs visages détectés');
        return null;
      }

      final face = faces.first;
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

      return normalizedLandmarks;
    } catch (e) {
      print('Erreur embedding : $e');
      _showSnackBar('Erreur lors de l\'analyse du visage');
      return null;
    }
  }

  double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) {
      print('Erreur: dimensions différentes (${a.length} vs ${b.length})');
      return 0.0;
    }

    double dot = 0.0, na = 0.0, nb = 0.0;
    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      na += a[i] * a[i];
      nb += b[i] * b[i];
    }
    if (na == 0.0 || nb == 0.0) return 0.0;
    return dot / (sqrt(na) * sqrt(nb));
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.orange),
      );
    }
  }

  // Vérifier si un autre utilisateur a le même embedding
  Future<bool> _checkForDuplicateEmbedding(
    List<double> currentEmbedding,
  ) async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();

      for (var userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        if (userData['embedding'] != null && userDoc.id != _currentUserId) {
          final otherEmbedding = List<double>.from(userData['embedding']);

          final similarity = _cosineSimilarity(
            currentEmbedding,
            otherEmbedding,
          );

          // CHANGEMENT ICI : 85% au lieu de 70%
          if (similarity > DUPLICATE_THRESHOLD) {
            print('Doublon potentiel détecté avec utilisateur: ${userDoc.id}');
            print(
              'Similarité: ${similarity.toStringAsFixed(3)} (seuil: ${DUPLICATE_THRESHOLD * 100}%)',
            );
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      print('Erreur vérification doublon embedding: $e');
      return false;
    }
  }

  // ----------------- SCAN & VERIFY -----------------
  Future<void> _startScan() async {
    if (_currentCourseId.isEmpty) {
      setState(() => _errorMessage = 'Veuillez sélectionner un cours');
      return;
    }
    if (_presenceMarked) {
      setState(() => _errorMessage = 'Présence déjà marquée pour ce cours');
      return;
    }
    if (_userEmbedding == null) {
      setState(
        () => _errorMessage =
            'Aucun profil facial enregistré. Veuillez d\'abord enregistrer votre visage.',
      );
      return;
    }

    setState(() {
      _isScanning = true;
      _errorMessage = '';
    });

    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 70,
      );

      if (picked == null) {
        setState(() {
          _isScanning = false;
          _errorMessage = 'Scan annulé';
        });
        return;
      }

      _scannedPhoto = File(picked.path);

      final embeddingScan = await _extraireEmbedding(_scannedPhoto!);
      if (embeddingScan == null) {
        setState(() => _isScanning = false);
        return;
      }

      print('Embedding scanné: ${embeddingScan.length} dimensions');

      final isDuplicate = await _checkForDuplicateEmbedding(embeddingScan);
      if (isDuplicate) {
        setState(() {
          _isScanning = false;
          _errorMessage = 'Cette personne a déjà un compte dans le système';
        });
        return;
      }

      final similarity = _cosineSimilarity(_userEmbedding!, embeddingScan);
      print(
        'Similarité avec embedding utilisateur: ${similarity.toStringAsFixed(3)}',
      );
      print('Seuil de reconnaissance: ${RECOGNITION_THRESHOLD * 100}%');

      // CHANGEMENT ICI : 70% au lieu de 55%
      if (similarity < RECOGNITION_THRESHOLD) {
        setState(() {
          _isScanning = false;
          _errorMessage =
              'Visage non reconnu (similarité ${(similarity * 100).toStringAsFixed(1)}% - minimum ${(RECOGNITION_THRESHOLD * 100).toInt()}%)';
        });
        return;
      }

      final presenceQuery = await _firestore
          .collection('presences')
          .where('cours_id', isEqualTo: _currentCourseId)
          .where('etudiant_id', isEqualTo: _currentUserId)
          .limit(1)
          .get();

      if (presenceQuery.docs.isNotEmpty) {
        setState(() {
          _presenceMarked = true;
          _isScanning = false;
          _errorMessage = 'Vous avez déjà marqué votre présence pour ce cours';
        });
        return;
      }

      final course = _todayCourses.firstWhere(
        (c) => c['cours_id'] == _currentCourseId,
        orElse: () => _todayCourses.isNotEmpty ? _todayCourses.first : {},
      );

      final userDocRef = _firestore.collection('users').doc(_currentUserId);
      final userSnapshot = await userDocRef.get();
      final userData = userSnapshot.data()!;

      await _firestore.collection('presences').add({
        'cours_id': _currentCourseId,
        'etudiant_id': _currentUserId,
        'nom': userData['nom'] ?? '',
        'prenom': userData['prenom'] ?? '',
        'email': userData['email'] ?? '',
        'description': userData['description'] ?? '',
        'filiere_id': course['filiere_id'] ?? userData['filiere_id'] ?? '',
        'nom_cours': course['nom_cours'] ?? _currentCourseName,
        'salle': course['salle'] ?? '',
        'heure_debut': course['heure_debut'] ?? FieldValue.serverTimestamp(),
        'heure_fin': course['heure_fin'] ?? FieldValue.serverTimestamp(),
        'is_present': true,
        'created_at': FieldValue.serverTimestamp(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'embedding_similarity': similarity,
      });

      setState(() {
        _isScanning = false;
        _presenceMarked = true;
        _errorMessage = '';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Présence enregistrée avec succès ! (${(similarity * 100).toStringAsFixed(1)}% de correspondance)',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Erreur scan: $e');
      setState(() {
        _isScanning = false;
        _errorMessage = 'Erreur lors du scan: ${e.toString()}';
      });
    }
  }

  // ----------------- BUILD UI -----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marquer présence'),
        backgroundColor: Colors.indigo,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentCourseName.isNotEmpty
                                ? 'Cours: $_currentCourseName'
                                : 'Sélectionnez un cours',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_userEmbedding == null)
                            Text(
                              '⚠️ Aucun profil facial enregistré',
                              style: TextStyle(
                                color: Colors.orange[800],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          if (_errorMessage.isNotEmpty)
                            Text(
                              _errorMessage,
                              style: TextStyle(
                                color:
                                    _errorMessage.toLowerCase().contains('dém')
                                    ? Colors.blue
                                    : _errorMessage.toLowerCase().contains(
                                        'succès',
                                      )
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                            ),
                          if (_currentCourseId.isNotEmpty &&
                              _userEmbedding != null)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.indigo.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Seuil de reconnaissance: ${(RECOGNITION_THRESHOLD * 100).toInt()}%',
                                style: TextStyle(
                                  color: Colors.indigo[800],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_todayCourses.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cours disponibles:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._todayCourses.map((course) {
                          final heureDebut = course['heure_debut'] as DateTime;
                          final heureFin = course['heure_fin'] as DateTime;
                          final isCurrent =
                              course['cours_id'] == _currentCourseId;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            color: isCurrent
                                ? Colors.indigo.withOpacity(0.1)
                                : null,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    course['nom_cours'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isCurrent
                                          ? Colors.indigo
                                          : Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${DateFormat('HH:mm').format(heureDebut)} - ${DateFormat('HH:mm').format(heureFin)}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    'Salle: ${course['salle']}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  if (isCurrent && _presenceMarked)
                                    const Padding(
                                      padding: EdgeInsets.only(top: 8),
                                      child: Text(
                                        '✓ Présence déjà marquée',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  const SizedBox(height: 24),

                  Card(
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Container(
                            height: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _userEmbedding == null
                                    ? Colors.orange
                                    : Colors.indigo.shade300,
                                width: 2,
                              ),
                              color: Colors.grey[50],
                            ),
                            child: _isScanning
                                ? const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.indigo,
                                              ),
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          'Analyse faciale en cours...',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Vérification contre la base de données',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  )
                                : _presenceMarked
                                ? const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                         MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.verified,
                                          color: Colors.green,
                                          size: 60,
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          'Présence validée',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _userEmbedding == null
                                              ? Icons.warning
                                              : Icons.face,
                                          size: 60,
                                          color: _userEmbedding == null
                                              ? Colors.orange
                                              : Colors.indigo.shade400,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          _userEmbedding == null
                                              ? 'Profil facial non enregistré'
                                              : 'Zone de reconnaissance',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: _userEmbedding == null
                                                ? Colors.orange[800]
                                                : Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _currentCourseName.isEmpty
                                              ? 'Sélectionnez un cours'
                                              : _currentCourseName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 16),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  (_isScanning ||
                                      _presenceMarked ||
                                      _currentCourseId.isEmpty ||
                                      _userEmbedding == null)
                                  ? null
                                  : _startScan,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _userEmbedding == null
                                    ? Colors.grey
                                    : Colors.indigo,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: _isScanning
                                  ? const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        Text('Analyse en cours...'),
                                      ],
                                    )
                                  : Text(
                                      _userEmbedding == null
                                          ? 'Profil facial requis'
                                          : _presenceMarked
                                          ? 'Présence déjà enregistrée'
                                          : 'Scanner mon visage',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.access_time, color: Colors.indigo),
                        const SizedBox(width: 10),
                        StreamBuilder(
                          stream: Stream.periodic(const Duration(seconds: 1)),
                          builder: (context, snapshot) {
                            return Text(
                              DateFormat('HH:mm:ss').format(DateTime.now()),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 10),
                        Text(
                          DateFormat('dd/MM/yyyy').format(DateTime.now()),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
