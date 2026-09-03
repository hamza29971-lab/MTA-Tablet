import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  static const String cloudName = 'c0ilsxhp';
  static const String uploadPreset = 'p0ojrxwr';
  static const String apiUrl = 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

  static Future<String?> uploadImage(XFile file) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.fields['upload_preset'] = uploadPreset;
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = jsonDecode(responseData);

      if (response.statusCode == 200) {
        return jsonResponse['secure_url']; // Yüklenen fotoğrafın URL'i
      } else {
        print('Cloudinary Hata: ${jsonResponse['error']['message']}');
        return null;
      }
    } catch (e) {
      print('Cloudinary Yükleme Hatası: $e');
      return null;
    }
  }

  static Future<List<String>> uploadImages(List<XFile> files) async {
    List<String> urls = [];
    for (var file in files) {
      final url = await uploadImage(file);
      if (url != null) {
        urls.add(url);
      }
    }
    return urls;
  }
}
