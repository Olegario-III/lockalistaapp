import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String cloudName = "dpu3l37x3";

  /// Uploads a file to Cloudinary
  /// [imageFile]: the local file to upload
  /// [folder]: optional folder in Cloudinary (e.g., 'profiles', 'events')
  /// [preset]: optional unsigned preset name
  Future<String?> uploadFile(
    File imageFile, {
    String folder = '',
    String preset = 'lockalista', // default preset you created
  }) async {
    final uri = Uri.parse(
      "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
    );

    final request = http.MultipartRequest("POST", uri)
      ..fields["upload_preset"] = preset;

    // Add folder if provided
    if (folder.isNotEmpty) {
      request.fields["folder"] = folder;
    }

    request.files.add(
      await http.MultipartFile.fromPath("file", imageFile.path),
    );

    final response = await request.send();

    if (response.statusCode != 200 && response.statusCode != 201) {
      print('Cloudinary upload failed: ${response.statusCode}');
      return null;
    }

    final resStr = await response.stream.bytesToString();
    final data = jsonDecode(resStr);
    return data["secure_url"];
  }
}
