import 'package:app/mixins/stream_subscriber.dart';
import 'package:app/ui/widgets/gradient_decorated_container.dart';
import 'package:flutter/material.dart';

class RecentlyPlayedScreen extends StatefulWidget {
  static const routeName = '/recently-played';

  const RecentlyPlayedScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _RecentlyPlayedScreenState();
}

class _RecentlyPlayedScreenState extends State<RecentlyPlayedScreen>
    with StreamSubscriber {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: GradientDecoratedContainer());
  }
}
