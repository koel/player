import 'package:app/models/models.dart';
import 'package:app/providers/playable_provider.dart';
import 'package:app/ui/widgets/song_card.dart';
import 'package:app/ui/widgets/playable_thumbnail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../extensions/widget_tester_extension.dart';

class _Harness {
  final PlayableProvider provider;
  final Future<void> Function() pump;
  _Harness(this.provider, this.pump);
}

_Harness _harness(WidgetTester tester, Playable playable) {
  final provider = PlayableProvider();
  addTearDown(provider.dispose);
  if (playable is Song) provider.syncWithVault([playable]);
  return _Harness(
    provider,
    () => tester.pumpAppWidget(
      ChangeNotifierProvider<PlayableProvider>.value(
        value: provider,
        child: SongCard(playable: playable),
      ),
    ),
  );
}

void main() {
  testWidgets('renders a Song with artist name', (tester) async {
    final song = Song.fake(title: 'Test Song');
    await _harness(tester, song).pump();

    expect(find.text('Test Song'), findsOneWidget);
    expect(find.text(song.artistName), findsOneWidget);
    expect(find.byType(PlayableThumbnail), findsOneWidget);
  });

  testWidgets('renders an Episode with podcast title', (tester) async {
    final episode = Episode(
      id: 'ep-1',
      length: 300,
      title: 'Test Episode',
      podcastId: 'pod-1',
      podcastTitle: 'My Podcast',
      podcastAuthor: 'Author',
      description: 'A description',
      imageUrl: 'https://example.com/image.jpg',
      link: null,
      createdAt: DateTime.now(),
    );
    await _harness(tester, episode).pump();

    expect(find.text('Test Episode'), findsOneWidget);
    expect(find.text('My Podcast'), findsOneWidget);
  });

  testWidgets(
    'rebuilds the artist subtitle when PlayableProvider notifies after a '
    'rename mutation',
    (tester) async {
      final song = Song.fake(title: 'Anthem')..artistName = 'Old Artist';
      final harness = _harness(tester, song);
      await harness.pump();
      expect(find.text('Old Artist'), findsOneWidget);

      song.artistName = 'Renamed Artist';
      harness.provider.notifyListeners();
      await tester.pump();

      expect(find.text('Renamed Artist'), findsOneWidget);
      expect(find.text('Old Artist'), findsNothing);
    },
  );
}
