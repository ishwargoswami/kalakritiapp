import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service class to handle authentication related operations
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Keys for shared preferences
  static const String _emailKey = 'email';
  static const String _rememberMeKey = 'rememberMe';

  /// Get the current authenticated user
  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Save email if remember me is enabled
      if (rememberMe) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_emailKey, email);
        await prefs.setBool(_rememberMeKey, true);
      } else {
        // Clear saved credentials if remember me is not checked
        await clearSavedCredentials();
      }
      
      // Update user's last login timestamp
      if (userCredential.user != null) {
        try {
          await _firestore.collection('users').doc(userCredential.user!.uid).update({
            'lastLogin': FieldValue.serverTimestamp(),
            'lastLoginDevice': await _getDeviceInfo(),
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
    String? phoneNumber,
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
            'phoneNumber': phoneNumber,
            'createdAt': FieldValue.serverTimestamp(),
            'lastLogin': FieldValue.serverTimestamp(),
            'registrationDevice': await _getDeviceInfo(),
            'favoriteProducts': [],
            'shippingAddresses': [],
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

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Begin the interactive sign-in process
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User canceled the sign-in flow
        return null;
      }
      
      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      // Check if this is a new user
      final bool isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
      
      if (userCredential.user != null) {
        // Update or create the user document in Firestore
        try {
          final userDoc = _firestore.collection('users').doc(userCredential.user!.uid);
          
          if (isNewUser) {
            // Create new user document
            await userDoc.set({
              'uid': userCredential.user!.uid,
              'email': userCredential.user!.email,
              'name': userCredential.user!.displayName,
              'photoURL': userCredential.user!.photoURL,
              'createdAt': FieldValue.serverTimestamp(),
              'lastLogin': FieldValue.serverTimestamp(),
              'registrationDevice': await _getDeviceInfo(),
              'authProvider': 'google',
              'favoriteProducts': [],
              'shippingAddresses': [],
            });
          } else {
            // Update existing user's login info
            await userDoc.update({
              'lastLogin': FieldValue.serverTimestamp(),
              'lastLoginDevice': await _getDeviceInfo(),
            });
          }
        } catch (firestoreError) {
          print('Firestore operation failed: $firestoreError');
        }
      }
      
      return userCredential;
    } catch (e) {
      print('Google sign-in error: $e');
      rethrow;
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    try {
      // Sign out from Google if signed in with Google
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      
      // Sign out from Firebase
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
    String? phoneNumber,
  }) async {
    try {
      final user = _auth.currentUser;
      
      if (user != null) {
        // Update auth profile
        if (displayName != null) {
          await user.updateDisplayName(displayName);
        }
        
        if (photoURL != null) {
          await user.updatePhotoURL(photoURL);
        }
        
        // Update Firestore document
        try {
          final Map<String, dynamic> userData = {};
          
          if (displayName != null && displayName.isNotEmpty) {
            userData['name'] = displayName;
          }
          
          if (photoURL != null && photoURL.isNotEmpty) {
            userData['photoURL'] = photoURL;
          }
          
          if (phoneNumber != null) {
            userData['phoneNumber'] = phoneNumber;
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

  /// Get saved email for "Remember Me" functionality
  Future<String?> getSavedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool(_rememberMeKey) ?? false;
      
      if (rememberMe) {
        return prefs.getString(_emailKey);
      }
      return null;
    } catch (e) {
      print('Error getting saved email: $e');
      return null;
    }
  }

  /// Get remember me status
  Future<bool> getRememberMeStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_rememberMeKey) ?? false;
    } catch (e) {
      print('Error getting remember me status: $e');
      return false;
    }
  }

  /// Clear saved credentials
  Future<void> clearSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_emailKey);
      await prefs.remove(_rememberMeKey);
    } catch (e) {
      print('Error clearing saved credentials: $e');
    }
  }

  /// Get device information
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    // This is a simplified version. In a real app, you would use a package like device_info_plus
    return {
      'platform': 'Flutter',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
} 