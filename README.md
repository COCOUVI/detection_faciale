# 📱 Application Mobile de Gestion de Présence par Reconnaissance Faciale

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Cloud-FFCA28?logo=firebase)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

> Solution innovante de gestion automatisée des présences universitaires utilisant la reconnaissance faciale et l'intelligence artificielle embarquée.

---

## 📋 Table des matières

- [À propos](#-à-propos)
- [Fonctionnalités](#-fonctionnalités)
- [Architecture technique](#-architecture-technique)
- [Prérequis](#-prérequis)
- [Installation](#-installation)
- [Configuration](#-configuration)
- [Utilisation](#-utilisation)
- [Sécurité](#-sécurité)
- [Équipe](#-équipe)
- [Licence](#-licence)

---

## 🎯 À propos

Cette application mobile Flutter permet aux établissements universitaires de moderniser et d'automatiser la gestion des présences. Grâce à la reconnaissance faciale embarquée, les étudiants peuvent pointer leur présence de manière sécurisée, rapide et sans contact.

### Contexte académique

- **Projet** : Développement Mobile - Projet de semestre
- **Établissement** : École Nationale d'Économie Appliquée et de Management (ENEAM)
- **Formation** : 3ème année AIP (Analyse et Programmation Informatique)
- **Objectif** : Automatisation de la gestion des présences via IA embarquée

---

## ✨ Fonctionnalités

### 👤 Gestion des utilisateurs
- **Inscription sécurisée** avec capture et validation du visage
- **Authentification biométrique** via reconnaissance faciale
- **Détection anti-doublon** : un visage unique par utilisateur
- **Profil personnalisé** : nom, prénom, filière, photo

### 📚 Gestion de la présence
- **Pointage facial en temps réel** avec validation stricte (seuil de confiance)
- **Affichage dynamique** des cours par filière
- **Historique complet** de tous les pointages
- **Statistiques détaillées** : taux de présence, absences, tendances
- **Synchronisation automatique** avec Firebase

### 🎓 Administration des cours
- Ajout et suppression de cours via interface
- Affectation des créneaux horaires par filière
- Gestion des sessions en temps réel

---

## 🏗 Architecture technique

### Frontend
```
Flutter 3.x (Dart)
├── Material Design
├── Custom Widgets
└── Responsive UI
```

### Backend & Services
```
Firebase Ecosystem
├── Firestore (Base de données NoSQL)
├── Firebase Authentication
└── Cloud Storage

IA & Traitement d'image
├── Google ML Kit (Reconnaissance faciale)
└── Cloudinary (Stockage images)
```

### Flux de données
```
Utilisateur → Flutter App → ML Kit (traitement local)
                         ↓
                    Firebase Auth
                         ↓
                    Firestore DB ← Cloudinary Storage
```

---

## 📦 Prérequis

Avant de commencer, assurez-vous d'avoir installé :

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (version stable)
- [Dart SDK](https://dart.dev/get-dart) (inclus avec Flutter)
- [Android Studio](https://developer.android.com/studio) ou [VS Code](https://code.visualstudio.com/)
- Un compte [Firebase](https://firebase.google.com/) avec projet configuré
- Un compte [Cloudinary](https://cloudinary.com/) pour le stockage d'images
- Un appareil physique (recommandé) ou émulateur Android/iOS

### Vérification de l'installation
```bash
flutter doctor -v
```

---

## 🚀 Installation

### 1. Cloner le dépôt
```bash
git clone https://github.com/COCOUVI/detection_faciale.git
cd detection_faciale
```

### 2. Installer les dépendances
```bash
flutter pub get
```

### 3. Vérifier les packages
```bash
flutter pub outdated
```

---

## ⚙️ Configuration

### Firebase

#### Android
1. Téléchargez `google-services.json` depuis la console Firebase
2. Placez-le dans `android/app/`

#### iOS
1. Téléchargez `GoogleService-Info.plist` depuis la console Firebase
2. Placez-le dans `ios/Runner/`

### Cloudinary

Éditez le fichier `lib/services/cloudinary_service.dart` :

```dart
class CloudinaryService {
  static const String cloudName = 'VOTRE_CLOUD_NAME';
  static const String apiKey = 'VOTRE_API_KEY';
  static const String apiSecret = 'VOTRE_API_SECRET';
  static const String uploadPreset = 'VOTRE_UPLOAD_PRESET';
}
```

### Structure de la base Firestore

```
users/
  └── {userId}/
      ├── nom: string
      ├── prenom: string
      ├── filiere: string
      ├── faceEmbedding: array
      └── photoUrl: string

cours/
  └── {coursId}/
      ├── nom: string
      ├── filiere: string
      ├── horaire: timestamp
      └── duree: number

presences/
  └── {presenceId}/
      ├── userId: string
      ├── coursId: string
      ├── timestamp: timestamp
      └── score: number
```

---

## 💻 Utilisation

### Démarrage de l'application

```bash
# Mode debug
flutter run

# Mode release
flutter run --release

# Spécifier un appareil
flutter devices
flutter run -d <device_id>
```

### Parcours utilisateur

#### 1️⃣ Inscription
L'étudiant crée son compte en renseignant ses informations personnelles et en scannant son visage. Le système vérifie automatiquement l'absence de doublon dans la base de données.

#### 2️⃣ Pointage
Pour valider sa présence, l'étudiant sélectionne le cours en cours et scanne son visage. La présence n'est validée que si le score de reconnaissance dépasse le seuil de sécurité défini (généralement > 80%).

#### 3️⃣ Tableau de bord
L'étudiant accède à ses statistiques de présence, son historique complet et les cours à venir dans sa filière.

---

## 🔒 Sécurité

### Protection des données biométriques
- Les embeddings faciaux sont des vecteurs mathématiques unidirectionnels
- Impossible de reconstituer une photo à partir d'un embedding
- Conformité RGPD : données pseudonymisées

### Mesures anti-fraude
- Détection de liveness (à implémenter en production)
- Seuil de confiance ajustable pour la reconnaissance
- Blocage automatique des tentatives multiples échouées
- Limitation des pointages par session

### Bonnes pratiques
- Authentification Firebase sécurisée
- Règles de sécurité Firestore strictes
- Chiffrement des communications (HTTPS/TLS)
- Logs d'audit pour toutes les opérations sensibles

---

## 👥 Équipe

Ce projet a été développé par l'équipe AIP de l'ENEAM :

## 👥 Équipe et collaborateurs

| Développeur            | Branch(s)               | GitHub                                            |
|------------------------|-------------------------|---------------------------------------------------|
| **COCOUVI Alexandro**  | xandrothedev, main      | [@COCOUVI](https://github.com/COCOUVI)            |
| **Hamid-HBS**          | hamid-branch, hamid-branchh | [@hamid-hbs](https://github.com/hamid-hbs)        |
| **John230624**         | john-geeek              | [@John230624](https://github.com/John230624)      |
| **Elfrieda**           | Elfrieda_branch         | *(ajoute le lien GitHub si besoin)*               |
| **Daryl**              | daryl-branch            | *(ajoute le lien GitHub si besoin)*               |
---

## 🔮 Perspectives d'évolution

### Court terme
- [ ] Ajout d'un mode hors-ligne avec synchronisation différée
- [ ] Notifications push pour rappel des cours
- [ ] Tableau de bord enseignant avec statistiques globales

### Moyen terme
- [ ] Intégration d'API biométriques avancées (Azure Face API, AWS Rekognition)
- [ ] Authentification multi-facteurs (PIN + Face)
- [ ] Export des rapports de présence (PDF, Excel)

### Long terme
- [ ] Module de génération automatique d'emploi du temps
- [ ] Analyse prédictive des absences
- [ ] Application web d'administration

---

## 📄 Licence

Ce projet est distribué sous licence MIT. Voir le fichier `LICENSE` pour plus d'informations.

---

## 📞 Contact & Support

- **Email** : [contact@eneam.edu](mailto:contact@eneam.edu)
- **Repository** : [github.com/COCOUVI/detection_faciale](https://github.com/COCOUVI/detection_faciale)
- **Issues** : [Signaler un bug](https://github.com/COCOUVI/detection_faciale/issues)

---

## 🙏 Remerciements

Merci à l'ENEAM pour l'encadrement de ce projet et aux enseignants du parcours AIP pour leur accompagnement.

---

<div align="center">

**Développé avec par l'équipe AIP - ENEAM**

*"La présence connectée : simple, fiable et adaptée à l'enseignement moderne"*

</div>