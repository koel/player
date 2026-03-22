import 'dart:async';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  return testMain();
}
