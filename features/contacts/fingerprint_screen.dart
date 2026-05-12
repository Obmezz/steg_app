import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/contact_model.dart';
import '../../state/contact_provider.dart';

class FingerprintScreen extends StatelessWidget {

  final ContactModel contact;

  const FingerprintScreen({super.key, required this.contact});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text("Verify ${contact.name}"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            const Text(
              "Compare this fingerprint with your contact:",
              style: TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 20),

            SelectableText(
              _format(contact.fingerprint),
              style: const TextStyle(
                fontSize: 18,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: () {
                context.read<ContactProvider>().verifyContact(contact);
                Navigator.pop(context);
              },
              child: const Text("Mark Verified ✅"),
            ),
          ],
        ),
      ),
    );
  }

  String _format(String f) {
    return f.replaceAllMapped(
      RegExp(r".{4}"),
          (m) => "${m.group(0)} ",
    );
  }
}