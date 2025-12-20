import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'config/firebase_options.dart';
import 'routing/app_router.dart';
import 'config/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp( MyApp());
}

class MyApp extends StatelessWidget {
  final AppRouter _router = AppRouter();

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Local App',
      theme: AppTheme.darkTheme,
      onGenerateRoute: _router.generateRoute,
      home: FutureBuilder(
        // Initialize Firebase here instead of in main()
        future: Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ),
        builder: (context, firebaseSnapshot) {
          // Still initializing Firebase
          if (firebaseSnapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            );
          }

          // Firebase initialization error
          if (firebaseSnapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text(
                        'Failed to initialize Firebase',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${firebaseSnapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => main(), // Retry by restarting the app
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // Firebase is initialized → now listen to auth state
          return StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, authSnapshot) {
              // Waiting for auth state to resolve
              if (authSnapshot.connectionState == ConnectionState.waiting ||
                  authSnapshot.connectionState == ConnectionState.active &&
                      !authSnapshot.hasData &&
                      !authSnapshot.hasError) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                );
              }

              // Auth error (rare, but possible)
              if (authSnapshot.hasError) {
                return Scaffold(
                  body: Center(
                    child: Text('Auth error: ${authSnapshot.error}'),
                  ),
                );
              }

              // Auth resolved → redirect based on login state
              if (authSnapshot.hasData) {
                return _router.homeRedirect();
              } else {
                return _router.loginRedirect();
              }
            },
          );
        },
      ),
    );
  }
}