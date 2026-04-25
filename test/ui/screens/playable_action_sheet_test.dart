import 'package:app/models/song.dart';
import 'package:app/providers/download_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'playable_action_sheet_test.mocks.dart';

@GenerateMocks([DownloadProvider])
void main() {
  group('PlayableActionSheet — Download / Remove Download action', () {
    late MockDownloadProvider downloadProviderMock;
    late Song song;

    setUp(() {
      downloadProviderMock = MockDownloadProvider();
      song = Song.fake();
    });

    test('label and behavior toggle on the download state', () {
      // Downloaded → "Remove Download" → removeForPlayable
      when(downloadProviderMock.has(playable: song)).thenReturn(true);
      var downloaded = downloadProviderMock.has(playable: song);
      expect(downloaded, isTrue);
      expect(downloaded ? 'Remove Download' : 'Download', 'Remove Download');

      // Not downloaded → "Download" → download
      when(downloadProviderMock.has(playable: song)).thenReturn(false);
      downloaded = downloadProviderMock.has(playable: song);
      expect(downloaded, isFalse);
      expect(downloaded ? 'Remove Download' : 'Download', 'Download');
    });

    test('tapping when downloaded delegates to removeForPlayable', () async {
      when(downloadProviderMock.removeForPlayable(song))
          .thenAnswer((_) async {});

      await downloadProviderMock.removeForPlayable(song);

      verify(downloadProviderMock.removeForPlayable(song)).called(1);
      verifyNever(downloadProviderMock.download(playable: song));
    });

    test('tapping when not downloaded delegates to download', () async {
      when(downloadProviderMock.download(playable: song))
          .thenAnswer((_) async {});

      await downloadProviderMock.download(playable: song);

      verify(downloadProviderMock.download(playable: song)).called(1);
      verifyNever(downloadProviderMock.removeForPlayable(song));
    });
  });
}
