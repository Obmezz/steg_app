import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/contact_provider.dart';
import '../../state/language_provider.dart';
import '../../models/contact_model.dart';
import '../qr/qr_scanner_screen.dart';
import '../../core/security/fingerprint.dart';

class ContactSelectionScreen extends StatelessWidget {
  const ContactSelectionScreen({super.key});

  void _showManualInputDialog(BuildContext context, LanguageProvider lang) {
    final nameController = TextEditingController();
    final keyController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        title: Text(lang.translate('add_contact_manual')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: lang.translate('contact_name'),
                hintText: "e.g. Alice",
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: keyController,
              decoration: InputDecoration(
                labelText: lang.translate('public_key'),
                hintText: lang.translate('paste_public_key'),
              ),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(lang.translate('cancel').toUpperCase()),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty && keyController.text.trim().isNotEmpty) {
                final contact = ContactModel(
                  name: nameController.text.trim(),
                  publicKey: keyController.text.trim(),
                  fingerprint: Fingerprint.generate(keyController.text.trim()),
                );
                context.read<ContactProvider>().addContact(contact);
                Navigator.pop(dialogContext); // Close dialog
                Navigator.pop(context, contact); // Return contact to the screen that opened this one
              }
            },
            child: Text(lang.translate('add_select').toUpperCase()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contacts = context.watch<ContactProvider>().contacts;
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('select_recipient')),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt_rounded),
            tooltip: lang.translate('scan_qr'),
            onPressed: () async {
              final result = await Navigator.push<ContactModel>(
                context,
                MaterialPageRoute(builder: (context) => const QRScannerScreen()),
              );
              if (result != null && context.mounted) {
                Navigator.pop(context, result);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_note_rounded),
            tooltip: lang.translate('enter_manually'),
            onPressed: () => _showManualInputDialog(context, lang),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          lang.translate('select_contact_info'),
                          style: const TextStyle(fontSize: 13, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          Expanded(
            child: contacts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_search_rounded, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          lang.translate('no_contacts'),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(lang.translate('scan_qr_prompt')),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final result = await Navigator.push<ContactModel>(
                              context,
                              MaterialPageRoute(builder: (context) => const QRScannerScreen()),
                            );
                            if (result != null && context.mounted) {
                              Navigator.pop(context, result);
                            }
                          },
                          icon: const Icon(Icons.camera_alt_rounded),
                          label: Text(lang.translate('scan_qr_code')),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () => _showManualInputDialog(context, lang),
                          icon: const Icon(Icons.keyboard_rounded),
                          label: Text(lang.translate('enter_manually')),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: contacts.length,
                    itemBuilder: (context, i) {
                      final contact = contacts[i];
                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                            child: Text(
                              contact.name[0].toUpperCase(),
                              style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(contact.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            "${lang.translate('fingerprint')}: ${contact.fingerprint.substring(0, 10)}...",
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => Navigator.pop(context, contact),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: contacts.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push<ContactModel>(
                  context,
                  MaterialPageRoute(builder: (context) => const QRScannerScreen()),
                );
                if (result != null && context.mounted) {
                  Navigator.pop(context, result);
                }
              },
              icon: const Icon(Icons.camera_alt_rounded),
              label: Text(lang.translate('scan_new')),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }
}
