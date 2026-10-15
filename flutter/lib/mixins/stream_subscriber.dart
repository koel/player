import 'dart:async';

mixin StreamSubscriber {
  final List<StreamSubscription> _subscriptions = [];

  void unsubscribeAll() => _subscriptions.forEach((sub) => sub.cancel());

  void subscribe(StreamSubscription sub) => _subscriptions.add(sub);
}
