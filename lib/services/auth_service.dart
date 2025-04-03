import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service class to handle authentication related operations
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get the current authenticated user
  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update user's last login timestamp
      if (userCredential.user != null) {
        try {
          await _firestore.collection('users').doc(userCredential.user!.uid).update({
            'lastLogin': FieldValue.serverTimestamp(),
          });
        } catch (firestoreError) {
          // If Firestore update fails, we still want to proceed with login
          // The user is already authenticated at this point
          print('Firestore update failed: $firestoreError');
        }
      }
      
      return userCredential;
    } catch (e) {
      print('Login error: $e');
      rethrow;
    }
  }

  /// Create a new user with email and password
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Create user document in Firestore
      if (userCredential.user != null) {
        try {
          await _firestore.collection('users').doc(userCredential.user!.uid).set({
            'uid': userCredential.user!.uid,
            'email': email,
            'name': name,
            'createdAt': FieldValue.serverTimestamp(),
            'lastLogin': FieldValue.serverTimestamp(),
          });
          
          // Update display name in Firebase Auth
          await userCredential.user!.updateDisplayName(name);
        } catch (firestoreError) {
          // If Firestore creation fails, we still want to proceed with signup
          // The user is already created in Firebase Auth at this point
          print('Firestore document creation failed: $firestoreError');
        }
      }
      
      return userCredential;
    } catch (e) {
      print('Signup error: $e');
      rethrow;
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Signout error: $e');
      rethrow;
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Password reset error: $e');
      rethrow;
    }
  }

  /// Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = _auth.currentUser;
      
      if (user != null) {
        // Update auth profile
        await user.updateDisplayName(displayName);
        await user.updatePhotoURL(photoURL);
        
        // Update Firestore document
        try {
          final Map<String, dynamic> userData = {};
          
          if (displayName != null && displayName.isNotEmpty) {
            userData['name'] = displayName;
          }
          
          if (photoURL != null && photoURL.isNotEmpty) {
            userData['photoURL'] = photoURL;
          }
          
          if (userData.isNotEmpty) {
            await _firestore.collection('users').doc(user.uid).update(userData);
          }
        } catch (firestoreError) {
          // If Firestore update fails, the Auth profile is still updated
          print('Firestore profile update failed: $firestoreError');
        }
      }
    } catch (e) {
      print('Profile update error: $e');
      rethrow;
    }
  }

  /// Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final user = _auth.currentUser;
      
      if (user != null) {
        try {
          final docSnapshot = await _firestore.collection('users').doc(user.uid).get();
          return docSnapshot.data();
        } catch (firestoreError) {
          // If Firestore read fails, return null
          print('Firestore read failed: $firestoreError');
          return null;
        }
      }
      return null;
    } catch (e) {
      print('Getting user data error: $e');
      return null;
    }
  }
} 