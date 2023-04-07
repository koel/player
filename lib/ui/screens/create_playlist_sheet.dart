import 'package:app/constants/constants.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/widgets/widgets.dart';
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
  late final PlaylistProvider playlistProvider;
  var _enabled = true;
  var _working = false;
  late String _name;
  final focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    playlistProvider = context.read();
  }

  void _onFieldValueChanged(String value) {
    _name = value;
    setState(() => _enabled = value.trim().isNotEmpty);
  }

  final inputBorder = const UnderlineInputBorder(
    borderSide: BorderSide(color: AppColors.highlight),
  );

  final spinner = const Center(
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
      var ok = true;

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

    return GradientDecoratedContainer(
      padding: EdgeInsets.only(
        left: AppDimensions.hPadding,
        right: AppDimensions.hPadding,
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
                  : ElevatedButton(
                      key: CreatePlaylistSheet.submitButtonKey,
                      onPressed: _enabled ? () async => await submit() : null,
                      child: const Text('Save'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
