import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // Get Current User
  User? get currentUser => _auth.currentUser;

  // Auth State Stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign Up
  Future<User?> signUpWithEmail(String name, String email, String password) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      User? user = credential.user;
      if (user != null) {
        await user.updateDisplayName(name);
        // Ensure the displayName is updated locally immediately
        await user.reload(); 
        
        // Create initial default profile in Firestore
        await _firestoreService.createInitialProfile(user.uid, name, email);
      }
      return user;
    } catch (e) {
      rethrow;
    }
  }

  // Log In
  Future<User?> loginWithEmail(String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } catch (e) {
      rethrow;
    }
  }

  // Log Out
  Future<void> logout() async {
    await _auth.signOut();
    // Clear all locally cached user data
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); 
  }
}
