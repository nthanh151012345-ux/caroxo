import 'package:caroxo/services/profile_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AvatarUploadTarget', () {
    test('uses lower-case supported extension in fixed user path', () {
      final target = AvatarUploadTarget.fromFileName(
        userId: 'user-123',
        fileName: 'My Photo.PNG',
      );

      expect(target.storagePath, 'user-123/avatar.png');
      expect(target.contentType, 'image/png');
    });

    test('defaults unknown extension to jpg', () {
      final target = AvatarUploadTarget.fromFileName(
        userId: 'user-123',
        fileName: 'avatar.bmp',
      );

      expect(target.storagePath, 'user-123/avatar.jpg');
      expect(target.contentType, 'image/jpeg');
    });

    test('defaults missing extension to jpg', () {
      final target = AvatarUploadTarget.fromFileName(
        userId: 'user-123',
        fileName: 'avatar',
      );

      expect(target.storagePath, 'user-123/avatar.jpg');
      expect(target.contentType, 'image/jpeg');
    });
  });
}
