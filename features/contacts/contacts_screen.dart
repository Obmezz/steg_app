import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/routes.dart';
import '../../state/contact_provider.dart';
import '../../models/contact_model.dart';
import 'fingerprint_screen.dart';

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final contacts = context.watch<ContactProvider>().contacts;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Contacts"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddContactDialog(context),
          ),
        ],
      ),
      body: contacts.isEmpty
          ? _buildEmptyState(context)
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: contacts.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final c = contacts[i];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: colorScheme.primaryContainer,
                      child: Text(
                        c.name[0].toUpperCase(),
                        style: TextStyle(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      c.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Row(
                      children: [
                        Icon(
                          c.isVerified ? Icons.verified_rounded : Icons.warning_amber_rounded,
                          size: 14,
                          color: c.isVerified ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          c.isVerified ? "Verified" : "Unverified Identity",
                          style: TextStyle(
                            color: c.isVerified ? Colors.green : Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.security_rounded),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FingerprintScreen(contact: c),
                              ),
                            );
                          },
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showEditContactDialog(context, c);
                            } else if (value == 'delete') {
                              _confirmDelete(context, c);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit Name'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete Contact', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline_rounded, size: 80, color: colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text(
            "No contacts yet",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Add a public key to start messaging",
            style: TextStyle(color: colorScheme.outline),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddContactDialog(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text("Add Contact"),
          ),
        ],
      ),
    );
  }

  void _showAddContactDialog(BuildContext context) {
    Navigator.pushNamed(context, Routes.contactSelection);
  }

  void _showEditContactDialog(BuildContext context, ContactModel contact) {
    final controller = TextEditingController(text: contact.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Contact Name"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Name"),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                final newContact = ContactModel(
                  name: controller.text,
                  publicKey: contact.publicKey,
                  fingerprint: contact.fingerprint,
                  isVerified: contact.isVerified,
                );
                context.read<ContactProvider>().updateContact(contact.name, newContact);
                Navigator.pop(context);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, ContactModel contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Contact"),
        content: Text("Are you sure you want to delete '${contact.name}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              context.read<ContactProvider>().removeContact(contact.name);
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
