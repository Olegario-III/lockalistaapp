import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'config/firebase_options.dart';
import 'routing/app_router.dart';

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

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Local App',
      onGenerateRoute: AppRouter().generateRoute, // central router
      initialRoute: '/', // default route
      home: const AuthChecker(), // fallback auth check
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
        // Loading spinner while waiting
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If user is logged in → go to HomePage
        if (snapshot.hasData) {
          return AppRouter().homeRedirect();
        }

        // Otherwise → go to LoginPage
        return AppRouter().loginRedirect();
      },
    );
  }
}
