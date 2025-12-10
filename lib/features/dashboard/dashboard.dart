import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // IMPORT IMPORTANT
import 'package:detection_fasciale/features/dashboard/widgets/dashboard_appbar.dart';
import 'package:detection_fasciale/features/dashboard/widgets/dashboard_drawer.dart';
import 'package:detection_fasciale/features/pointage/pointage_screen.dart';
import 'package:detection_fasciale/features/presence/presence_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key})
    : super(key: key); // Enlève le paramètre userName

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  // Fonction pour récupérer le nom depuis Firebase
  String _getUserName() {
    final user =
        FirebaseAuth.instance.currentUser; // Récupère l'utilisateur connecté

    if (user == null) return "Utilisateur";

    // 1. Essaie de récupérer le displayName
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!;
    }

    // 2. Sinon utilise l'email (partie avant @)
    if (user.email != null) {
      return user.email!.split('@')[0];
    }

    // 3. Fallback par défaut
    return "Utilisateur";
  }

  // Les écrans du dashboard
  final List<Widget> _screens = [
    _buildHomeDashboard(),
    const PointageScreen(),
    const PresenceScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final userName = _getUserName(); // Appelle la fonction pour obtenir le nom

    return Scaffold(
      appBar: DashboardAppBar(
        title: _getTitle(),
        userName: userName, // Passe le nom récupéré
        onMenuPressed: () => Scaffold.of(context).openDrawer(),
      ),
      drawer: DashboardDrawer(
        userName: userName, // Passe le nom récupéré
        onLogout: _handleLogout,
        onPointage: () => _navigateToScreen(1),
        onPresence: () => _navigateToScreen(2),
        onDashboard: () => _navigateToScreen(0),
        currentIndex: _currentIndex,
      ),
      body: _screens[_currentIndex],
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

  void _navigateToScreen(int index) {
    Navigator.pop(context); // Ferme le drawer
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
    await FirebaseAuth.instance.signOut(); // Déconnexion Firebase
    Navigator.pushReplacementNamed(context, '/');
  }

  static Widget _buildHomeDashboard() {
    return Padding(
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
                    'Bienvenue sur PresenceConnect',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Système de gestion de présence par reconnaissance faciale',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Statistiques rapides
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Présences aujourd\'hui',
                  value: '24',
                  icon: Icons.person,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  title: 'Retards',
                  value: '3',
                  icon: Icons.access_time,
                  color: Colors.orange,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Actions rapides
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Actions rapides',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildQuickAction(
                        icon: Icons.camera_alt,
                        label: 'Marquer présence',
                        color: Colors.blue,
                        onTap: () {},
                      ),
                      _buildQuickAction(
                        icon: Icons.history,
                        label: 'Historique',
                        color: Colors.purple,
                        onTap: () {},
                      ),
                      _buildQuickAction(
                        icon: Icons.settings,
                        label: 'Paramètres',
                        color: Colors.grey,
                        onTap: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildStatCard({
    required String title,
    required String value,
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
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(50),
          child: CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            radius: 30,
            child: Icon(icon, color: color, size: 30),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
      ],
    );
  }
}
