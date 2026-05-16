import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/routes.dart';
import '../../services/user_repository.dart';
import '../../services/biometric_service.dart';
import '../../state/user_provider.dart';
import '../../state/language_provider.dart';
import '../../utils/helpers.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _userRepo = UserRepository();
  final _biometricService = BiometricService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  void _login() async {
    final lang = context.read<LanguageProvider>();
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      UiHelpers.showSnackBar(context, lang.translate('fill_all_fields'), isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = await _userRepo.login(
        _usernameController.text,
        _passwordController.text,
      );

      if (!mounted) return;

      if (!mounted) return;

      if (user != null) {
        if (context.mounted) {
          context.read<UserProvider>().setCurrentUser(user);
          Navigator.of(context).pushReplacementNamed(Routes.home);
        }
      } else {
        if (context.mounted) UiHelpers.showSnackBar(context, lang.translate('invalid_credentials'), isError: true);
      }
    } catch (e) {
      if (mounted) {
        UiHelpers.showSnackBar(context, lang.translate('operation_failed'), isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _biometricLogin() async {
    final lang = context.read<LanguageProvider>();
    try {
      final canAuth = await _biometricService.isAuthAvailable();
      if (!canAuth) {
        if (mounted) {
          UiHelpers.showSnackBar(context, lang.translate('auth_failed'), isError: true);
        }
        return;
      }

      final authenticated = await _biometricService.authenticate();
      if (!mounted) return;
      if (authenticated) {
        final db = await _userRepo.db;
        final users = await db.query('users', limit: 1);
        if (!mounted) return;
        if (users.isNotEmpty) {
          context.read<UserProvider>().setCurrentUser(users.first);
          Navigator.of(context).pushReplacementNamed(Routes.home);
        } else {
          UiHelpers.showSnackBar(context, lang.translate('no_registered_account'), isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        UiHelpers.showSnackBar(context, lang.translate('auth_failed'), isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Icon(
                      Icons.shield_rounded,
                      size: 64,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  lang.translate('welcome'),
                  style: textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  lang.translate('tagline'),
                  style: textTheme.bodyLarge?.copyWith(color: colorScheme.outline),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: lang.translate('username'),
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: lang.translate('password'),
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: colorScheme.outline,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pushNamed(context, Routes.forgotPassword),
                    child: Text(
                      lang.translate('forgot_password'),
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.onPrimary,
                          ),
                        )
                      : Text(lang.translate('login').toUpperCase()),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _biometricLogin,
                  icon: const Icon(Icons.fingerprint),
                  label: Text(lang.translate('use_biometrics').toUpperCase()),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                    side: BorderSide(color: colorScheme.primary),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      lang.translate('no_account'),
                      style: TextStyle(color: colorScheme.outline),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, Routes.register),
                      child: Text(
                        lang.translate('register'),
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => lang.setLanguage('en'),
                      child: Text(
                        "English", 
                        style: TextStyle(
                          fontWeight: lang.currentLocale.languageCode == 'en' ? FontWeight.bold : FontWeight.normal,
                          color: lang.currentLocale.languageCode == 'en' ? colorScheme.primary : colorScheme.onSurfaceVariant,
                        )
                      ),
                    ),
                    Text("|", style: TextStyle(color: colorScheme.outlineVariant)),
                    TextButton(
                      onPressed: () => lang.setLanguage('am'),
                      child: Text(
                        "አማርኛ", 
                        style: TextStyle(
                          fontWeight: lang.currentLocale.languageCode == 'am' ? FontWeight.bold : FontWeight.normal,
                          color: lang.currentLocale.languageCode == 'am' ? colorScheme.primary : colorScheme.onSurfaceVariant,
                        )
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
