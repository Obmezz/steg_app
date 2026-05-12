import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/security/key_storage.dart';

class QRGenerator extends StatelessWidget {

  final String name;

  const QRGenerator({super.key, required this.name});

  @override
  Widget build(BuildContext context) {

    final storage = KeyStorage();

    return FutureBuilder(
      future: storage.getPublicKey(),
      builder: (context, snapshot) {

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = jsonEncode({
          "name": name,
          "publicKey": snapshot.data!,
        });

        return Scaffold(
          appBar: AppBar(title: const Text("My QR")),
          body: Center(
            child: QrImageView(
              data: data,
              size: 250,
            ),
          ),
        );
      },
    );
  }
}