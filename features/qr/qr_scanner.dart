import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../state/contact_provider.dart';
import '../../models/contact_model.dart';
import '../../core/security/fingerprint.dart';
import 'package:provider/provider.dart';

class QRScanner extends StatefulWidget {
  const QRScanner({super.key});

  @override
  State<QRScanner> createState() => _QRScannerState();
}

class _QRScannerState extends State<QRScanner> {
  bool _isScanned = false;
  String? _latestCode;
  late MobileScannerController controller;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _handleCapture() {
    if (_latestCode == null || _isScanned) return;

    _isScanned = true;
    try {
      final data = jsonDecode(_latestCode!);
      final fingerprint = Fingerprint.generate(data["publicKey"]);

      final contact = ContactModel(
        name: data["name"],
        publicKey: data["publicKey"],
        fingerprint: fingerprint,
      );

      context.read<ContactProvider>().addContact(contact);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _isScanned = false;
      debugPrint("QR Scan Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan Contact"),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.camera_front),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              final raw = capture.barcodes.firstOrNull?.rawValue;
              if (raw != null && raw.isNotEmpty) {
                setState(() {
                  _latestCode = raw;
                });
              }
            },
          ),
          // QR Frame Feedback
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _latestCode != null ? Colors.green : Colors.white70,
                  width: _latestCode != null ? 4 : 2,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: _latestCode != null
                  ? const Center(
                      child: Icon(Icons.check_circle, color: Colors.green, size: 64),
                    )
                  : null,
            ),
          ),
          // Capture Button Area
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                if (_latestCode != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, color: Colors.white, size: 16),
                          SizedBox(width: 8),
                          Text(
                            "READY TO ADD",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                GestureDetector(
                  onTap: _latestCode == null ? null : _handleCapture,
                  child: Container(
                    height: 85,
                    width: 85,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: Center(
                      child: Container(
                        height: 65,
                        width: 65,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _latestCode == null 
                              ? Colors.white.withOpacity(0.2) 
                              : Colors.white,
                        ),
                        child: Icon(
                          Icons.person_add_alt_1,
                          color: _latestCode == null ? Colors.white54 : Colors.black,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _latestCode == null ? "SCANNING..." : "ADD CONTACT",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          // Instructions
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                _latestCode == null ? "Point camera at a QR code" : "QR Detected! Tap button to add",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
