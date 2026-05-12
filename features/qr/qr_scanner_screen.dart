import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/contact_model.dart';
import '../../core/security/fingerprint.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
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
    if (_latestCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No QR code detected yet. Point the camera at a QR code."),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }
    if (_isScanned) return;
    _isScanned = true;

    try {
      ContactModel contact;
      // Attempt to parse JSON if it's from our QR generator
      try {
        final data = jsonDecode(_latestCode!);
        final fingerprint = Fingerprint.generate(data["publicKey"]);
        contact = ContactModel(
          name: data["name"],
          publicKey: data["publicKey"],
          fingerprint: fingerprint,
          isVerified: true,
        );
      } catch (_) {
        // Fallback to pipe-separated or raw key
        final parts = _latestCode!.split('|');
        if (parts.length >= 2) {
          contact = ContactModel(
            name: parts[0],
            publicKey: parts[1],
            fingerprint: Fingerprint.generate(parts[1]),
            isVerified: true,
          );
        } else {
          contact = ContactModel(
            name: "New Contact",
            publicKey: _latestCode!,
            fingerprint: Fingerprint.generate(_latestCode!),
            isVerified: true,
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, contact);
      }
    } catch (e) {
      _isScanned = false;
      debugPrint("Error parsing QR: $e");
    }
  }

  Future<void> _scanFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    final BarcodeCapture? capture = await controller.analyzeImage(image.path);
    if (capture != null && capture.barcodes.isNotEmpty) {
      final code = capture.barcodes.first.rawValue;
      if (code != null) {
        setState(() {
          _latestCode = code;
        });
        _handleCapture();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No QR code found in the selected image")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan Public Key"),
        actions: [
          IconButton(
            icon: const Icon(Icons.image_outlined),
            tooltip: "Scan from Gallery",
            onPressed: _scanFromGallery,
          ),
          IconButton(
            color: Colors.white,
            icon: const Icon(Icons.flash_on),
            iconSize: 28.0,
            onPressed: () => controller.toggleTorch(),
          ),
          IconButton(
            color: Colors.white,
            icon: const Icon(Icons.flip_camera_ios_rounded),
            iconSize: 28.0,
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final String? code = barcode.rawValue;
                if (code != null && code.isNotEmpty) {
                  setState(() {
                    _latestCode = code;
                  });
                }
              }
            },
          ),
          // Camera icon overlay
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white.withOpacity(0.5),
                  size: 40,
                ),
                const SizedBox(height: 8),
                Text(
                  "CAMERA ACTIVE",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          // QR Frame
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _latestCode != null ? Colors.green : Colors.white,
                  width: _latestCode != null ? 4 : 2,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: _latestCode != null
                  ? const Center(
                      child: Icon(Icons.check_circle, color: Colors.green, size: 50),
                    )
                  : null,
            ),
          ),
          // Capture Button Area
          Positioned(
            bottom: 40,
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
                            "QR CODE READY",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                GestureDetector(
                  onTap: _handleCapture,
                  child: Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _latestCode == null ? Colors.white54 : Colors.white,
                        width: 4,
                      ),
                    ),
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 60,
                        width: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _latestCode == null 
                              ? Colors.white.withOpacity(0.3) 
                              : Colors.white,
                        ),
                        child: Icon(
                          Icons.qr_code_scanner,
                          color: _latestCode == null ? Colors.white70 : Colors.black,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _latestCode == null ? "SCANNING..." : "TAP TO CAPTURE",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
