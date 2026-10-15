import 'package:app/models/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> baseJson({dynamic preferences}) => {
        'id': 'user-1',
        'name': 'Jane',
        'email': 'jane@koel.test',
        if (preferences != null) 'preferences': preferences,
      };

  test('parses home_blocks_order from preferences', () {
    final user = User.fromJson(baseJson(preferences: {
      'home_blocks_order': ['random-songs', 'most-played-albums'],
    }));

    expect(user.homeBlocksOrder, ['random-songs', 'most-played-albums']);
  });

  test('defaults home_blocks_order to empty when absent (older API)', () {
    expect(User.fromJson(baseJson()).homeBlocksOrder, isEmpty);
    expect(
      User.fromJson(baseJson(preferences: {'something_else': true}))
          .homeBlocksOrder,
      isEmpty,
    );
  });

  test('keeps only string entries in home_blocks_order', () {
    final user = User.fromJson(baseJson(preferences: {
      'home_blocks_order': ['random-songs', 42, null, 'top-albums'],
    }));

    expect(user.homeBlocksOrder, ['random-songs', 'top-albums']);
  });
}
