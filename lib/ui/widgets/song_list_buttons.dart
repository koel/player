import 'package:app/constants/constants.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/widgets/full_width_primary_icon_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

enum SongListContext {
  queue,
  allSongs,
  album,
  artist,
  playlist,
  favorites,
  other,
}

class ButtonConfig {
  final String label;
  final Widget icon;
  final void Function()? onPressed;

  const ButtonConfig({
    required this.label,
    required this.icon,
    required this.onPressed,
  });
}

class SongListButtons extends StatelessWidget {
  final List<Song> songs;
  final List<ButtonConfig> buttons;

  const SongListButtons({
    Key? key,
    required this.songs,
    this.buttons = const [],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AudioProvider audio = context.read();

    var _buttons = this.buttons;
    if (_buttons.isEmpty) {
      _buttons = [
        ButtonConfig(
          label: 'Play All',
          icon: const Icon(CupertinoIcons.play_fill),
          onPressed: () async => await audio.replaceQueue(songs),
        ),
        ButtonConfig(
          label: 'Shuffle All',
          icon: const Icon(CupertinoIcons.shuffle),
          onPressed: () async => await audio.replaceQueue(songs, shuffle: true),
        ),
      ];
    }

    List<Widget> buttonWidgets = [];
    _buttons.forEach((element) {
      buttonWidgets
        ..add(FullWidthPrimaryIconButton(
          icon: element.icon,
          label: element.label,
          onPressed: element.onPressed,
        ))
        ..add(SizedBox(width: 12));
    });

    return Container(
      padding: const EdgeInsets.all(AppDimensions.horizontalPadding),
      child: Row(children: buttonWidgets..removeLast()),
    );
  }
}
