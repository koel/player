import 'package:app/constants/colors.dart';
import 'package:app/constants/dimensions.dart';
import 'package:app/providers/playlist_provider.dart';
import 'package:app/ui/widgets/message_overlay.dart';
import 'package:app/ui/widgets/spinner.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CreatePlaylistSheet extends StatefulWidget {
  static final Key nameFieldKey = UniqueKey();
  static final Key submitButtonKey = UniqueKey();

  const CreatePlaylistSheet({Key? key}) : super(key: key);

  @override
  _AddPlaylistScreenState createState() => _AddPlaylistScreenState();
}

class _AddPlaylistScreenState extends State<CreatePlaylistSheet> {
  late PlaylistProvider playlistProvider;
  bool _enabled = true;
  bool _working = false;
  late String _name;
  FocusNode focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    playlistProvider = context.read();
  }

  void _onFieldValueChanged(String value) {
    _name = value;
    setState(() => _enabled = value.trim() != '');
  }

  final InputBorder inputBorder = const UnderlineInputBorder(
    borderSide: BorderSide(color: AppColors.highlight),
  );

  final Widget spinner = const Center(
    child: Padding(
      padding: EdgeInsets.only(top: 18.0),
      child: Spinner(size: 16.0),
    ),
  );

  @override
  Widget build(BuildContext context) {
    Future<void> submit() async {
      if (_name == '') return;

      focusNode.unfocus();
      setState(() => _working = true);
      bool ok = true;

      try {
        await playlistProvider.create(name: _name);
      } catch (err) {
        ok = false;
      } finally {
        setState(() => _working = false);
      }

      if (ok) {
        Navigator.of(context).pop();
        showOverlay(context, caption: 'Playlist added');
      } else {
        showCupertinoDialog(
          context: context,
          builder: (BuildContext context) {
            return CupertinoAlertDialog(
              title: const Text('Uh oh'),
              content: const Text(
                'Something wrong happened. Please try again.',
              ),
              actions: <Widget>[
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            );
          },
        );
      }
    }

    return Container(
      color: AppColors.black,
      padding: EdgeInsets.only(
        left: AppDimensions.horizontalPadding,
        right: AppDimensions.horizontalPadding,
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Align(
        child: Form(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextFormField(
                key: CreatePlaylistSheet.nameFieldKey,
                focusNode: focusNode,
                onFieldSubmitted: (_) async => await submit(),
                onChanged: _onFieldValueChanged,
                style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.w700),
                cursorColor: AppColors.highlight,
                textAlign: TextAlign.center,
                autofocus: true,
                decoration: InputDecoration(
                  border: inputBorder,
                  enabledBorder: inputBorder,
                  focusedBorder: inputBorder,
                  fillColor: Colors.transparent,
                  hintText: 'Playlist name',
                ),
              ),
              const SizedBox(height: 24.0),
              _working
                  ? spinner
                  : ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: double.infinity,
                      ),
                      child: ElevatedButton(
                        key: CreatePlaylistSheet.submitButtonKey,
                        style: ElevatedButton.styleFrom(onSurface: Colors.grey),
                        onPressed: _enabled ? () async => await submit() : null,
                        child: const Text('Create Playlist'),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
