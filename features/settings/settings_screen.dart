import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../state/language_provider.dart';
import '../../state/user_provider.dart';
import '../../state/security_provider.dart';
import '../../app/routes.dart';
import '../../services/biometric_service.dart';
import '../../services/message_repository.dart';
import '../../services/user_repository.dart';

import '../../utils/helpers.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _userRepo = UserRepository();
  final _bio = BiometricService();

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final security = Provider.of<SecurityProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text(lang.translate('settings'))),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(lang.translate('language')),
            subtitle: Text(lang.currentLocale.languageCode == 'en' 
                ? lang.translate('english') 
                : lang.translate('amharic')),
            onTap: () => _showLanguageDialog(context, lang),
          ),
          ListTile(
            leading: const Icon(Icons.security),
            title: Text(lang.translate('encryption_settings')),
            onTap: () => _showEncryptionDialog(context, lang),
          ),
          ListTile(
            leading: const Icon(Icons.password),
            title: Text(lang.translate('change_password')),
            onTap: () => _showChangePasswordDialog(context, lang, userProvider),
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: Text(lang.translate('notifications')),
            onTap: () => _showNotificationsDialog(context, lang),
          ),
          ListTile(
            leading: const Icon(Icons.fingerprint),
            title: Text(lang.translate('use_biometrics')),
            trailing: Switch(
              value: security.useBiometrics,
              onChanged: (val) async {
                if (val) {
                  final canAuth = await _bio.isAuthAvailable();
                  if (!canAuth) {
                    if (context.mounted) {
                      UiHelpers.showSnackBar(context, lang.translate('auth_failed'), isError: true);
                    }
                    return;
                  }
                  final authenticated = await _bio.authenticate();
                  if (authenticated) {
                    await security.setUseBiometrics(true);
                  }
                } else {
                  await security.setUseBiometrics(false);
                }
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: Text(lang.translate('wipe_data'), style: const TextStyle(color: Colors.red)),
            onTap: () => _showWipeDataDialog(context, lang),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(lang.translate('logout')),
            onTap: () {
              context.read<UserProvider>().setCurrentUser(null);
              Navigator.of(context).pushNamedAndRemoveUntil(Routes.login, (route) => false);
            },
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, LanguageProvider lang, UserProvider userProvider) async {
    final user = userProvider.currentUser;
    if (user == null) return;

    // First, verify security question and biometrics
    bool verified = false;
    
    // 1. Biometrics
    final bioAuth = await _bio.authenticate();
    if (!context.mounted) return;
    if (!bioAuth) {
      UiHelpers.showSnackBar(context, lang.translate('auth_failed'), isError: true);
      return;
    }

    // 2. Security Question
    if (context.mounted) {
      final answer = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          final controller = TextEditingController();
          return AlertDialog(
            scrollable: true,
            title: Text(lang.translate('security_question')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user['securityQuestion'] ?? ""),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(labelText: lang.translate('security_answer')),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(lang.translate('cancel'))),
              TextButton(onPressed: () => Navigator.pop(dialogContext, controller.text), child: Text(lang.translate('got_it'))),
            ],
          );
        }
      );

      if (context.mounted) {
        if (answer != null && answer == user['securityAnswer']) {
          verified = true;
        } else if (answer != null) {
          UiHelpers.showSnackBar(context, lang.translate('incorrect_answer'), isError: true);
        }
      }
    }

    if (verified && context.mounted) {
      // Show password change form
      showDialog(
        context: context,
        builder: (context) {
          final passController = TextEditingController();
          final confirmController = TextEditingController();
          bool obscurePass = true;
          bool obscureConfirm = true;

          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                scrollable: true,
                title: Text(lang.translate('change_password')),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: passController,
                      obscureText: obscurePass,
                      decoration: InputDecoration(
                        labelText: lang.translate('new_password'),
                        suffixIcon: IconButton(
                          icon: Icon(obscurePass ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => obscurePass = !obscurePass),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: confirmController,
                      obscureText: obscureConfirm,
                      decoration: InputDecoration(
                        labelText: lang.translate('confirm_new_password'),
                        suffixIcon: IconButton(
                          icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => obscureConfirm = !obscureConfirm),
                        ),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: Text(lang.translate('cancel'))),
                  TextButton(
                    onPressed: () async {
                      if (passController.text.length < 8) {
                        UiHelpers.showSnackBar(context, lang.translate('pass_requirement'), isError: true);
                        return;
                      }
                      if (passController.text != confirmController.text) {
                        if (context.mounted) UiHelpers.showSnackBar(context, "Passwords do not match", isError: true);
                        return;
                      }
                      await _userRepo.resetPassword(user['username'], passController.text);
                      await userProvider.refreshUser();
                      if (context.mounted) {
                        Navigator.pop(context);
                        UiHelpers.showSnackBar(context, lang.translate('password_changed'));
                      }
                    },
                    child: Text(lang.translate('got_it')),
                  ),
                ],
              );
            },
          );
        },
      );
    }
  }

  void _showEncryptionDialog(BuildContext context, LanguageProvider lang) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.translate('encryption_settings')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lang.translate('encryption_info_title'), style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(lang.translate('encryption_info_body')),
          ],
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

  void _showNotificationsDialog(BuildContext context, LanguageProvider lang) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(lang.translate('notifications_settings')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: Text(lang.translate('push_notifications')),
                subtitle: Text(lang.translate('notify_on_receive')),
                value: true, // Mock value
                onChanged: (val) {},
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(lang.translate('got_it').toUpperCase()),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, LanguageProvider lang) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.translate('language')),
        content: RadioGroup<String>(
          groupValue: lang.currentLocale.languageCode,
          onChanged: (val) {
            if (val != null) lang.setLanguage(val);
            Navigator.pop(context);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                onTap: () {
                  lang.setLanguage('en');
                  Navigator.pop(context);
                },
                leading: const Radio<String>(
                  value: 'en',
                ),
                title: Text(lang.translate('english')),
              ),
              ListTile(
                onTap: () {
                  lang.setLanguage('am');
                  Navigator.pop(context);
                },
                leading: const Radio<String>(
                  value: 'am',
                ),
                title: Text(lang.translate('amharic')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showWipeDataDialog(BuildContext context, LanguageProvider lang) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.translate('wipe_data')),
        content: Text(lang.translate('wipe_data_confirm')),
        actions: [
          TextButton(
            child: Text(lang.translate('cancel')),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text(lang.translate('wipe_all'), style: const TextStyle(color: Colors.red)),
            onPressed: () async {
              // 1. Clear databases
              final messageRepo = MessageRepository();
              await messageRepo.clearMessages();
              
              final userRepo = UserRepository();
              final dbPath = await getDatabasesPath();
              
              // Close and delete user database
              final uDb = await userRepo.db;
              await uDb.close();
              await deleteDatabase(join(dbPath, 'users.db'));
              
              // Close and delete chat/message database
              final mDb = await messageRepo.db;
              await mDb.close();
              await deleteDatabase(join(dbPath, 'chat.db'));

              // 2. Clear all Shared Preferences (Language, Security, etc.)
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              
              // 3. Reset Providers
              if (context.mounted) {
                context.read<UserProvider>().setCurrentUser(null);
              }
              
              // 4. Redirect to splash
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(Routes.splash, (route) => false);
                UiHelpers.showSnackBar(context, "All data has been wiped successfully.");
              }
            },
          ),
        ],
      ),
    );
  }
}
