import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kalakritiapp/models/user_role.dart';
import 'package:kalakritiapp/models/user.dart';

/// Service class to handle authentication related operations
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Keys for shared preferences
  static const String _emailKey = 'email';
  static const String _rememberMeKey = 'rememberMe';
  static const String _userRoleKey = 'userRole';

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
          
          // Save user role to shared preferences for quick access
          final userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
          if (userDoc.exists) {
            final userData = userDoc.data();
            if (userData != null && userData.containsKey('role')) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString(_userRoleKey, userData['role']);
            }
          }
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
    required UserRole role,
    String? businessName,
    String? businessDescription,
  }) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Create user document in Firestore
      if (userCredential.user != null) {
        try {
          final Map<String, dynamic> userData = {
            'uid': userCredential.user!.uid,
            'email': email,
            'name': name,
            'phoneNumber': phoneNumber,
            'role': role.toString().split('.').last,
            'createdAt': FieldValue.serverTimestamp(),
            'lastLogin': FieldValue.serverTimestamp(),
            'registrationDevice': await _getDeviceInfo(),
            'favoriteProducts': [],
            'shippingAddresses': [],
          };
          
          // Add seller-specific fields if the user is registering as a seller
          if (role == UserRole.seller) {
            userData['businessName'] = businessName;
            userData['businessDescription'] = businessDescription;
            userData['businessImages'] = [];
            userData['isVerifiedSeller'] = false;
          }
          
          await _firestore.collection('users').doc(userCredential.user!.uid).set(userData);
          
          // Update display name in Firebase Auth
          await userCredential.user!.updateDisplayName(name);
          
          // Save user role to shared preferences for quick access
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_userRoleKey, role.toString().split('.').last);
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
  Future<UserCredential?> signInWithGoogle({UserRole? selectedRole}) async {
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
            // For new users, we need to determine their role
            final UserRole role = selectedRole ?? UserRole.buyer;
            
            // Create new user document
            final Map<String, dynamic> userData = {
              'uid': userCredential.user!.uid,
              'email': userCredential.user!.email,
              'name': userCredential.user!.displayName,
              'photoURL': userCredential.user!.photoURL,
              'role': role.toString().split('.').last,
              'createdAt': FieldValue.serverTimestamp(),
              'lastLogin': FieldValue.serverTimestamp(),
              'registrationDevice': await _getDeviceInfo(),
              'authProvider': 'google',
              'favoriteProducts': [],
              'shippingAddresses': [],
            };
            
            // Add seller-specific fields if the user is registering as a seller
            if (role == UserRole.seller) {
              userData['businessName'] = '';
              userData['businessDescription'] = '';
              userData['businessImages'] = [];
              userData['isVerifiedSeller'] = false;
            }
            
            await userDoc.set(userData);
            
            // Save user role to shared preferences for quick access
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_userRoleKey, role.toString().split('.').last);
          } else {
            // Update existing user's login info
            await userDoc.update({
              'lastLogin': FieldValue.serverTimestamp(),
              'lastLoginDevice': await _getDeviceInfo(),
            });
            
            // Retrieve and save user role to shared preferences
            final docSnapshot = await userDoc.get();
            if (docSnapshot.exists) {
              final userData = docSnapshot.data();
              if (userData != null && userData.containsKey('role')) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString(_userRoleKey, userData['role']);
              }
            }
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

  /// Get the current user's role
  Future<UserRole> getCurrentUserRole() async {
    try {
      // First try to get role from shared preferences for quick access
      final prefs = await SharedPreferences.getInstance();
      final roleString = prefs.getString(_userRoleKey);
      
      if (roleString != null) {
        return UserRoleExtension.fromString(roleString);
      }
      
      // If not in prefs, get from Firestore
      final user = _auth.currentUser;
      if (user != null) {
        try {
          final docSnapshot = await _firestore.collection('users').doc(user.uid).get();
          if (docSnapshot.exists) {
            final userData = docSnapshot.data();
            if (userData != null && userData.containsKey('role')) {
              final role = UserRoleExtension.fromString(userData['role']);
              
              // Save to prefs for future quick access
              await prefs.setString(_userRoleKey, userData['role']);
              
              return role;
            }
          }
        } catch (firestoreError) {
          print('Firestore read failed: $firestoreError');
        }
      }
      
      // Default to buyer if we couldn't determine the role
      return UserRole.buyer;
    } catch (e) {
      print('Error getting user role: $e');
      return UserRole.buyer;
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    try {
      // Sign out from Google if signed in with Google
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      
      // Clear user role from shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userRoleKey);
      
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
    String? businessName,
    String? businessDescription,
    List<String>? businessImages,
    String? businessAddress,
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
          
          if (businessName != null) {
            userData['businessName'] = businessName;
          }
          
          if (businessDescription != null) {
            userData['businessDescription'] = businessDescription;
          }
          
          if (businessImages != null) {
            userData['businessImages'] = businessImages;
          }
          
          if (businessAddress != null) {
            userData['businessAddress'] = businessAddress;
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
  Future<UserModel?> getUserData() async {
    try {
      final user = _auth.currentUser;
      
      if (user != null) {
        try {
          final docSnapshot = await _firestore.collection('users').doc(user.uid).get();
          if (docSnapshot.exists) {
            return UserModel.fromFirestore(docSnapshot);
          }
          return null;
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