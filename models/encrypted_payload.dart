import 'dart:typed_data';

class EncryptedPayload {

  final Uint8List encryptedKey;
  final Uint8List encryptedMessage;
  final Uint8List iv;
  final Uint8List signature;

  EncryptedPayload({
    required this.encryptedKey,
    required this.encryptedMessage,
    required this.iv,
    required this.signature,
  });

  /// Convert to JSON-safe format
  Map<String, dynamic> toJson() {
    return {
      "key": encryptedKey.toList(),
      "data": encryptedMessage.toList(),
      "iv": iv.toList(),
      "signature": signature.toList(),
    };
  }

  /// Restore from JSON
  factory EncryptedPayload.fromJson(Map<String, dynamic> json) {
    return EncryptedPayload(
      encryptedKey: Uint8List.fromList(List<int>.from(json["key"])),
      encryptedMessage: Uint8List.fromList(List<int>.from(json["data"])),
      iv: Uint8List.fromList(List<int>.from(json["iv"])),
      signature: Uint8List.fromList(List<int>.from(json["signature"])),
    );
  }

  EncryptedPayload copyWith({
    Uint8List? encryptedKey,
    Uint8List? encryptedMessage,
    Uint8List? iv,
    Uint8List? signature,
  }) {
    return EncryptedPayload(
      encryptedKey: encryptedKey ?? this.encryptedKey,
      encryptedMessage: encryptedMessage ?? this.encryptedMessage,
      iv: iv ?? this.iv,
      signature: signature ?? this.signature,
    );
  }
}