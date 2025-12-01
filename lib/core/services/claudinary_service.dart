import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';

class CloudinaryService {
  final cloudinary = CloudinaryPublic(
    'dpu3l37x3', // Replace with your Cloudinary cloud name
    'lockalista', // Replace with your upload preset
    cache: false,
  );

  Future<String?> uploadFile(File file, {String folder = 'lockalista'}) async {
    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(file.path, folder: folder),
      );
      return response.secureUrl;
    } catch (e) {
      print('Cloudinary upload error: $e');
      return null;
    }
  }
}
