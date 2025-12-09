import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import '../config/cloudinary_config.dart';

class CloudinaryService {
  late CloudinaryPublic _cloudinary;

  CloudinaryService() {
    _cloudinary = CloudinaryPublic(
      CloudinaryConfig.cloudName,
      CloudinaryConfig.uploadPreset,
      cache: false,
    );
  }

  /// Upload une photo vers Cloudinary
  /// Retourne l'URL publique de la photo
  Future<String> uploadPhoto(File photo, String userId) async {
    try {
      print('🔄 Début upload Cloudinary pour UID: $userId');

      CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          photo.path,
          folder: CloudinaryConfig.folder,
          publicId: userId, // Le nom du fichier sera l'UID
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      String photoUrl = response.secureUrl;
      print('✅ Photo uploadée !  URL: $photoUrl');

      return photoUrl;
    } catch (e) {
      print('❌ Erreur upload Cloudinary: $e');
      rethrow;
    }
  }
}
