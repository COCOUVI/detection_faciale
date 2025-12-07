import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

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
  String? _selectedFiliereId; // Pour stocker l'ID de la filière choisie
  File? _photoPrise;
  bool _isLoading = false;

  // Fonction Caméra
  Future<void> _prendrePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front, // Selfie
      imageQuality: 50, // On réduit un peu la qualité pour alléger
    );

    if (pickedFile != null) {
      setState(() => _photoPrise = File(pickedFile.path));
    }
  }

  // Fonction Inscription
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Validation manuelle du Scan
    if (_photoPrise == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Le scan du visage est OBLIGATOIRE.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Création Auth (Email/Pass)
      UserCredential userCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      String uid = userCred.user!.uid;

      // 2. Création Firestore (Données)
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'id': uid,
        'nom': _nomController.text.trim().toUpperCase(),
        'prenom': _prenomController.text.trim(),
        'email': _emailController.text.trim(),
        'role': 'etudiant',
        'filiere_id': _selectedFiliereId, // L'ID sélectionné dans la liste
        'photo_url': "", // TODO: Upload Storage plus tard
        'embedding': [], // TODO: IA
        'created_at': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Bienvenue sur PresenceConnect !')),
        );
        // Vider le formulaire
        _formKey.currentState!.reset();
        setState(() {
          _photoPrise = null;
          _selectedFiliereId = null;
        });
      }

    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? "Erreur")));
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
          // --- SCAN VISAGE ---
          GestureDetector(
            onTap: _prendrePhoto,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: _photoPrise == null ? Colors.red[100] : Colors.green[100],
                  backgroundImage: _photoPrise != null ? FileImage(_photoPrise!) : null,
                  child: _photoPrise == null
                      ? const Icon(Icons.camera_alt, size: 30, color: Colors.red)
                      : null,
                ),
                const SizedBox(height: 5),
                Text(
                  _photoPrise == null ? "Appuyer pour scanner *" : "Visage scanné !",
                  style: TextStyle(
                    color: _photoPrise == null ? Colors.red : Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // --- CHAMPS ---
          TextFormField(
            controller: _nomController,
            decoration: const InputDecoration(labelText: 'Nom', prefixIcon: Icon(Icons.person)),
            validator: (v) => v!.isEmpty ? 'Requis' : null,
          ),
          const SizedBox(height: 10),
          
          TextFormField(
            controller: _prenomController,
            decoration: const InputDecoration(labelText: 'Prénom', prefixIcon: Icon(Icons.person_outline)),
            validator: (v) => v!.isEmpty ? 'Requis' : null,
          ),
          const SizedBox(height: 10),

          // --- LISTE DÉROULANTE (FILIÈRES DEPUIS FIREBASE) ---
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('fillieres').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: LinearProgressIndicator());
              }
              
              // On transforme les documents Firebase en liste d'items pour le menu
              List<DropdownMenuItem<String>> filiereItems = snapshot.data!.docs.map((doc) {
                return DropdownMenuItem(
                  value: doc.id, // Ce qu'on stocke (l'ID)
                  child: Text(doc['nom']), // Ce qu'on affiche (le Nom)
                );
              }).toList();

              return DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Filière', 
                  prefixIcon: Icon(Icons.school),
                  border: OutlineInputBorder()
                ),
                value: _selectedFiliereId,
                items: filiereItems,
                onChanged: (value) => setState(() => _selectedFiliereId = value),
                validator: (v) => v == null ? 'Veuillez choisir une filière' : null,
              );
            },
          ),
          const SizedBox(height: 10),

          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
            validator: (v) => v!.contains('@') ? null : 'Email invalide',
          ),
          const SizedBox(height: 10),

          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Mot de passe', prefixIcon: Icon(Icons.lock)),
            validator: (v) => v!.length < 6 ? '6 caractères min.' : null,
          ),
          const SizedBox(height: 30),

          // --- BOUTON ---
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
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("CRÉER MON COMPTE", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}