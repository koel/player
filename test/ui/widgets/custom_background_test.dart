import 'package:app/ui/widgets/gradient_decorated_container.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Custom background', () {
    test('backgroundImageNotifier is a ValueNotifier', () {
      expect(backgroundImageNotifier, isA<ValueNotifier<String?>>());
    });

    test('can be set and read', () {
      backgroundImageNotifier.value = '/some/path/image.jpg';
      expect(backgroundImageNotifier.value, '/some/path/image.jpg');

      backgroundImageNotifier.value = null;
      expect(backgroundImageNotifier.value, isNull);
    });

    test('null value means default asset background', () {
      backgroundImageNotifier.value = null;
      expect(backgroundImageNotifier.value, isNull);
    });

    test('non-null value means custom background', () {
      backgroundImageNotifier.value = '/custom/background.png';
      expect(backgroundImageNotifier.value, isNotNull);

      backgroundImageNotifier.value = null;
    });

    test('notifier broadcasts changes to listeners', () {
      String? received;

      backgroundImageNotifier.addListener(() {
        received = backgroundImageNotifier.value;
      });

      backgroundImageNotifier.value = '/new/image.webp';
      expect(received, '/new/image.webp');

      backgroundImageNotifier.value = null;
      expect(received, isNull);
    });
  });
}
