import 'dart:convert';
import 'package:crypto/crypto.dart';

class Fingerprint {

  /// Generate fingerprint from public key
  static String generate(String publicKey) {

    final hash = sha256.convert(utf8.encode(publicKey));

    return hash.toString().substring(0, 16); // short fingerprint
  }
}