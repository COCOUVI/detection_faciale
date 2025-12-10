import 'package:flutter/material.dart';

class DashboardDrawer extends StatelessWidget {
  final String userName;
  final VoidCallback onLogout;
  final VoidCallback onPointage;
  final VoidCallback onPresence;
  final VoidCallback onDashboard;
  final int currentIndex;

  const DashboardDrawer({
    Key? key,
    required this.userName,
    required this.onLogout,
    required this.onPointage,
    required this.onPresence,
    required this.onDashboard,
    required this.currentIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // En-tête du drawer
            Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.indigo.shade500, Colors.indigo.shade800],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 50, color: Colors.indigo),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Utilisateur',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Section menu
            _buildDrawerItem(
              icon: Icons.dashboard,
              title: 'Tableau de bord',
              isSelected: currentIndex == 0,
              onTap: onDashboard,
            ),

            _buildDrawerItem(
              icon: Icons.history,
              title: 'Mes pointages',
              isSelected: currentIndex == 1,
              onTap: onPointage,
            ),

            _buildDrawerItem(
              icon: Icons.camera_alt,
              title: 'Effectuer une présence',
              isSelected: currentIndex == 2,
              onTap: onPresence,
            ),

            const Divider(),

            // Section paramètres
            _buildDrawerItem(
              icon: Icons.settings,
              title: 'Paramètres',
              isSelected: false,
              onTap: () {},
            ),

            _buildDrawerItem(
              icon: Icons.help,
              title: 'Aide & Support',
              isSelected: false,
              onTap: () {},
            ),

            const Divider(),

            // Déconnexion
            _buildDrawerItem(
              icon: Icons.logout,
              title: 'Déconnexion',
              isSelected: false,
              onTap: onLogout,
              color: Colors.red,
            ),

            const SizedBox(height: 20),

            // Footer
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Version 1.0.0\n© 2024 PresenceConnect',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: color ?? (isSelected ? Colors.indigo : Colors.grey[700]),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? (isSelected ? Colors.indigo : Colors.grey[700]),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Colors.indigo.withOpacity(0.1),
      onTap: onTap,
    );
  }
}
