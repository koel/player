class LrcLine {
  final double time; // Time in seconds
  final String text;

  LrcLine({required this.time, required this.text});
}

class LrcParser {
  static List<LrcLine> parse(String lyrics) {
    if (lyrics.isEmpty) return [];

    final List<LrcLine> lines = [];
    // Match [mm:ss.xx] or [mm:ss.xxx] format
    final RegExp lrcRegex = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)');

    for (final line in lyrics.split('\n')) {
      final match = lrcRegex.firstMatch(line);
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final centiseconds = int.parse(
          match.group(3)!.padRight(2, '0').substring(0, 2),
        );
        final time = minutes * 60.0 + seconds + centiseconds / 100.0;
        final text = match.group(4)!.trim();

        if (text.isNotEmpty) {
          lines.add(LrcLine(time: time, text: text));
        }
      }
    }

    // Sort by time
    lines.sort((a, b) => a.time.compareTo(b.time));
    return lines;
  }

  static bool hasSyncedLyrics(String lyrics) {
    return RegExp(r'\[\d{2}:\d{2}\.\d{2,3}\]').hasMatch(lyrics);
  }
}
