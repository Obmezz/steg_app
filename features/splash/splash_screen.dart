import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/routes.dart';
import '../../services/user_repository.dart';
import '../../services/biometric_service.dart';
import '../../state/user_provider.dart';
import '../../state/security_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  final _userRepo = UserRepository();
  final _biometricService = BiometricService();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    _initializeApp();
  }

  void _initializeApp() async {
    final navigator = Navigator.of(context);
    final userProvider = context.read<UserProvider>();
    final security = context.read<SecurityProvider>();

    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final hasUser = await _userRepo.hasUsers();
    
    if (hasUser) {
      if (security.useBiometrics) {
        final authenticated = await _biometricService.authenticate();
        if (authenticated && mounted) {
          final users = await UserRepository().db.then((db) => db.query('users', limit: 1));
          if (users.isNotEmpty && mounted) {
            userProvider.setCurrentUser(users.first);
            navigator.pushReplacementNamed(Routes.home);
            return;
          }
        }
      } else {
        // Biometrics not enabled, but user exists. 
        // Force login to be safe, or auto-login if no bio is the choice?
        // Usually if bio is off, you go to login screen for password.
        navigator.pushReplacementNamed(Routes.login);
        return;
      }
    }

    if (mounted) {
      navigator.pushReplacementNamed(Routes.login);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary,
              colorScheme.secondary,
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        )
                      ],
                    ),
                    child: Icon(
                      Icons.shield_rounded,
                      size: 80,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    "SECURE STEGO",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "PRIVACY REDEFINED",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
