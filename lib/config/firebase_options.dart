// File: lib/config/firebase_options.dart

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static const FirebaseOptions currentPlatform = android;

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyAwikQf1uigBcnZsbcNHhf18g_5Lg9Be44",
    appId: "1:874343811496:android:5514c44c3317652bc6359d",
    messagingSenderId: "874343811496",
    projectId: "lockalista",
    storageBucket: "lockalista.firebasestorage.app",
  );
}
