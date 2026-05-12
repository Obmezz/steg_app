import 'package:flutter/material.dart';
import '../models/contact_model.dart';
import '../services/message_repository.dart';

class ContactProvider extends ChangeNotifier {
  final MessageRepository _repo;
  List<ContactModel> _contacts = [];

  ContactProvider(this._repo) {
    _loadContacts();
  }

  List<ContactModel> get contacts => _contacts;

  Future<void> _loadContacts() async {
    final maps = await _repo.getContacts();
    _contacts = maps.map((m) => ContactModel.fromMap(m)).toList();
    notifyListeners();
  }

  Future<void> addContact(ContactModel contact) async {
    _contacts.add(contact);
    await _repo.insertContact(contact.toMap());
    notifyListeners();
  }

  Future<void> removeContact(String name) async {
    _contacts.removeWhere((c) => c.name == name);
    await _repo.deleteContact(name);
    notifyListeners();
  }

  Future<void> updateContact(String oldName, ContactModel newContact) async {
    final index = _contacts.indexWhere((c) => c.name == oldName);
    if (index != -1) {
      _contacts[index] = newContact;
      await _repo.updateContact(oldName, newContact.toMap());
      notifyListeners();
    }
  }

  void verifyContact(ContactModel contact) {
    contact.isVerified = true;
    _repo.updateContact(contact.name, contact.toMap());
    notifyListeners();
  }

  ContactModel? getByName(String name) {
    try {
      return _contacts.firstWhere((c) => c.name == name);
    } catch (_) {
      return null;
    }
  }
}
