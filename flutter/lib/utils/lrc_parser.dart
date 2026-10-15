class LrcLine {
  final double time; // Time in seconds
  final String text;

  LrcLine({required this.time, required this.text});
}

class LrcParser {
  static List<LrcLine> parse(String lyrics) {
    if (lyrics.isEmpty) return [];

    final List<LrcLine> lines = [];
    // Match [m:ss.xx] or [mm:ss.xxx] format (1-2 digit minutes)
    final RegExp tagRegex = RegExp(r'\[(\d{1,2}):(\d{2})\.(\d{2,3})\]');

    for (final line in lyrics.split('\n')) {
      final matches = tagRegex.allMatches(line);
      if (matches.isEmpty) continue;

      // The text is everything after the last tag
      final lastMatch = matches.last;
      final text = line.substring(lastMatch.end).trim();

      if (text.isEmpty) continue;

      for (final match in matches) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final fracStr = match.group(3)!;
        final double frac;

        if (fracStr.length == 3) {
          frac = int.parse(fracStr) / 1000.0;
        } else {
          frac = int.parse(fracStr) / 100.0;
        }

        final time = minutes * 60.0 + seconds + frac;
        lines.add(LrcLine(time: time, text: text));
      }
    }

    // Sort by time
    lines.sort((a, b) => a.time.compareTo(b.time));
    return lines;
  }

  static bool hasSyncedLyrics(String lyrics) {
    return RegExp(r'\[\d{1,2}:\d{2}\.\d{2,3}\]').hasMatch(lyrics);
  }
}
