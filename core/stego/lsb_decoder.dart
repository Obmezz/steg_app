import 'dart:convert';
import 'dart:math';
import 'package:image/image.dart';

class LSBDecoder {
  static const int seed = 1337;

  String decode(Image image) {
    final rand = Random(seed);
    final totalPixels = image.width * image.height;
    
    int x = rand.nextInt(image.width);
    int y = rand.nextInt(image.height);

    final bits = <int>[];

    // Read bits sequentially from the same deterministic path
    for (int i = 0; i < totalPixels; i++) {
      final currentX = (x + i) % image.width;
      final currentY = (y + (x + i) ~/ image.width) % image.height;

      final pixel = image.getPixel(currentX, currentY);

      bits.add(pixel.r.toInt() & 1);
      bits.add(pixel.g.toInt() & 1);
      bits.add(pixel.b.toInt() & 1);
      
      // Stop once we have enough bits (length + data)
      // But we don't know the length yet. 
      // We need at least 32 bits for the length header.
      if (bits.length >= 32 && bits.length >= 32 + _bitsToInt(bits.sublist(0, 32))) {
        break;
      }
    }

    final length = _bitsToInt(bits.sublist(0, 32));
    final payloadBits = bits.sublist(32, 32 + length);
    final bytes = _bitsToBytes(payloadBits);

    return utf8.decode(bytes);
  }

  int _bitsToInt(List<int> bits) {
    int value = 0;
    for (final b in bits) {
      value = (value << 1) | b;
    }
    return value;
  }

  List<int> _bitsToBytes(List<int> bits) {
    final bytes = <int>[];
    for (int i = 0; i < bits.length; i += 8) {
      int byte = 0;
      for (int j = 0; j < 8; j++) {
        if (i + j < bits.length) {
          byte = (byte << 1) | bits[i + j];
        }
      }
      bytes.add(byte);
    }
    return bytes;
  }
}
