import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/helpers.dart';
import '../../services/user_repository.dart';
import '../../state/language_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _usernameController = TextEditingController();
  final _answerController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _userRepo = UserRepository();
  
  bool _isLoading = false;
  bool _userFound = false;
  String? _securityQuestion;
  bool _answerCorrect = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  void _lookupUser() async {
    if (_usernameController.text.isEmpty) return;
    
    final lang = context.read<LanguageProvider>();
    setState(() => _isLoading = true);
    try {
      final user = await _userRepo.getUser(_usernameController.text);
      if (mounted) {
        if (user != null) {
          setState(() {
            _userFound = true;
            _securityQuestion = user['securityQuestion'] ?? lang.translate('no_security_question');
          });
        } else {
          UiHelpers.showSnackBar(context, lang.translate('username_not_found'), isError: true);
        }
      }
    } catch (e) {
      if (mounted) UiHelpers.showSnackBar(context, lang.translate('operation_failed'), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _verifyAnswer() async {
    final lang = context.read<LanguageProvider>();
    setState(() => _isLoading = true);
    try {
      final user = await _userRepo.getUser(_usernameController.text);
      if (mounted) {
        if (user != null && user['securityAnswer'] == _answerController.text) {
          setState(() => _answerCorrect = true);
        } else {
          UiHelpers.showSnackBar(context, lang.translate('incorrect_answer'), isError: true);
        }
      }
    } catch (e) {
      if (mounted) UiHelpers.showSnackBar(context, lang.translate('operation_failed'), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _resetPassword() async {
    final lang = context.read<LanguageProvider>();
    if (_newPasswordController.text != _confirmPasswordController.text) {
      UiHelpers.showSnackBar(context, lang.translate('passwords_mismatch'), isError: true);
      return;
    }

    final pass = _newPasswordController.text;
    final regex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$');
    if (!regex.hasMatch(pass)) {
      UiHelpers.showSnackBar(context, lang.translate('pass_requirement'), isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _userRepo.resetPassword(_usernameController.text, _newPasswordController.text);
      if (mounted) {
        UiHelpers.showSnackBar(context, lang.translate('password_reset_success'));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) UiHelpers.showSnackBar(context, lang.translate('operation_failed'), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('reset_password')),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                lang.translate('account_recovery'),
                style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              if (!_userFound) ...[
                Text(
                  lang.translate('find_account_prompt'),
                  style: textTheme.bodyLarge?.copyWith(color: colorScheme.outline),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: lang.translate('username'),
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _lookupUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                  child: _isLoading 
                      ? SizedBox(
                          height: 20, 
                          width: 20, 
                          child: CircularProgressIndicator(color: colorScheme.onPrimary, strokeWidth: 2)
                        ) 
                      : Text(lang.translate('find_account').toUpperCase()),
                ),
              ],

              if (_userFound && !_answerCorrect) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang.translate('security_question'),
                        style: textTheme.labelLarge?.copyWith(color: colorScheme.primary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _securityQuestion ?? '', 
                        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _answerController,
                  decoration: InputDecoration(
                    labelText: lang.translate('security_answer'),
                    prefixIcon: const Icon(Icons.question_answer_outlined),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _verifyAnswer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                  child: _isLoading 
                      ? SizedBox(
                          height: 20, 
                          width: 20, 
                          child: CircularProgressIndicator(color: colorScheme.onPrimary, strokeWidth: 2)
                        ) 
                      : Text(lang.translate('verify_answer').toUpperCase()),
                ),
              ],

              if (_answerCorrect) ...[
                Text(
                  lang.translate('set_new_password_prompt'),
                  style: textTheme.bodyLarge?.copyWith(color: colorScheme.outline),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _newPasswordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: lang.translate('new_password'),
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
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: lang.translate('confirm_new_password'),
                    prefixIcon: const Icon(Icons.lock_reset),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        color: colorScheme.outline,
                      ),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                  child: _isLoading 
                      ? SizedBox(
                          height: 20, 
                          width: 20, 
                          child: CircularProgressIndicator(color: colorScheme.onPrimary, strokeWidth: 2)
                        ) 
                      : Text(lang.translate('reset_password').toUpperCase()),
                ),
              ],
              
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(lang.translate('cancel')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
