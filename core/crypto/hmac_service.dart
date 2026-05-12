import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

class HMACService {

  /// Generate HMAC-SHA256
  String generate(String data, Uint8List key) {

    final hmac = HMac(SHA256Digest(), 64)
      ..init(KeyParameter(key));

    final result = hmac.process(
      Uint8List.fromList(utf8.encode(data)),
    );

    return base64Encode(result);
  }

  /// Verify HMAC
  bool verify(String data, String signature, Uint8List key) {

    final newSig = generate(data, key);
    return newSig == signature;
  }
}