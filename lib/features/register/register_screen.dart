import 'package:flutter/material.dart';
import 'widgets/register_form.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            foregroundColor: const Color(0xFF1F2937),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF4F46E5).withOpacity(0.9),
                      const Color(0xFF818CF8).withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Opacity(
                        opacity: 0.1,
                        child: Icon(
                          Icons.face_retouching_natural_rounded,
                          size: 200,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Icons.person_add_alt_1_rounded,
                              size: 32,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Rejoignez PresenceConnect',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Portail étudiant sécurisé',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            leading: IconButton(
              icon: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Carte du formulaire
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 600),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Column(
                        children: [
                          // Header de la carte
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFFF8FAFF),
                                  Color(0xFFF0F4FF),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF4F46E5),
                                        Color(0xFF818CF8),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.fingerprint_rounded,
                                    size: 24,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Nouvelle inscription',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1F2937),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Remplissez le formulaire ci-dessous pour créer votre compte',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: const Color(0xFF6B7280)
                                              .withOpacity(0.9),
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Contenu du formulaire
                          Padding(
                            padding: const EdgeInsets.all(32),
                            child: RegisterForm(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Informations complémentaires
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      children: [
                        // Étapes du processus
                        const Text(
                          'Processus d\'inscription',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStep(
                              number: 1,
                              icon: Icons.camera_alt_rounded,
                              title: 'Scan facial',
                              isActive: true,
                            ),
                            Container(
                              height: 1,
                              width: 40,
                              color: const Color(0xFFD1D5DB),
                            ),
                            _buildStep(
                              number: 2,
                              icon: Icons.person_add_rounded,
                              title: 'Informations',
                              isActive: true,
                            ),
                            Container(
                              height: 1,
                              width: 40,
                              color: const Color(0xFFD1D5DB),
                            ),
                            _buildStep(
                              number: 3,
                              icon: Icons.check_circle_rounded,
                              title: 'Validation',
                              isActive: false,
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),

                        // Section sécurité
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F9FF),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFBAE6FD),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF38BDF8),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.shield_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Sécurité des données',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF0C4A6E),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Votre reconnaissance faciale est cryptée et stockée de manière sécurisée. '
                                      'Nous utilisons des algorithmes avancés pour protéger votre identité.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: const Color(0xFF0C4A6E)
                                            .withOpacity(0.8),
                                        fontWeight: FontWeight.w400,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Lien vers la politique
                        TextButton(
                          onPressed: () {
                            // TODO: Naviguer vers la politique de confidentialité
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'En vous inscrivant, vous acceptez nos ',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                              const Text(
                                'conditions d\'utilisation',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF4F46E5),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep({
    required int number,
    required IconData icon,
    required String title,
    required bool isActive,
  }) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF4F46E5)
                : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isActive
                  ? const Color(0xFF4F46E5)
                  : const Color(0xFFD1D5DB),
              width: 2,
            ),
          ),
          child: Icon(
            icon,
            color: isActive ? Colors.white : const Color(0xFF9CA3AF),
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? const Color(0xFF4F46E5) : const Color(0xFF9CA3AF),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF4F46E5)
                : const Color(0xFFF3F4F6),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number.toString(),
              style: TextStyle(
                color: isActive ? Colors.white : const Color(0xFF9CA3AF),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}