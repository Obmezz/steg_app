import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class BiometricService {
  final LocalAuthentication auth = LocalAuthentication();

  /// Checks if any form of device authentication is available (Biometrics or PIN/Pattern/Password)
  Future<bool> isAuthAvailable() async {
    try {
      final bool canCheckBiometrics = await auth.canCheckBiometrics;
      final bool isDeviceSupported = await auth.isDeviceSupported();
      return canCheckBiometrics || isDeviceSupported;
    } on PlatformException catch (e) {
      debugPrint("BiometricService: Error checking auth availability: $e");
      return false;
    }
  }

  /// Checks if actual biometric hardware is available and enrolled
  Future<bool> hasEnrolledBiometrics() async {
    try {
      final List<BiometricType> availableBiometrics = await auth.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } on PlatformException catch (e) {
      debugPrint("BiometricService: Error getting available biometrics: $e");
      return false;
    }
  }

  Future<bool> authenticate() async {
    try {
      if (!await isAuthAvailable()) {
        debugPrint("BiometricService: No authentication method available on this device.");
        return false;
      }

      return await auth.authenticate(
        localizedReason: 'Please authenticate to proceed securely',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // This is key: it allows fallback to PIN/Pattern/Password
          useErrorDialogs: true,
        ),
      );
    } on PlatformException catch (e) {
      debugPrint("BiometricService: Authentication error: $e");
      return false;
    }
  }
}
