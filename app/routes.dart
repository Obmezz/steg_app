import 'package:flutter/material.dart';
import '../features/chat/chat_screen.dart';
import '../features/contacts/contacts_screen.dart';
import '../features/contacts/contact_selection_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/auth/forgot_password_screen.dart';
import '../features/home/home_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/history/history_screen.dart';

class Routes {
  static final navigatorKey = GlobalKey<NavigatorState>();
  static final messengerKey = GlobalKey<ScaffoldMessengerState>();
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const home = '/home';
  static const chat = '/chat';
  static const profile = '/profile';
  static const settings = '/settings';
  static const contacts = '/contacts';
  static const contactSelection = '/contact-selection';
  static const history = '/history';

  static Map<String, WidgetBuilder> routes = {
    splash: (context) => const SplashScreen(),
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
    forgotPassword: (context) => const ForgotPasswordScreen(),
    home: (context) => const HomeScreen(),
    chat: (context) => const ChatScreen(),
    profile: (context) => const ProfileScreen(),
    settings: (context) => const SettingsScreen(),
    contacts: (context) => const ContactsScreen(),
    contactSelection: (context) => const ContactSelectionScreen(),
    history: (context) => const HistoryScreen(),
  };
}
