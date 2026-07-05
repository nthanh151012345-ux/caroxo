import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase_config.dart';

class AvatarUploadTarget {
  final String storagePath;
  final String contentType;

  const AvatarUploadTarget({
    required this.storagePath,
    required this.contentType,
  });

  factory AvatarUploadTarget.fromFileName({
    required String userId,
    required String fileName,
  }) {
    final extension = _normalizedExtension(fileName);
    return AvatarUploadTarget(
      storagePath: '$userId/avatar.$extension',
      contentType: _contentTypeForExtension(extension),
    );
  }

  static String _normalizedExtension(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    final raw = dotIndex == -1 ? '' : fileName.substring(dotIndex + 1);
    final extension = raw.toLowerCase().trim();
    if (extension == 'jpg' ||
        extension == 'jpeg' ||
        extension == 'png' ||
        extension == 'webp' ||
        extension == 'gif') {
      return extension == 'jpeg' ? 'jpg' : extension;
    }
    return 'jpg';
  }

  static String _contentTypeForExtension(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'jpg':
      default:
        return 'image/jpeg';
    }
  }
}

class ProfileService {
  static const String avatarBucket = 'avatars';

  SupabaseClient get _client {
    final client = SupabaseConfig.client;
    if (client == null) {
      throw StateError('Supabase chưa được cấu hình.');
    }
    return client;
  }

  Future<String?> fetchAvatarUrl() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return null;
    }

    final row = await _client
        .from('profiles')
        .select('avatar_url')
        .eq('user_id', user.id)
        .maybeSingle();

    return row?['avatar_url'] as String?;
  }

  Future<String> uploadAvatar(PlatformFile file) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('Bạn cần đăng nhập để cập nhật ảnh đại diện.');
    }

    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      throw StateError('Không thể đọc tệp ảnh đã chọn.');
    }

    final target = AvatarUploadTarget.fromFileName(
      userId: user.id,
      fileName: file.name,
    );

    await _client.storage
        .from(avatarBucket)
        .uploadBinary(
          target.storagePath,
          Uint8List.fromList(bytes),
          fileOptions: FileOptions(
            contentType: target.contentType,
            upsert: true,
          ),
        );

    final avatarUrl = _client.storage
        .from(avatarBucket)
        .getPublicUrl(target.storagePath);

    await _client.from('profiles').upsert({
      'user_id': user.id,
      'email': user.email,
      'avatar_url': avatarUrl,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });

    return avatarUrl;
  }
}
