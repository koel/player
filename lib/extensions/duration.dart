extension DurationExtensions on Duration {
  String toMs() {
    String twoDigitSeconds = _toTwoDigits(this.inSeconds.remainder(60));
    return "${_toTwoDigits(this.inMinutes)}:$twoDigitSeconds";
  }

  String toHms() {
    String twoDigitMinutes = _toTwoDigits(this.inMinutes.remainder(60));
    String twoDigitSeconds = _toTwoDigits(this.inSeconds.remainder(60));
    return "${_toTwoDigits(this.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  String _toTwoDigits(int n) => n >= 10 ? '$n' : '0$n';
}
