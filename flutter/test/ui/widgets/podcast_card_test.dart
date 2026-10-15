import 'package:app/models/models.dart';
import 'package:app/router.dart';
import 'package:app/ui/widgets/album_artist_thumbnail.dart';
import 'package:app/ui/widgets/podcast_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../extensions/widget_tester_extension.dart';
import 'podcast_card_test.mocks.dart';

@GenerateMocks([AppRouter])
void main() {
  testWidgets('renders title, author and thumbnail', (tester) async {
    final podcast = Podcast.fake(title: 'My Podcast', author: 'Jane Doe');
    await tester.pumpAppWidget(PodcastCard(podcast: podcast));

    expect(find.byType(AlbumArtistThumbnail), findsOneWidget);
    expect(find.text('My Podcast'), findsOneWidget);
    expect(find.text('Jane Doe'), findsOneWidget);
  });

  testWidgets('goes to Podcast Details when tapped', (tester) async {
    final router = MockAppRouter();
    final podcast = Podcast.fake(title: 'Tap Pod');
    when(router.gotoPodcastDetailsScreen(any, podcastId: podcast.id))
        .thenAnswer((_) async => null);

    await tester.pumpAppWidget(
      PodcastCard(podcast: podcast, router: router),
    );

    await tester.tap(find.text('Tap Pod'));
    verify(router.gotoPodcastDetailsScreen(any, podcastId: podcast.id))
        .called(1);
  });
}
