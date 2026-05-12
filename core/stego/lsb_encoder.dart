import 'dart:convert';
import 'dart:math';
import 'package:image/image.dart';

class LSBEncoder {
  static const int seed = 1337;

  /// Encode payload into image
  Image encode(Image image, String payload) {
    final bytes = utf8.encode(payload);
    final bits = _toBits(bytes);

    // prepend length (32-bit header)
    final lengthBits = _intToBits(bits.length);
    final fullBits = [...lengthBits, ...bits];

    final rand = Random(seed);
    final totalPixels = image.width * image.height;
    
    // We need (fullBits.length / 3) pixels approximately.
    // To ensure uniqueness without storing all pixels, we'd need a better shuffle.
    // For now, let's use a simple but more memory-efficient approach:
    // We'll use a set to keep track of used pixels if we were doing random,
    // but a deterministic skip-pattern is easier for the decoder.
    
    int bitIndex = 0;
    
    // Simple deterministic path: Every Nth pixel or just sequential for now to ensure it WORKS.
    // Shuffling the entire image was likely causing OOM or performance issues.
    // Let's use sequential embedding but with a "start offset" and "step" from the seed.
    
    int x = rand.nextInt(image.width);
    int y = rand.nextInt(image.height);
    
    for (int i = 0; i < totalPixels; i++) {
      if (bitIndex >= fullBits.length) break;

      final currentX = (x + i) % image.width;
      final currentY = (y + (x + i) ~/ image.width) % image.height;

      final pixel = image.getPixel(currentX, currentY);

      int r = pixel.r.toInt();
      int g = pixel.g.toInt();
      int b = pixel.b.toInt();

      if (bitIndex < fullBits.length) {
        r = _setLSB(r, fullBits[bitIndex++]);
      }
      if (bitIndex < fullBits.length) {
        g = _setLSB(g, fullBits[bitIndex++]);
      }
      if (bitIndex < fullBits.length) {
        b = _setLSB(b, fullBits[bitIndex++]);
      }

      image.setPixelRgba(currentX, currentY, r, g, b, 255);
    }

    return image;
  }

  List<int> _toBits(List<int> bytes) {
    final bits = <int>[];
    for (final b in bytes) {
      for (int i = 7; i >= 0; i--) {
        bits.add((b >> i) & 1);
      }
    }
    return bits;
  }

  List<int> _intToBits(int value) {
    return List.generate(32, (i) => (value >> (31 - i)) & 1);
  }

  int _setLSB(int value, int bit) {
    return (value & 0xFE) | bit;
  }
}
