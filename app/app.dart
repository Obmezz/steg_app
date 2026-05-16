import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import '../state/language_provider.dart';
import '../state/security_provider.dart';
import 'routes.dart';
import 'theme.dart';

/// The root widget of the Secure Stego Chat application.
///
/// This widget sets up the overall application structure, including:
/// * Localization support (English and Amharic).
/// * Theme configuration (Light and Dark modes) driven by [SecurityProvider].
/// * Routing configuration using [Routes].
/// * State management integration for language and security settings.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  /// Builds the [MaterialApp] with the necessary providers and configurations.
  /// 
  /// Uses [LanguageProvider] for localization and [SecurityProvider] for theme management.
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final securityProvider = Provider.of<SecurityProvider>(context);

    return MaterialApp(
      key: const ValueKey('stego_app_root'),
      navigatorKey: Routes.navigatorKey,
      scaffoldMessengerKey: Routes.messengerKey,
      title: 'Secure Stego Chat',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: securityProvider.themeMode,
      locale: languageProvider.currentLocale,
      supportedLocales: const [
        Locale('en'),
        Locale('am'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routes: Routes.routes,
      initialRoute: Routes.splash,
      debugShowCheckedModeBanner: false,
    );
  }
}
