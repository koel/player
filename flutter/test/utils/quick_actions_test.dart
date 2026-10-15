import 'package:app/utils/quick_actions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:quick_actions_platform_interface/quick_actions_platform_interface.dart';

class FakeQuickActionsPlatform extends QuickActionsPlatform
    with MockPlatformInterfaceMixin {
  QuickActionHandler? handler;
  List<ShortcutItem> items = [];

  @override
  Future<void> initialize(QuickActionHandler handler) async {
    this.handler = handler;
  }

  @override
  Future<void> setShortcutItems(List<ShortcutItem> items) async {
    this.items = items;
  }

  @override
  Future<void> clearShortcutItems() async {
    items = [];
  }
}

void main() {
  late FakeQuickActionsPlatform platform;
  late KoelQuickActions actions;

  setUp(() {
    platform = FakeQuickActionsPlatform();
    QuickActionsPlatform.instance = platform;
    actions = KoelQuickActions();
  });

  tearDown(() => actions.dispose());

  group('shortcutItems', () {
    test('offers Search, Favorites and Downloaded without a recent track', () {
      final items = KoelQuickActions.shortcutItems();

      expect(
        items.map((item) => item.type),
        [
          KoelQuickActions.search,
          KoelQuickActions.playFavorites,
          KoelQuickActions.playDownloaded,
        ],
      );
      expect(
        items.map((item) => item.icon),
        [
          'quick_action_search',
          'quick_action_favorites',
          'quick_action_download',
        ],
      );
    });

    test('adds Play Most Recent with a subtitle when a track is known', () {
      final items = KoelQuickActions.shortcutItems(recentSubtitle: 'Skid Row - 18 and Life');

      expect(items, hasLength(4));
      expect(items.last.type, KoelQuickActions.playRecent);
      expect(items.last.localizedTitle, 'Play Most Recent');
      expect(items.last.localizedSubtitle, 'Skid Row - 18 and Life');
    });
  });

  group('recentSubtitle', () {
    test('joins artist and title', () {
      expect(
        KoelQuickActions.recentSubtitle(artist: 'Skid Row', title: '18 and Life'),
        'Skid Row - 18 and Life',
      );
    });

    test('falls back to the title when there is no artist', () {
      expect(KoelQuickActions.recentSubtitle(artist: '', title: 'Untitled'),
          'Untitled');
      expect(KoelQuickActions.recentSubtitle(title: 'Untitled'), 'Untitled');
    });

    test('is null without a title', () {
      expect(KoelQuickActions.recentSubtitle(artist: 'X', title: null), isNull);
      expect(KoelQuickActions.recentSubtitle(artist: 'X', title: ''), isNull);
    });
  });

  test('setShortcuts forwards the built items to the platform', () async {
    await actions.setShortcuts(recentSubtitle: 'Skid Row - 18 and Life');

    expect(platform.items.map((item) => item.type), [
      KoelQuickActions.search,
      KoelQuickActions.playFavorites,
      KoelQuickActions.playDownloaded,
      KoelQuickActions.playRecent,
    ]);
  });

  test('buffers an action received before a listener and streams it', () async {
    actions.initialize();
    expect(platform.handler, isNotNull);

    final streamed = expectLater(
      actions.actions,
      emits(KoelQuickActions.playFavorites),
    );
    platform.handler!(KoelQuickActions.playFavorites);
    await streamed;

    expect(actions.consumePendingAction(), KoelQuickActions.playFavorites);
    expect(actions.consumePendingAction(), isNull);
  });

  test('tracks a pending search-focus request', () async {
    expect(actions.consumePendingSearchFocus(), isFalse);

    final focused = expectLater(actions.searchFocusRequests, emits(null));
    actions.requestSearchFocus();
    await focused;

    expect(actions.consumePendingSearchFocus(), isTrue);
    expect(actions.consumePendingSearchFocus(), isFalse);
  });
}
