import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../state/user_provider.dart';
import '../../state/language_provider.dart';
import '../../core/security/key_storage.dart';
import '../../services/image_service.dart';
import '../../services/biometric_service.dart';
import '../../app/routes.dart';
import '../../state/security_provider.dart';
import '../../core/security/fingerprint.dart';
import '../../utils/helpers.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _keyStorage = KeyStorage();
  final _imageService = ImageService();
  final _biometricService = BiometricService();
  final _usernameController = TextEditingController();
  
  String? _publicKey;
  String? _username;
  bool _isEditing = false;
  File? _newProfilePic;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final key = await _keyStorage.getPublicKey();
    if (!mounted) return;
    
    final user = context.read<UserProvider>().currentUser;
    if (user != null) {
      _usernameController.text = user['username'];
      _username = user['username'];
    }
    setState(() {
      _publicKey = key;
    });
  }

  void _saveProfile(LanguageProvider lang) async {
    final userProvider = context.read<UserProvider>();
    final newUsername = _usernameController.text;
    final profilePicPath = _newProfilePic?.path ?? userProvider.currentUser?['profilePicture'];

    await userProvider.updateProfile(
      newUsername: newUsername,
      profilePicture: profilePicPath,
    );
    
    if (mounted) {
      setState(() => _isEditing = false);
      UiHelpers.showSnackBar(context, lang.translate('profile_updated'));
    }
  }

  void _handleBiometricToggle(bool value) async {
    final securityProvider = context.read<SecurityProvider>();
    final lang = context.read<LanguageProvider>();

    if (value) {
      final canAuthenticate = await _biometricService.isAuthAvailable();
      if (!canAuthenticate) {
        if (mounted) {
          UiHelpers.showSnackBar(context, lang.translate('auth_failed'), isError: true);
        }
        return;
      }

      final authenticated = await _biometricService.authenticate();
      if (authenticated) {
        await securityProvider.setUseBiometrics(true);
        if (mounted) {
          UiHelpers.showSnackBar(context, lang.translate('profile_updated'));
        }
      } else {
        if (mounted) {
          UiHelpers.showSnackBar(context, lang.translate('biometric_failed'), isError: true);
        }
      }
    } else {
      await securityProvider.setUseBiometrics(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().currentUser;
    final lang = context.watch<LanguageProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    if (user == null) return Scaffold(body: Center(child: Text(lang.translate('not_logged_in'))));

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('profile')),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check_rounded : Icons.edit_rounded),
            onPressed: () {
              if (_isEditing) {
                _saveProfile(lang);
              } else {
                setState(() => _isEditing = true);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: colorScheme.primary, width: 3),
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      backgroundImage: _newProfilePic != null
                          ? FileImage(_newProfilePic!)
                          : (user['profilePicture'] != null
                              ? FileImage(File(user['profilePicture']))
                              : null),
                      child: (user['profilePicture'] == null && _newProfilePic == null)
                          ? Icon(Icons.person, size: 60, color: colorScheme.outline)
                          : null,
                    ),
                  ),
                  if (_isEditing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () async {
                          final picked = await _imageService.pickImage();
                          if (picked != null) {
                            setState(() => _newProfilePic = picked);
                          }
                        },
                        child: CircleAvatar(
                          backgroundColor: colorScheme.primary,
                          radius: 20,
                          child: Icon(Icons.camera_alt, color: colorScheme.onPrimary, size: 20),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              if (_isEditing)
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: lang.translate('username'),
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                )
              else
                Text(
                  user['username'],
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
              const SizedBox(height: 4),
              Text(
                user['fullName'],
                style: TextStyle(fontSize: 16, color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 40),
              _buildSectionHeader(lang.translate('security_info'), colorScheme),
              const SizedBox(height: 12),
              _buildSettingsCard(context, lang, colorScheme),
              const SizedBox(height: 24),
              _buildSectionHeader(lang.translate('public_identity'), colorScheme),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_publicKey != null) ...[
                      Row(
                        children: [
                          Icon(Icons.fingerprint_rounded, color: colorScheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            lang.translate('fingerprint'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          Fingerprint.generate(_publicKey!),
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSecondaryContainer,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Row(
                      children: [
                        Icon(Icons.vpn_key_outlined, color: colorScheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          lang.translate('your_public_key'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      child: SelectableText(
                        _publicKey ?? lang.translate('loading_key'),
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        IconButton.filled(
                          onPressed: _publicKey == null ? null : () => _showQRDialog(lang),
                          icon: const Icon(Icons.qr_code_2_rounded),
                          tooltip: lang.translate('show_qr_code'),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          onPressed: () => Navigator.pushNamed(context, '/contact-selection'),
                          icon: const Icon(Icons.camera_alt_rounded),
                          tooltip: lang.translate('scan_qr'),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          onPressed: _publicKey == null
                              ? null
                              : () {
                                  Clipboard.setData(ClipboardData(text: _publicKey!));
                                  UiHelpers.showSnackBar(context, lang.translate('copied_to_clipboard'));
                                },
                          icon: const Icon(Icons.copy_rounded),
                          tooltip: lang.translate('copy'),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          onPressed: _publicKey == null
                              ? null
                              : () => Share.share(_publicKey!, subject: 'My Public Key'),
                          icon: const Icon(Icons.share_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      lang.translate('share_key_info'),
                      style: TextStyle(fontSize: 12, color: colorScheme.outline),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.read<UserProvider>().setCurrentUser(null);
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: Text(lang.translate('logout').toUpperCase()),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: colorScheme.error),
                    foregroundColor: colorScheme.error,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, LanguageProvider lang, ColorScheme colorScheme) {
    final securityProvider = context.watch<SecurityProvider>();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          SwitchListTile(
            secondary: Icon(Icons.fingerprint_rounded, color: colorScheme.primary),
            title: Text(lang.translate('fingerprint')),
            subtitle: Text(lang.translate('use_biometrics')),
            value: securityProvider.useBiometrics,
            onChanged: (val) => _handleBiometricToggle(val),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ColorScheme colorScheme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: colorScheme.outline,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  void _showQRDialog(LanguageProvider lang) {
    final qrData = jsonEncode({
      "name": _username ?? "User",
      "publicKey": _publicKey,
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.translate('your_public_key')),
        content: SizedBox(
          width: 300,
          height: 300,
          child: Center(
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 250.0,
              backgroundColor: Colors.white,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang.translate('got_it').toUpperCase()),
          ),
        ],
      ),
    );
  }
}
