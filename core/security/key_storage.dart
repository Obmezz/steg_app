import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class KeyStorage {

  final _storage = const FlutterSecureStorage();

  Future<void> savePrivateKey(String key) async {
    await _storage.write(key: "private", value: key);
  }

  Future<void> savePublicKey(String key) async {
    await _storage.write(key: "public", value: key);
  }

  Future<String?> getPrivateKey() async {
    return _storage.read(key: "private");
  }

  Future<String?> getPublicKey() async {
    return _storage.read(key: "public");
  }
}