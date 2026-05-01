import 'package:app/models/models.dart';
import 'package:app/providers/podcast_provider.dart';
import 'package:app/router.dart';
import 'package:app/ui/widgets/podcast_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';

import '../../extensions/widget_tester_extension.dart';
import 'podcast_card_test.mocks.dart';

@GenerateMocks([AppRouter, PodcastProvider])
void main() {
  Future<void> mountWithProvider(WidgetTester tester, Podcast podcast) async {
    await tester.pumpAppWidget(
      ChangeNotifierProvider<PodcastProvider>.value(
        value: MockPodcastProvider(),
        child: PodcastCard(podcast: podcast, router: MockAppRouter()),
      ),
    );
  }

  testWidgets('shows Unsubscribe on long-press', (tester) async {
    final podcast = Podcast.fake(title: 'My Podcast');
    await mountWithProvider(tester, podcast);

    await tester.longPress(find.byType(PodcastCard));
    await tester.pumpAndSettle();

    expect(find.text('Unsubscribe'), findsOneWidget);
  });
}
