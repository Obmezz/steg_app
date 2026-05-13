import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/contact_model.dart';
import '../../core/security/fingerprint.dart';
import '../../state/contact_provider.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool _isScanned = false;
  late MobileScannerController controller;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      formats: [BarcodeFormat.qrCode],
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _handleCapture(String code) async {
    if (_isScanned) return;
    
    setState(() {
      _isScanned = true;
    });

    try {
      ContactModel contact;
      
      try {
        // Try parsing JSON first
        final data = jsonDecode(code);
        final fingerprint = Fingerprint.generate(data["publicKey"]);
        contact = ContactModel(
          name: data["name"] ?? "Unknown",
          publicKey: data["publicKey"],
          fingerprint: fingerprint,
          isVerified: true,
        );
      } catch (_) {
        // Fallback: Check if it's a name|key format or raw key
        if (code.contains('|')) {
          final parts = code.split('|');
          contact = ContactModel(
            name: parts[0],
            publicKey: parts[1],
            fingerprint: Fingerprint.generate(parts[1]),
            isVerified: true,
          );
        } else {
          contact = ContactModel(
            name: "New Contact",
            publicKey: code,
            fingerprint: Fingerprint.generate(code),
            isVerified: true,
          );
        }
      }

      // Add to provider immediately so it's saved to DB
      if (mounted) {
        await context.read<ContactProvider>().addContact(contact);
        if (mounted) {
          Navigator.pop(context, contact);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanned = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Invalid QR Code: $e")),
        );
      }
    }
  }

  Future<void> _scanFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) return;

      final BarcodeCapture? capture = await controller.analyzeImage(image.path);
      if (capture != null && capture.barcodes.isNotEmpty) {
        final code = capture.barcodes.first.rawValue;
        if (code != null) {
          await _handleCapture(code);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No QR code found in the selected image")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gallery error: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Scan Public Key", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black54,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.image_outlined),
            tooltip: "Scan from Gallery",
            onPressed: _scanFromGallery,
          ),
          IconButton(
            icon: const Icon(Icons.flash_on),
            tooltip: "Toggle Flash",
            onPressed: () => controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios_rounded),
            tooltip: "Switch Camera",
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              final barcode = capture.barcodes.firstOrNull;
              if (barcode != null && barcode.rawValue != null && !_isScanned) {
                _handleCapture(barcode.rawValue!);
              }
            },
          ),
          
          // Scanner Overlay (Cutout)
          ColorFiltered(
            colorFilter: const ColorFilter.mode(
              Colors.black54,
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    height: 250,
                    width: 250,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Border for the cutout
          Align(
            alignment: Alignment.center,
            child: Container(
              height: 250,
              width: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _isScanned ? Colors.green : Colors.white,
                  width: 4,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: _isScanned
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.green),
                    )
                  : null,
            ),
          ),

          // Instructions
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  _isScanned ? "Processing..." : "Align QR code within the frame",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
