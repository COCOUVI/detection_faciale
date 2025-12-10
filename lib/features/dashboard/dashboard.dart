import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:detection_fasciale/features/dashboard/widgets/dashboard_appbar.dart';
import 'package:detection_fasciale/features/dashboard/widgets/dashboard_drawer.dart';
import 'package:detection_fasciale/features/pointage/pointage_screen.dart';
import 'package:detection_fasciale/features/presence/presence_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Variables pour les statistiques
  int _totalPresences = 0;
  int _todayPresences = 0;
  int _totalCours = 0;
  int _todayCours = 0;
  bool _isLoadingStats = true;
  String? _userNomComplet;
  String? _userFiliereId;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _currentUserId = user.uid;

      try {
        // 1. Récupérer les informations utilisateur depuis Firestore
        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final nom = userData['nom'] ?? '';
          final prenom = userData['prenom'] ?? '';
          _userNomComplet = '$nom $prenom';
          _userFiliereId = userData['filiere_id'] as String?;
        }

        // 2. Charger les statistiques
        await _loadStatistics();

        setState(() {
          _isLoadingStats = false;
        });
      } catch (e) {
        print('❌ Erreur chargement données dashboard: $e');
        setState(() {
          _isLoadingStats = false;
        });
      }
    } else {
      setState(() {
        _isLoadingStats = false;
      });
    }
  }

  Future<void> _loadStatistics() async {
    if (_currentUserId == null) return;

    try {
      print('🔄 Chargement des statistiques pour utilisateur: $_currentUserId');

      // 1. COMPTER LES PRÉSENCES TOTALES
      final presencesQuery = await _firestore
          .collection('presences')
          .where('etudiant_id', isEqualTo: _currentUserId)
          .where('is_present', isEqualTo: true)
          .get();

      _totalPresences = presencesQuery.docs.length;
      print('✅ Total présences: $_totalPresences');

      // 2. COMPTER LES PRÉSENCES D'AUJOURD'HUI
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      final todayPresencesQuery = await _firestore
          .collection('presences')
          .where('etudiant_id', isEqualTo: _currentUserId)
          .where('is_present', isEqualTo: true)
          .where(
            'created_at',
            isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart),
          )
          .get();

      _todayPresences = todayPresencesQuery.docs.length;
      print('✅ Présences aujourd\'hui: $_todayPresences');

      // 3. COMPTER LES COURS SI L'UTILISATEUR A UNE FILIÈRE
      if (_userFiliereId != null) {
        final coursQuery = await _firestore
            .collection('cours')
            .where('filiere_id', isEqualTo: _userFiliereId)
            .get();

        _totalCours = coursQuery.docs.length;
        print('✅ Total cours: $_totalCours');

        final todayCoursQuery = await _firestore
            .collection('cours')
            .where('filiere_id', isEqualTo: _userFiliereId)
            .where(
              'heure_debut',
              isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart),
            )
            .get();

        _todayCours = todayCoursQuery.docs.length;
        print('✅ Cours aujourd\'hui: $_todayCours');
      }

      // 4. AFFICHER LES DONNÉES BRUTES POUR DÉBOGAGE
      print('📊 STATISTIQUES FINALES:');
      print('   - ID Utilisateur: $_currentUserId');
      print('   - Filière ID: $_userFiliereId');
      print('   - Total présences: $_totalPresences');
      print('   - Présences aujourd\'hui: $_todayPresences');
      print('   - Total cours: $_totalCours');
      print('   - Cours aujourd\'hui: $_todayCours');
    } catch (e) {
      print('❌ Erreur chargement statistiques: $e');
    }
  }

  String _getUserName() {
    if (_userNomComplet != null && _userNomComplet!.isNotEmpty) {
      return _userNomComplet!;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return "Utilisateur";

    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!;
    }

    if (user.email != null) {
      return user.email!.split('@')[0];
    }

    return "Utilisateur";
  }

  @override
  Widget build(BuildContext context) {
    final userName = _getUserName();

    return Scaffold(
      appBar: DashboardAppBar(
        title: _getTitle(),
        userName: userName,
        onMenuPressed: () => Scaffold.of(context).openDrawer(),
      ),
      drawer: DashboardDrawer(
        userName: userName,
        onLogout: _handleLogout,
        onPointage: () => _navigateToScreen(1),
        onPresence: () => _navigateToScreen(2),
        onDashboard: () => _navigateToScreen(0),
        currentIndex: _currentIndex,
      ),
      body: _currentIndex == 0
          ? _buildDashboardContent()
          : _getScreen(_currentIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Tableau de bord',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Mes pointages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'Présence',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _isLoadingStats = true;
        });
        await _loadStatistics();
        setState(() {
          _isLoadingStats = false;
        });
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Vos statistiques de présence',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_isLoadingStats)
                      const LinearProgressIndicator()
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Données actualisées',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.green[600],
                            ),
                          ),
                          const SizedBox(height: 5),
                          if (_currentUserId != null)
                            Text(
                              'ID: ${_currentUserId!.substring(0, 8)}...',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Statistiques principales
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Présences totales',
                    value: _isLoadingStats ? '...' : '$_totalPresences',
                    subtitle: _currentUserId != null
                        ? 'Pour cet utilisateur'
                        : 'Non connecté',
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard(
                    title: "Aujourd'hui",
                    value: _isLoadingStats ? '...' : '$_todayPresences',
                    subtitle: _todayCours > 0
                        ? 'sur $_todayCours cours'
                        : 'Aucun cours',
                    icon: Icons.today,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Taux de présence',
                    value: _isLoadingStats
                        ? '...'
                        : '${_totalCours > 0 ? ((_totalPresences / _totalCours) * 100).toStringAsFixed(1) : '100'}%',
                    subtitle: _totalCours > 0
                        ? '$_totalPresences/$_totalCours cours'
                        : 'Aucun cours',
                    icon: Icons.percent,
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard(
                    title: 'Taux du jour',
                    value: _isLoadingStats
                        ? '...'
                        : '${_todayCours > 0 ? ((_todayPresences / _todayCours) * 100).toStringAsFixed(1) : '100'}%',
                    subtitle: _todayCours > 0
                        ? '$_todayPresences/$_todayCours cours'
                        : 'Aucun cours',
                    icon: Icons.calendar_today,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Détails des présences
            if (!_isLoadingStats && _totalPresences > 0)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Détails de vos présences',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildDetailItem(
                        icon: Icons.person,
                        label: 'ID Utilisateur',
                        value: _currentUserId != null
                            ? '${_currentUserId!.substring(0, 12)}...'
                            : 'Non disponible',
                      ),
                      _buildDetailItem(
                        icon: Icons.school,
                        label: 'Filière',
                        value: _userFiliereId != null
                            ? '${_userFiliereId!.substring(0, 8)}...'
                            : 'Non assignée',
                      ),
                      _buildDetailItem(
                        icon: Icons.date_range,
                        label: 'Date du jour',
                        value: DateFormat('dd/MM/yyyy').format(DateTime.now()),
                      ),
                      if (_totalPresences == 0)
                        Container(
                          margin: const EdgeInsets.only(top: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange[200]!),
                          ),
                          child: const Text(
                            '⚠️ Vous n\'avez encore pointé aucune présence',
                            style: TextStyle(color: Colors.orange),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            // Bouton pour voir l'historique
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Accès rapide',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _navigateToScreen(1),
                            icon: const Icon(Icons.history),
                            label: const Text('Voir mon historique'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _navigateToScreen(2),
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Pointer présence'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Debug info (visible seulement en développement)
            if (!_isLoadingStats)
              Card(
                color: Colors.grey[100],
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📊 Données Firestore',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Présences totales: $_totalPresences',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        'Présences aujourd\'hui: $_todayPresences',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      if (_userFiliereId != null) ...[
                        Text(
                          'Cours total: $_totalCours',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          'Cours aujourd\'hui: $_todayCours',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _getScreen(int index) {
    switch (index) {
      case 1:
        return const PointageScreen();
      case 2:
        return const PresenceScreen();
      default:
        return const SizedBox();
    }
  }

  void _navigateToScreen(int index) {
    Navigator.pop(context);
    setState(() => _currentIndex = index);
  }

  String _getTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Tableau de bord';
      case 1:
        return 'Mes pointages';
      case 2:
        return 'Effectuer une présence';
      default:
        return 'Dashboard';
    }
  }

  void _handleLogout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/');
  }
}
