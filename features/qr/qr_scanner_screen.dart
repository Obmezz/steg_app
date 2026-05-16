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

class _QRScannerScreenState extends State<QRScannerScreen> with WidgetsBindingObserver {
  bool _isScanned = false;
  bool _isProcessing = false;
  
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    formats: [BarcodeFormat.qrCode],
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!controller.value.isInitialized) return;
    switch (state) {
      case AppLifecycleState.resumed:
        controller.start();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        controller.stop();
        break;
      default:
        break;
    }
  }

  Future<void> _handleCapture(String code) async {
    if (_isScanned || _isProcessing) return;
    
    setState(() {
      _isScanned = true;
      _isProcessing = true;
    });

    // Stop scanner immediately to prevent double-scanning
    await controller.stop();

    try {
      ContactModel contact;
      try {
        final data = jsonDecode(code);
        contact = ContactModel(
          name: data["name"] ?? "Unknown",
          publicKey: data["publicKey"],
          fingerprint: Fingerprint.generate(data["publicKey"]),
          isVerified: true,
        );
      } catch (_) {
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

      if (mounted) {
        await context.read<ContactProvider>().addContact(contact);
        if (mounted) Navigator.pop(context, contact);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanned = false;
          _isProcessing = false;
        });
        controller.start(); // Restart if failed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Invalid QR Code: $e")),
        );
      }
    }
  }

  Future<void> _scanFromGallery() async {
    if (_isProcessing) return;
    
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) return;

      setState(() => _isProcessing = true);
      
      final BarcodeCapture? capture = await controller.analyzeImage(image.path);
      
      if (capture != null && capture.barcodes.isNotEmpty) {
        final code = capture.barcodes.first.rawValue;
        if (code != null) {
          await _handleCapture(code);
        }
      } else {
        if (mounted) {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No QR code found in selected image")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.image_search),
            tooltip: "Pick from Gallery",
            onPressed: _scanFromGallery,
          ),
          ValueListenableBuilder(
            valueListenable: controller,
            builder: (context, state, child) {
              if (!state.isInitialized) return const SizedBox.shrink();
              return IconButton(
                icon: Icon(
                  state.torchState == TorchState.on ? Icons.flash_on : Icons.flash_off,
                  color: state.torchState == TorchState.unavailable ? Colors.grey : Colors.white,
                ),
                onPressed: state.torchState == TorchState.unavailable 
                  ? null 
                  : () => controller.toggleTorch(),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              final barcode = capture.barcodes.firstOrNull;
              if (barcode != null && barcode.rawValue != null) {
                _handleCapture(barcode.rawValue!);
              }
            },
            errorBuilder: (context, error) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 60),
                    const SizedBox(height: 16),
                    Text(
                      "Scanner Error: ${error.errorCode.name}",
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => controller.start(),
                      child: const Text("RETRY"),
                    ),
                  ],
                ),
              );
            },
          ),
          // Scanner Overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _isScanned ? Colors.green : Colors.white54, 
                  width: 3
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: _isProcessing
                  ? const Center(child: CircularProgressIndicator(color: Colors.green))
                  : null,
            ),
          ),
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                _isProcessing ? "Processing..." : "Align QR code within the frame",
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
