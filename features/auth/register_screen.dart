import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../services/user_repository.dart';
import '../../core/security/key_storage.dart';
import '../../core/crypto/rsa_service.dart';
import '../../utils/helpers.dart';
import '../../state/language_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _securityQuestionController = TextEditingController();
  final _securityAnswerController = TextEditingController();
  
  final _userRepo = UserRepository();
  final _keyStorage = KeyStorage();
  final _rsaService = RSAService();

  bool _isLoading = false;
  bool _permissionsGranted = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  void _checkPermissions() async {
    final camera = await Permission.camera.status;
    final storage = await Permission.storage.status;
    final photos = await Permission.photos.status;
    
    if (mounted) {
      setState(() {
        _permissionsGranted = camera.isGranted && (storage.isGranted || photos.isGranted);
      });
    }
  }

  void _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.storage,
      Permission.photos,
    ].request();

    bool allGranted = true;
    if (statuses[Permission.camera] != PermissionStatus.granted) {
      allGranted = false;
    }
    if (statuses[Permission.storage] != PermissionStatus.granted && 
        statuses[Permission.photos] != PermissionStatus.granted) {
      allGranted = false;
    }

    if (mounted) {
      setState(() => _permissionsGranted = allGranted);
      if (allGranted) {
        UiHelpers.showSnackBar(context, context.read<LanguageProvider>().translate('permissions_granted'));
      }
    }
  }

  void _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        // 1. Register user in DB
        await _userRepo.register(
          username: _usernameController.text,
          fullName: _fullNameController.text,
          age: int.parse(_ageController.text),
          password: _passwordController.text,
          securityQuestion: _securityQuestionController.text,
          securityAnswer: _securityAnswerController.text,
        );

        // 2. Generate RSA Identity for this device/user
        final keyPair = _rsaService.generateKeyPair();
        await _keyStorage.savePrivateKey(KeyHelper.encodePrivateKey(keyPair.privateKey));
        await _keyStorage.savePublicKey(KeyHelper.encodePublicKey(keyPair.publicKey));

        if (mounted) {
          UiHelpers.showSnackBar(context, "Registration Successful! Your secure identity has been created.");
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          UiHelpers.showSnackBar(context, Provider.of<LanguageProvider>(context, listen: false).translate('operation_failed'), isError: true);
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  bool _isPasswordValid(String password) {
    final regex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$');
    return regex.hasMatch(password);
  }

  Widget _buildPermissionSection(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final isGranted = _permissionsGranted;
    
    final Color sectionColor = isGranted ? Colors.green : Colors.orange;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: sectionColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: sectionColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isGranted ? Icons.verified_user_rounded : Icons.privacy_tip_rounded,
                color: sectionColor,
              ),
              const SizedBox(width: 12),
              Text(
                lang.translate('grant_permissions'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            lang.translate('permissions_desc'),
            style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isGranted ? null : _requestPermissions,
              icon: Icon(isGranted ? Icons.check : Icons.security_rounded),
              label: Text(isGranted 
                ? lang.translate('permissions_granted').toUpperCase()
                : lang.translate('grant_all').toUpperCase()),
              style: OutlinedButton.styleFrom(
                foregroundColor: sectionColor,
                side: BorderSide(color: sectionColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValidationIndicator(String label, bool isValid) {
    return Row(
      children: [
        Icon(
          isValid ? Icons.check_circle : Icons.cancel,
          color: isValid ? Colors.green : Colors.red,
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(color: isValid ? Colors.green : Colors.red, fontSize: 12),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final pass = _passwordController.text;
    final hasUpper = pass.contains(RegExp(r'[A-Z]'));
    final hasLower = pass.contains(RegExp(r'[a-z]'));
    final hasDigit = pass.contains(RegExp(r'[0-9]'));
    final hasSpecial = pass.contains(RegExp(r'[@$!%*?&]'));
    final hasMinLength = pass.length >= 8;

    return Scaffold(
      appBar: AppBar(title: const Text("Create Account")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Join Secure Stego",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              Text(
                "Create an account to start secure messaging",
                style: TextStyle(color: Theme.of(context).colorScheme.outline),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: "Full Name",
                  prefixIcon: Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: "Username",
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(
                  labelText: "Age",
                  prefixIcon: Icon(Icons.cake_outlined),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                obscureText: _obscurePassword,
                onChanged: (v) => setState(() {}),
                validator: (v) => !_isPasswordValid(v!) ? "Password does not meet requirements" : null,
              ),
              const SizedBox(height: 8),
              _buildValidationIndicator("At least 8 characters", hasMinLength),
              _buildValidationIndicator("Upper & Lower case", hasUpper && hasLower),
              _buildValidationIndicator(r"Numbers & Symbols (@$!%*?&)", hasDigit && hasSpecial),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: "Confirm Password",
                  prefixIcon: const Icon(Icons.lock_reset),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                ),
                obscureText: _obscureConfirmPassword,
                validator: (v) => v != _passwordController.text ? "Passwords do not match" : null,
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                "Security Recovery",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                "Used to reset your password if forgotten.",
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _securityQuestionController,
                decoration: const InputDecoration(
                  labelText: "Security Question (e.g. Your first pet's name?)",
                  prefixIcon: Icon(Icons.help_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _securityAnswerController,
                decoration: const InputDecoration(
                  labelText: "Your Answer",
                  prefixIcon: Icon(Icons.question_answer_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              _buildPermissionSection(context),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isLoading || !_permissionsGranted) ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text("REGISTER & GENERATE KEYS", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              if (!_permissionsGranted)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text(
                    "Please grant permissions to continue",
                    style: TextStyle(color: Colors.red, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                "Note: Registration will generate a unique RSA key pair for your secure communication. This may take a moment.",
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
