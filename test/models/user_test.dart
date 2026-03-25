import 'package:app/models/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('User.fromJson', () {
    test('parses all fields including preferences', () {
      final json = {
        'id': 'user-1',
        'name': 'John Doe',
        'email': 'john@example.com',
        'is_admin': true,
        'avatar': 'https://example.com/avatar.jpg',
        'preferences': {
          'continuous_playback': true,
          'crossfade_duration': 5,
        },
      };

      final user = User.fromJson(json);

      expect(user.id, 'user-1');
      expect(user.name, 'John Doe');
      expect(user.email, 'john@example.com');
      expect(user.isAdmin, isTrue);
      expect(user.avatarUrl, 'https://example.com/avatar.jpg');
      expect(user.continuousPlayback, isTrue);
      expect(user.crossfadeDuration, 5);
    });

    test('handles missing preferences', () {
      final json = {
        'id': 'user-2',
        'name': 'Jane',
        'email': 'jane@example.com',
        'is_admin': false,
      };

      final user = User.fromJson(json);

      expect(user.continuousPlayback, isFalse);
      expect(user.crossfadeDuration, 0);
      expect(user.avatarUrl, isNull);
    });

    test('uses API avatar when available', () {
      final user = User.fromJson({
        'id': '1',
        'name': 'Test',
        'email': 'test@test.com',
        'is_admin': false,
        'avatar': 'https://cdn.example.com/photo.jpg',
      });

      expect(user.avatar.url, 'https://cdn.example.com/photo.jpg');
    });

    test('falls back to gravatar when no avatar URL', () {
      final user = User.fromJson({
        'id': '1',
        'name': 'Test',
        'email': 'test@test.com',
        'is_admin': false,
      });

      expect(user.avatar.url, contains('gravatar.com'));
    });
  });
}
