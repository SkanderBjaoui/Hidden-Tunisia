import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../config/supabase_config.dart';
import 'app_exception.dart';

/// Uploads destination images to Supabase Storage.
class StorageService {
  static const _maxBytes = 5 * 1024 * 1024; // matches the bucket limit (5 MB)
  static const _mimeByExtension = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
  };

  SupabaseClient get _client => Supabase.instance.client;

  /// Uploads [file] and returns its public URL (saved in places.image_url).
  /// Files go in a folder named after the user id: the storage policy only
  /// allows users to write inside their own folder.
  Future<String> uploadPlaceImage(XFile file) {
    return guardBackend(() async {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw const AppException('Please log in to upload an image.');
      }

      final extension = file.name.contains('.')
          ? file.name.split('.').last.toLowerCase()
          : 'jpg';
      final mime = _mimeByExtension[extension];
      if (mime == null) {
        throw const AppException('Please choose a JPG, PNG or WebP image.');
      }

      final bytes = await file.readAsBytes();
      if (bytes.length > _maxBytes) {
        throw const AppException('The image is too big (maximum 5 MB).');
      }

      final path = '$userId/${const Uuid().v4()}.$extension';
      final bucket = _client.storage.from(SupabaseConfig.imageBucket);
      await bucket.uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(contentType: mime),
      );
      return bucket.getPublicUrl(path);
    });
  }
}
