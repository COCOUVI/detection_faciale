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
      width: 280,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            // En-tête du drawer
            Container(
              height: 220,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF4F46E5),
                    const Color(0xFF7C73E6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Étudiant',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Section menu
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            _buildDrawerItem(
                              icon: Icons.dashboard_rounded,
                              title: 'Tableau de bord',
                              isSelected: currentIndex == 0,
                              onTap: onDashboard,
                            ),
                            const SizedBox(height: 4),
                            _buildDrawerItem(
                              icon: Icons.history_rounded,
                              title: 'Mes pointages',
                              isSelected: currentIndex == 1,
                              onTap: onPointage,
                            ),
                            const SizedBox(height: 4),
                            _buildDrawerItem(
                              icon: Icons.camera_alt_rounded,
                              title: 'Effectuer une présence',
                              isSelected: currentIndex == 2,
                              onTap: onPresence,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                      Container(
                        height: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        color: Colors.grey.withOpacity(0.1),
                      ),
                      const SizedBox(height: 20),

                      // Section paramètres
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            _buildDrawerItem(
                              icon: Icons.settings_rounded,
                              title: 'Paramètres',
                              isSelected: false,
                              onTap: () {},
                            ),
                            const SizedBox(height: 4),
                            _buildDrawerItem(
                              icon: Icons.help_outline_rounded,
                              title: 'Aide & Support',
                              isSelected: false,
                              onTap: () {},
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                      Container(
                        height: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        color: Colors.grey.withOpacity(0.1),
                      ),
                      const SizedBox(height: 20),

                      // Déconnexion
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildDrawerItem(
                          icon: Icons.logout_rounded,
                          title: 'Déconnexion',
                          isSelected: false,
                          onTap: onLogout,
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF4F46E5),
                              Color(0xFF7C73E6),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.security_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Session sécurisée',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'PresenceConnect v1.0.0',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '© 2024 Tous droits réservés',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
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
    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF4F46E5).withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(
                color: const Color(0xFF4F46E5).withOpacity(0.3),
                width: 1,
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color ??
                        (isSelected
                            ? const Color(0xFF4F46E5)
                            : Colors.grey.withOpacity(0.1)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: color != null
                        ? Colors.white
                        : (isSelected
                            ? Colors.white
                            : const Color(0xFF6B7280)),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: color ??
                          (isSelected
                              ? const Color(0xFF4F46E5)
                              : const Color(0xFF1F2937)),
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4F46E5),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}