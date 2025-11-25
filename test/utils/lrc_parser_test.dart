import 'package:app/utils/lrc_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('detects synced lyrics with single digit minutes', () {
    const lyrics = '[0:12.34]First line';

    expect(LrcParser.hasSyncedLyrics(lyrics), isTrue);
  });

  test('parses multiple timestamps on the same line', () {
    const lyrics =
        '[00:05.50][00:07.10]Dual tag line\n[01:02.345]Another line';

    final lines = LrcParser.parse(lyrics);

    expect(lines.length, 3);
    expect(lines[0].time, closeTo(5.5, 0.0001));
    expect(lines[1].time, closeTo(7.1, 0.0001));
    expect(lines[0].text, 'Dual tag line');
    expect(lines[2].time, closeTo(62.345, 0.0001));
    expect(lines[2].text, 'Another line');
  });

  test('ignores lines without text after timestamps', () {
    const lyrics = '[00:01.00]\n[00:02.00]Actual text';

    final lines = LrcParser.parse(lyrics);

    expect(lines.length, 1);
    expect(lines.single.text, 'Actual text');
  });

  test('parses real LRC format with spaces after timestamps', () {
    const lyrics = '''[00:19.83] I am my mother's only one
[00:26.02] It's enough
[00:34.25] I wear my garment so it shows''';

    final lines = LrcParser.parse(lyrics);

    expect(lines.length, 3);
    expect(lines[0].time, closeTo(19.83, 0.01));
    expect(lines[0].text, "I am my mother's only one");
    expect(lines[1].time, closeTo(26.02, 0.01));
    expect(lines[1].text, "It's enough");
  });
}
