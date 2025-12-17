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
  String? _userFiliereNom;
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
        String? filiereId;
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final nom = userData['nom'] ?? '';
          final prenom = userData['prenom'] ?? '';
          _userNomComplet = '$nom $prenom';
          filiereId = userData['filiere_id'] as String?;
        }

        // 2. Récupérer le nom de la filière
        if (filiereId != null) {
          final filiereDoc = await _firestore
              .collection('fillieres')
              .doc(filiereId)
              .get();
          if (filiereDoc.exists) {
            final filiereData = filiereDoc.data() as Map<String, dynamic>;
            _userFiliereNom = filiereData['nom'];
          } else {
            _userFiliereNom = null;
          }
        }

        // 3. Charger les statistiques
        await _loadStatistics(filiereId);

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

  Future<void> _loadStatistics(String? filiereId) async {
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
      if (filiereId != null) {
        final coursQuery = await _firestore
            .collection('cours')
            .where('filiere_id', isEqualTo: filiereId)
            .get();

        _totalCours = coursQuery.docs.length;
        print('✅ Total cours: $_totalCours');

        final todayCoursQuery = await _firestore
            .collection('cours')
            .where('filiere_id', isEqualTo: filiereId)
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
      print('   - Filière nom: $_userFiliereNom');
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
      backgroundColor: const Color(0xFFF8FAFF),
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
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildDashboardContent() {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _isLoadingStats = true;
        });
        await _loadUserData(); // Refreshes everything including filiere name
        setState(() {
          _isLoadingStats = false;
        });
      },
      color: const Color(0xFF4F46E5),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête amélioré
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF4F46E5),
                    const Color(0xFF7C73E6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4F46E5).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.dashboard_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tableau de bord',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Bonjour, ${_getUserName()}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_isLoadingStats)
                    LinearProgressIndicator(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                  else
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.update_rounded,
                                size: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Données actualisées',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        if (_userNomComplet != null)
                          Text(
                            _userNomComplet!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Statistiques principales
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildStatCard(
                  title: 'Présences totales',
                  value: _isLoadingStats ? '...' : '$_totalPresences',
                  subtitle: _userNomComplet ?? 'Utilisateur',
                  icon: Icons.check_circle_rounded,
                  color: const Color(0xFF10B981),
                ),
                _buildStatCard(
                  title: "Aujourd'hui",
                  value: _isLoadingStats ? '...' : '$_todayPresences',
                  subtitle: _todayCours > 0
                      ? 'sur $_todayCours cours'
                      : 'Aucun cours',
                  icon: Icons.today_rounded,
                  color: const Color(0xFF3B82F6),
                ),
                _buildStatCard(
                  title: 'Taux de présence',
                  value: _isLoadingStats
                      ? '...'
                      : '${_totalCours > 0 ? ((_totalPresences / _totalCours) * 100).toStringAsFixed(1) : '100'}%',
                  subtitle: _totalCours > 0
                      ? '$_totalPresences/$_totalCours cours'
                      : 'Aucun cours',
                  icon: Icons.percent_rounded,
                  color: const Color(0xFF8B5CF6),
                ),
                _buildStatCard(
                  title: 'Taux du jour',
                  value: _isLoadingStats
                      ? '...'
                      : '${_todayCours > 0 ? ((_todayPresences / _todayCours) * 100).toStringAsFixed(1) : '100'}%',
                  subtitle: _todayCours > 0
                      ? '$_todayPresences/$_todayCours cours'
                      : 'Aucun cours',
                  icon: Icons.calendar_today_rounded,
                  color: const Color(0xFFF59E0B),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Détails des présences
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informations personnelles',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailItem(
                    icon: Icons.person_rounded,
                    label: 'Nom complet',
                    value: _userNomComplet ?? 'Non disponible',
                  ),
                  _buildDetailItem(
                    icon: Icons.school_rounded,
                    label: 'Filière',
                    value: _userFiliereNom ?? 'Non assignée',
                  ),
                  _buildDetailItem(
                    icon: Icons.date_range_rounded,
                    label: 'Date du jour',
                    value: DateFormat('dd/MM/yyyy').format(DateTime.now()),
                  ),
                  if (_totalPresences == 0 && !_isLoadingStats)
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFBBF24),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Vous n\'avez encore pointé aucune présence',
                              style: TextStyle(
                                fontSize: 14,
                                color: const Color(0xFF92400E),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Accès rapide
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Accès rapide',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Accédez rapidement aux fonctionnalités principales',
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          title: 'Voir mon historique',
                          icon: Icons.history_rounded,
                          color: const Color(0xFF3B82F6),
                          onTap: () => _navigateToScreen(1),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildActionButton(
                          title: 'Pointer présence',
                          icon: Icons.camera_alt_rounded,
                          color: const Color(0xFF10B981),
                          onTap: () => _navigateToScreen(2),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Debug info (visible seulement en développement)
            if (!_isLoadingStats)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE5E7EB),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F46E5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.analytics_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Données Firestore',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 20,
                      runSpacing: 12,
                      children: [
                        _buildDebugItem('Présences totales', '$_totalPresences'),
                        _buildDebugItem('Présences aujourd\'hui', '$_todayPresences'),
                        if (_userFiliereNom != null) ...[
                          _buildDebugItem('Cours total', '$_totalCours'),
                          _buildDebugItem('Cours aujourd\'hui', '$_todayCours'),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xFF9CA3AF),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: const Color(0xFF4F46E5),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF1F2937),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              icon: Icons.dashboard_rounded,
              label: 'Dashboard',
              isActive: _currentIndex == 0,
              onTap: () => setState(() => _currentIndex = 0),
            ),
            _buildNavItem(
              icon: Icons.history_rounded,
              label: 'Pointages',
              isActive: _currentIndex == 1,
              onTap: () => setState(() => _currentIndex = 1),
            ),
            _buildNavItem(
              icon: Icons.camera_alt_rounded,
              label: 'Présence',
              isActive: _currentIndex == 2,
              onTap: () => setState(() => _currentIndex = 2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF4F46E5).withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? const Color(0xFF4F46E5) : const Color(0xFF9CA3AF),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? const Color(0xFF4F46E5) : const Color(0xFF9CA3AF),
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
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
        return 'Pointer présence';
      default:
        return 'Dashboard';
    }
  }

  void _handleLogout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/');
  }
}