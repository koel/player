import 'package:app/constants/constants.dart';
import 'package:app/exceptions/http_response_exception.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddPodcastSheet extends StatefulWidget {
  static final Key nameFieldKey = UniqueKey();
  static final Key submitButtonKey = UniqueKey();

  const AddPodcastSheet({Key? key}) : super(key: key);

  @override
  _AddPodcastSheetState createState() => _AddPodcastSheetState();
}

class _AddPodcastSheetState extends State<AddPodcastSheet> {
  late final PodcastProvider podcastProvider;
  var _enabled = true;
  var _working = false;
  late String _url;
  final focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    podcastProvider = context.read();
  }

  void _onFieldValueChanged(String value) {
    _url = value;
    setState(() => _enabled = value.trim().isNotEmpty);
  }

  final inputBorder = UnderlineInputBorder(
    borderSide: BorderSide(color: AppColors.white.withOpacity(.8)),
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
      if (_url == '') return;

      focusNode.unfocus();
      setState(() => _working = true);
      var error = null;

      try {
        await podcastProvider.add(url: _url);
      } catch (err) {
        error = err;
      } finally {
        setState(() => _working = false);
      }

      if (error == null) {
        Navigator.of(context).pop();
        showOverlay(context, caption: 'Podcast added');
      } else {
        var message =
            error is HttpResponseException && error.response.statusCode == 409
                ? 'You are already subscribed to this podcast.'
                : 'Something wrong happened. Please try again.';
        showCupertinoDialog(
          context: context,
          builder: (BuildContext context) {
            return CupertinoAlertDialog(
              title: const Text('Uh oh'),
              content: Text(message),
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
                key: AddPodcastSheet.nameFieldKey,
                keyboardType: TextInputType.url,
                focusNode: focusNode,
                onFieldSubmitted: (_) async => await submit(),
                onChanged: _onFieldValueChanged,
                style: TextStyle(fontSize: 14.0),
                cursorColor: AppColors.white,
                autofocus: true,
                decoration: InputDecoration(
                  border: inputBorder,
                  enabledBorder: inputBorder,
                  focusedBorder: inputBorder,
                  fillColor: Colors.transparent,
                  hintText: 'Podcast RSS URL',
                  hintStyle: TextStyle(color: AppColors.white.withOpacity(.8)),
                ),
              ),
              const SizedBox(height: 24.0),
              _working
                  ? spinner
                  : ElevatedButton(
                      key: AddPodcastSheet.submitButtonKey,
                      onPressed: _enabled ? () async => await submit() : null,
                      child: const Text('Add'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
