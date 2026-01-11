// lib/core/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// Login with email and password
  Future<User?> login(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return result.user;
  }

  /// Register a new user with email, password, and full name
  /// Every new user gets role = 'user' by default
  Future<User?> register(String email, String password, String name) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = result.user;

    if (user != null) {
      // Update Firebase Auth display name
      await user.updateDisplayName(name);

      // Save user info in Firestore with default role
      await _db.collection('users').doc(user.uid).set({
        'name': name,
        'email': email,
        'role': 'user', // ✅ default role
        'createdAt': FieldValue.serverTimestamp(),
        'bannedUntil': null, // optional, for future ban feature
      });
    }

    return user;
  }

  /// Logout current user
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Current logged-in user
  User? get currentUser => _auth.currentUser;
}
