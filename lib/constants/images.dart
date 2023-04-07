import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class AppImages {
  AppImages._();

  static const defaultImageAssetName = 'assets/images/default-image.webp';
  static Uri? _defaultArtUri;

  static const defaultImage = const Image(
    image: AssetImage(defaultImageAssetName),
  );

  // audio_service doesn't directly support `asset://` URIs, so we need to
  // convert the asset to a file and use a `file://` URI instead.
  // See: https://github.com/ryanheise/audio_service/issues/523
  static Future<Uri?> getDefaultArtUri() async {
    if (_defaultArtUri == null) {
      try {
        final content = await rootBundle.load(defaultImageAssetName);
        final bytes = content.buffer.asUint8List();
        final documentDir = await getApplicationDocumentsDirectory();
        final filePath = '${documentDir.path}/default-image.webp';

        _defaultArtUri = (await File(filePath).writeAsBytes(bytes)).uri;
      } catch (_) {}
    }

    return _defaultArtUri;
  }
}
