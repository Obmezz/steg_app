import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pointycastle/export.dart';

class UiHelpers {
  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class KeyHelper {

  static String encodePublicKey(RSAPublicKey key) {
    final data = "${key.modulus}|${key.exponent}";
    return base64Encode(data.codeUnits);
  }

  static RSAPublicKey decodePublicKey(String encoded) {
    final decoded = String.fromCharCodes(base64Decode(encoded));
    final parts = decoded.split("|");

    return RSAPublicKey(
      BigInt.parse(parts[0]),
      BigInt.parse(parts[1]),
    );
  }

  static String encodePrivateKey(RSAPrivateKey key) {
    // Basic serialization for demo purposes
    final data = "${key.modulus}|${key.privateExponent}|${key.p}|${key.q}";
    return base64Encode(data.codeUnits);
  }

  static RSAPrivateKey decodePrivateKey(String encoded) {
    final decoded = String.fromCharCodes(base64Decode(encoded));
    final parts = decoded.split("|");

    return RSAPrivateKey(
      BigInt.parse(parts[0]),
      BigInt.parse(parts[1]),
      parts.length > 2 ? BigInt.parse(parts[2]) : null,
      parts.length > 3 ? BigInt.parse(parts[3]) : null,
    );
  }
}
