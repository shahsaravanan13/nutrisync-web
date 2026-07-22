import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Initialize fresh profile for new users
  Future<void> createInitialProfile(String uid, String name, String email) async {
    final profileRef = _db.collection('users').doc(uid).collection('profile').doc('data');
    
    // Default values as per requirements
    await profileRef.set({
      'name': name,
      'email': email,
      'calories': 0,
      'protein': 0,
      'carbs': 0,
      'fat': 0,
      'waterIntake': 0,
      'weight': 0,
      'height': 0,
      'bmi': 0,
      'healthScore': 0,
      'dailyStreak': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Get Profile Data Stream
  Stream<DocumentSnapshot> getUserProfileStream(String uid) {
    return _db.collection('users').doc(uid).collection('profile').doc('data').snapshots();
  }
  
  // Update Profile Data
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).collection('profile').doc('data').update(data);
  }
}
