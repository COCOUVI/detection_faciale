import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PointageScreen extends StatefulWidget {
  const PointageScreen({Key? key}) : super(key: key);

  @override
  State<PointageScreen> createState() => _PointageScreenState();
}

class _PointageScreenState extends State<PointageScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _etudiantId;

  @override
  void initState() {
    super.initState();
    _loadEtudiantId();
  }

  Future<void> _loadEtudiantId() async {
    // TODO: Récupérer l'ID de l'étudiant connecté
    // Exemple: depuis SharedPreferences, Provider, Firebase Auth, etc.
    setState(() {
      _etudiantId =
          "w5Z7syKWfVRC0Hm4bKJzIWoIciY2"; // À remplacer par la vraie méthode
    });
  }

  // Fonction pour récupérer les pointages
  Stream<QuerySnapshot> _getPointagesStream() {
    if (_etudiantId == null) {
      return const Stream.empty();
    }

    try {
      return _firestore
          .collection('presences')
          .where('etudiant_id', isEqualTo: _etudiantId)
          .orderBy('heure_debut', descending: true)
          .snapshots();
    } catch (e) {
      print("Exception: $e");
      return const Stream.empty();
    }
  }

  // Formater la date
  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Aujourd\'hui';
    } else if (dateOnly == yesterday) {
      return 'Hier';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  // Formater l'heure
  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '--:--';
    return DateFormat('HH:mm').format(timestamp.toDate());
  }

  // Déterminer le statut
  String _getStatus(Map<String, dynamic> data) {
    if (data['is_present'] == false) {
      return 'Absent';
    }

    return 'Présent';
  }

  // Couleur selon le statut
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Présent':
        return Colors.green;
      case 'Absent':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Icône selon le statut
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Présent':
        return Icons.check_circle;
      case 'Absent':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_etudiantId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mes pointages',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Historique de vos présences',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),

            // Liste des pointages
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getPointagesStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 50),
                          const SizedBox(height: 20),
                          Text(
                            'Erreur: ${snapshot.error}',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 64, color: Colors.grey),
                          SizedBox(height: 20),
                          Text(
                            'Aucun pointage trouvé',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  final pointages = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: pointages.length,
                    itemBuilder: (context, index) {
                      final data =
                          pointages[index].data() as Map<String, dynamic>;
                      final status = _getStatus(data);

                      return _buildPointageCard(data, status);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointageCard(Map<String, dynamic> data, String status) {
    final heureDebut = data['heure_debut'] as Timestamp?;
    final heureFin = data['heure_fin'] as Timestamp?;
    final nomCours = data['nom_cours'] ?? 'Cours';
    final salle = data['salle'] ?? 'Salle non spécifiée';

    final color = _getStatusColor(status);
    final icon = _getStatusIcon(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec cours et statut
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nomCours,
                        style:  TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.indigo.shade800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Salle: $salle',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: color,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 16,
                        color: color,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        status,
                        style: TextStyle(
                          color: color,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Date et heures
            if (heureDebut != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 18,
                          color: Colors.indigo.shade600,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _formatDate(heureDebut),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 18,
                          color: Colors.indigo.shade600,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Arrivée',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatTime(heureDebut),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                height: 40,
                                width: 1,
                                color: Colors.grey.shade300,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Départ',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatTime(heureFin),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}