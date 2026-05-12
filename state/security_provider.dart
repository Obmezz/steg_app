import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityProvider extends ChangeNotifier {
  static const String _biometricKey = 'use_biometrics';
  static const String _themeKey = 'theme_mode';
  bool _useBiometrics = false;
  ThemeMode _themeMode = ThemeMode.system;

  bool get useBiometrics => _useBiometrics;
  ThemeMode get themeMode => _themeMode;

  SecurityProvider();

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _useBiometrics = prefs.getBool(_biometricKey) ?? false;
    final themeIdx = prefs.getInt(_themeKey) ?? ThemeMode.system.index;
    _themeMode = ThemeMode.values[themeIdx];
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
    notifyListeners();
  }

  Future<void> setUseBiometrics(bool value) async {
    _useBiometrics = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricKey, value);
    notifyListeners();
  }
}
