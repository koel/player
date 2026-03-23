import 'package:app/models/playlist_folder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlaylistFolder.fromJson', () {
    test('parses all fields', () {
      final json = {
        'id': 'folder-uuid-1',
        'name': 'Rock Collection',
      };

      final folder = PlaylistFolder.fromJson(json);

      expect(folder.id, 'folder-uuid-1');
      expect(folder.name, 'Rock Collection');
    });
  });

  group('PlaylistFolder.fake', () {
    test('generates a valid folder', () {
      final folder = PlaylistFolder.fake();
      expect(folder.id, isNotEmpty);
      expect(folder.name, isNotEmpty);
    });

    test('respects custom parameters', () {
      final folder = PlaylistFolder.fake(id: 'custom-id', name: 'My Folder');
      expect(folder.id, 'custom-id');
      expect(folder.name, 'My Folder');
    });
  });
}
