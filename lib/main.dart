import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'core/localization/app_localizations.dart';
import 'providers/providers.dart';
import 'services/services.dart';
import 'models/models.dart';
import 'screens/auth/login_screen.dart';
import 'screens/regular_user/regular_user_home_screen.dart';
import 'screens/employee/employee_home_screen.dart';
import 'screens/admin/admin_home_screen.dart';
import 'screens/manager/manager_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  final prefs = await SharedPreferences.getInstance();
  final savedLang = prefs.getString('language') ?? 'ar';

  runApp(AtharApp(initialLocale: Locale(savedLang)));
}

class AtharApp extends StatelessWidget {
  final Locale initialLocale;

  const AtharApp({super.key, required this.initialLocale});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => ReportsProvider()),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) {
          return MaterialApp(
            title: 'Athar - أثر',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            locale: localeProvider.locale,
            supportedLocales: const [
              Locale('en'),
              Locale('ar'),
            ],
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) {
              return Directionality(
                textDirection: localeProvider.isArabic
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                child: child!,
              );
            },
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    _checkInitialAuth();
  }

  Future<void> _checkInitialAuth() async {
    // Wait for initial auth check to complete
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() => _initializing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        debugPrint('🟢 [AuthWrapper] Building... isLoggedIn: ${authProvider.isLoggedIn}, initializing: $_initializing');

        // Only show splash during initial app load, not during login
        if (_initializing && authProvider.isLoading) {
          debugPrint('🟢 [AuthWrapper] Initial load - showing SplashScreen');
          return const SplashScreen();
        }

        if (authProvider.isLoggedIn) {
          debugPrint('🟢 [AuthWrapper] Logged in! Role: ${authProvider.currentUser?.role}');
          return _getHomeScreen(authProvider.currentUser!.role);
        }

        debugPrint('🟢 [AuthWrapper] Not logged in - showing LoginScreen');
        return const LoginScreen();
      },
    );
  }

  Widget _getHomeScreen(UserRole role) {
    debugPrint('🟢 [AuthWrapper] Getting home screen for role: $role');
    switch (role) {
      case UserRole.employee:
        return const EmployeeHomeScreen();
      case UserRole.admin:
        return const AdminHomeScreen();
      case UserRole.manager:
        return const ManagerHomeScreen();
      default:
        return const RegularUserHomeScreen();
    }
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B6B3A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Center(
                child: Text(
                  'أثر',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B6B3A),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Athar',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Smart Lost & Found System',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
