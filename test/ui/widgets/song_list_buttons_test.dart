import 'package:app/models/song.dart';
import 'package:app/providers/audio_provider.dart';
import 'package:app/ui/widgets/playable_list_header.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import '../../extensions/widget_tester_extension.dart';
import 'song_list_buttons_test.mocks.dart';

@GenerateMocks([AudioProvider])
void main() {
  late MockAudioProvider audioMock;
  late List<Song> songs;

  setUp(() {
    audioMock = MockAudioProvider();
    songs = Song.fakeMany(10);
  });

  Future<void> _mount(WidgetTester tester) async {
    await tester.pumpAppWidget(
      ChangeNotifierProvider<AudioProvider>.value(
        value: audioMock,
        child: PlayableListHeader(playables: songs),
      ),
    );
  }

  testWidgets('plays all', (WidgetTester tester) async {
    await _mount(tester);
    await tester.tap(find.byKey(PlayableListHeader.firstButtonKey));
    verify(audioMock.replaceQueue(songs)).called(1);
  });

  testWidgets('shuffles all', (WidgetTester tester) async {
    await _mount(tester);
    await tester.tap(find.byKey(PlayableListHeader.secondButtonKey));
    verify(audioMock.replaceQueue(songs, shuffle: true)).called(1);
  });
}
