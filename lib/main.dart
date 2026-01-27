import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

import 'config/firebase_options.dart';
import 'config/theme.dart';
import 'routing/app_router.dart';
import 'core/utils/theme_notifier.dart';

final logger = Logger(printer: PrettyPrinter());

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    logger.i("Firebase initialized successfully");
  } catch (e, stack) {
    logger.e("Firebase initialization failed", e, stack);
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = context.watch<ThemeNotifier>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Local App',

      // 🌙 Global themes
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeNotifier.themeMode,

      // 🔁 Routing
      onGenerateRoute: AppRouter().generateRoute,
      initialRoute: '/',
      home: const AuthChecker(),
    );
  }
}

/// Checks if user is logged in
class AuthChecker extends StatelessWidget {
  const AuthChecker({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // ⏳ Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ✅ Logged in → Home
        if (snapshot.hasData) {
          return AppRouter().homeRedirect();
        }

        // ❌ Not logged in → Login
        return AppRouter().loginRedirect();
      },
    );
  }
}
