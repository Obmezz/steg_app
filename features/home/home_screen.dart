import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/routes.dart';
import '../../services/image_service.dart';
import '../../state/language_provider.dart';
import '../../state/security_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final imageService = ImageService();
    final colorScheme = Theme.of(context).colorScheme;
    final lang = Provider.of<LanguageProvider>(context);
    final security = Provider.of<SecurityProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('app_title')),
        actions: [
          IconButton(
            icon: Icon(
              security.themeMode == ThemeMode.dark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              color: colorScheme.primary,
            ),
            onPressed: () {
              final newMode = security.themeMode == ThemeMode.dark
                  ? ThemeMode.light
                  : ThemeMode.dark;
              security.setThemeMode(newMode);
            },
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.person_rounded, color: colorScheme.primary),
              onPressed: () => Navigator.pushNamed(context, Routes.profile),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(context, Routes.settings),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang.translate('welcome'),
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    lang.translate('tagline'),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  _HomeCard(
                    title: lang.translate('send_secret'),
                    subtitle: lang.translate('send_secret_sub'),
                    icon: Icons.auto_awesome_rounded,
                    color: colorScheme.primary,
                    onTap: () => Navigator.pushNamed(context, Routes.chat),
                  ),
                  const SizedBox(height: 20),
                  _HomeCard(
                    title: lang.translate('reveal_secret'),
                    subtitle: lang.translate('reveal_secret_sub'),
                    icon: Icons.vpn_key_rounded,
                    color: const Color(0xFF10B981),
                    onTap: () async {
                      final File? image = await imageService.pickImage();
                      if (image != null && context.mounted) {
                        Navigator.pushNamed(context, Routes.chat, arguments: image);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang.translate('quick_actions').toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _QuickAction(
                        icon: Icons.people_rounded,
                        label: lang.translate('contacts'),
                        onTap: () => Navigator.pushNamed(context, Routes.contacts),
                      ),
                      const SizedBox(width: 12),
                      _QuickAction(
                        icon: Icons.history_rounded,
                        label: lang.translate('history'),
                        onTap: () => Navigator.pushNamed(context, Routes.history),
                      ),
                      const SizedBox(width: 12),
                      _QuickAction(
                        icon: Icons.camera_alt_rounded,
                        label: lang.translate('scan_qr'),
                        onTap: () => Navigator.pushNamed(context, Routes.contactSelection),
                      ),
                      const SizedBox(width: 12),
                      _QuickAction(
                        icon: Icons.help_outline_rounded,
                        label: lang.translate('help'),
                        onTap: () => _showHelpDialog(context, lang),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context, LanguageProvider lang) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.help_outline_rounded, color: Colors.blue),
            const SizedBox(width: 12),
            Text(lang.translate('help')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(lang.translate('help_step_1'), style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(lang.translate('help_desc_1')),
              const SizedBox(height: 12),
              Text(lang.translate('help_step_2'), style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(lang.translate('help_desc_2')),
              const SizedBox(height: 12),
              Text(lang.translate('help_step_3'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              Text(
                lang.translate('help_desc_3'),
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
              ),
              Text(lang.translate('help_desc_3_warn')),
            ],
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

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              Icon(icon, color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.8) ?? Colors.blueGrey.shade700),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _HomeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: color.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(icon, size: 32, color: color),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.shade300),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
