import 'package:app/exceptions/http_response_exception.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> showAddPodcastDialog(BuildContext context) async {
  final urlController = TextEditingController();
  final podcastProvider = context.read<PodcastProvider>();

  await showFormSheet(
    context,
    title: 'Add Podcast',
    submitLabel: 'Add',
    canSubmit: () => urlController.text.trim().isNotEmpty,
    onSubmit: () async {
      final url = urlController.text.trim();
      if (url.isEmpty) return;

      try {
        await podcastProvider.add(url: url);
        Navigator.pop(context);
        showOverlay(context, caption: 'Podcast added');
      } catch (e) {
        final message =
            e is HttpResponseException && e.response.statusCode == 409
                ? 'You are already subscribed to this podcast.'
                : 'Something wrong happened. Please try again.';
        showOverlay(
          context,
          caption: 'Error',
          message: message,
          icon: CupertinoIcons.exclamationmark_triangle,
        );
      }
    },
    builder: (context, setState) {
      return FormTextField(
        controller: urlController,
        placeholder: 'Podcast RSS URL',
        keyboardType: TextInputType.url,
        autofocus: true,
        onChanged: (_) => setState(() {}),
      );
    },
  );
}
