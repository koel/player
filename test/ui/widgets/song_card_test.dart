import 'package:app/models/models.dart';
import 'package:app/ui/widgets/song_card.dart';
import 'package:app/ui/widgets/playable_thumbnail.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../extensions/widget_tester_extension.dart';

void main() {
  testWidgets('renders a Song with artist name', (WidgetTester tester) async {
    final song = Song.fake(title: 'Test Song');

    await tester.pumpAppWidget(SongCard(playable: song));

    expect(find.text('Test Song'), findsOneWidget);
    expect(find.text(song.artistName), findsOneWidget);
    expect(find.byType(PlayableThumbnail), findsOneWidget);
  });

  testWidgets('renders an Episode with podcast title',
      (WidgetTester tester) async {
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

    await tester.pumpAppWidget(SongCard(playable: episode));

    expect(find.text('Test Episode'), findsOneWidget);
    expect(find.text('My Podcast'), findsOneWidget);
  });
}
