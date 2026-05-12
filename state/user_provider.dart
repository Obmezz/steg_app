import 'package:flutter/material.dart';
import '../services/user_repository.dart';

class UserProvider extends ChangeNotifier {
  final UserRepository _userRepo = UserRepository();
  Map<String, dynamic>? _currentUser;

  Map<String, dynamic>? get currentUser => _currentUser;

  void setCurrentUser(Map<String, dynamic>? user) {
    _currentUser = user;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    if (_currentUser != null) {
      final updated = await _userRepo.getUser(_currentUser!['username']);
      _currentUser = updated;
      notifyListeners();
    }
  }

  Future<void> updateProfile({required String newUsername, String? profilePicture}) async {
    if (_currentUser == null) return;
    
    await _userRepo.updateProfile(
      _currentUser!['username'],
      newUsername,
      profilePicture,
    );
    
    await refreshUser();
  }
}
