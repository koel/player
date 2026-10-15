import 'dart:async';

extension StreamExtensions<T> on Stream<T> {
  Stream<T> throttle(Duration duration) {
    Timer? throttleTimer;
    StreamController<T> resultStreamController = StreamController<T>();

    listen((event) {
      if (throttleTimer == null || !throttleTimer!.isActive) {
        throttleTimer = Timer(duration, () {});
        resultStreamController.add(event);
      }
    });

    return resultStreamController.stream;
  }
}
