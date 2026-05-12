import 'dart:io';
import 'package:image/image.dart' as img;

import '../stego/lsb_encoder.dart';
import '../stego/lsb_decoder.dart';

class StegoPipeline {

  final encoder = LSBEncoder();
  final decoder = LSBDecoder();

  /// Hide encrypted payload inside image
  File encode(File imageFile, String payload) {

    final image = img.decodeImage(imageFile.readAsBytesSync())!;

    final encoded = encoder.encode(image, payload);

    final output = File(
      imageFile.path.replaceAll(".png", "_hidden.png"),
    );

    output.writeAsBytesSync(img.encodePng(encoded));

    return output;
  }

  /// Extract payload from image
  String decode(File imageFile) {

    final image = img.decodeImage(imageFile.readAsBytesSync())!;

    return decoder.decode(image);
  }
}