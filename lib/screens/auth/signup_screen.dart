import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalakritiapp/models/user_role.dart';
import 'package:kalakritiapp/providers/auth_provider.dart';
import 'package:kalakritiapp/screens/auth/login_screen.dart';
import 'package:kalakritiapp/screens/home_screen.dart';
import 'package:kalakritiapp/screens/seller/seller_setup_screen.dart';
import 'package:kalakritiapp/services/auth_service.dart';
import 'package:kalakritiapp/widgets/custom_button.dart';
import 'package:kalakritiapp/widgets/custom_text_field.dart';
import 'package:kalakritiapp/widgets/loading_overlay.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  UserRole _selectedRole = UserRole.buyer;
  
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    // Validate form
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get the AuthService from the provider
      final authService = ref.read(authServiceProvider);
      
      // Attempt signup
      final userCredential = await authService.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        role: _selectedRole,
      );
      
      // If successful, navigate based on role
      if (mounted) {
        // Small delay to ensure Firebase auth state is fully updated
        await Future.delayed(const Duration(milliseconds: 300));
        
        if (_selectedRole == UserRole.seller) {
          // Navigate to seller setup screen
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => SellerSetupScreen(
                user: userCredential.user!,
                isNewUser: true,
              ),
            ),
            (route) => false,
          );
        } else {
          // Navigate to home screen for buyers
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      // Handle authentication errors
      setState(() {
        _errorMessage = _getErrorMessage(e.code);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      
      // When signing in with Google, we need to specify the selected role too
      final userCredential = await authService.signInWithGoogle(
        selectedRole: _selectedRole,
      );
      
      if (userCredential != null && mounted) {
        final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
        
        if (isNewUser && _selectedRole == UserRole.seller) {
          // Navigate to seller setup screen for new sellers
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => SellerSetupScreen(
                user: userCredential.user!,
                isNewUser: true,
              ),
            ),
            (route) => false,
          );
        } else {
          // Navigate to home screen for buyers or existing users
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Google sign-in failed. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Map Firebase error codes to user-friendly messages
  String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'email-already-in-use':
        return 'This email is already in use by another account.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'weak-password':
        return 'The password is too weak.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App logo or image
                Center(
                  child: Text(
                    'कलाकृति',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Page title
                Text(
                  'Create Account',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                
                // Subtitle
                Text(
                  'Please fill in the information below to create your account',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // Error message if any
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red[700]),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Role selection
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'I want to:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Role options
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedRole = UserRole.buyer;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _selectedRole == UserRole.buyer
                                      ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _selectedRole == UserRole.buyer
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.grey.shade300,
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.shopping_cart,
                                      color: _selectedRole == UserRole.buyer
                                          ? Theme.of(context).colorScheme.primary
                                          : Colors.grey,
                                      size: 36,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Buy Products',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _selectedRole == UserRole.buyer
                                            ? Theme.of(context).colorScheme.primary
                                            : Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedRole = UserRole.seller;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _selectedRole == UserRole.seller
                                      ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _selectedRole == UserRole.seller
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.grey.shade300,
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.store,
                                      color: _selectedRole == UserRole.seller
                                          ? Theme.of(context).colorScheme.primary
                                          : Colors.grey,
                                      size: 36,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Sell Products',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _selectedRole == UserRole.seller
                                            ? Theme.of(context).colorScheme.primary
                                            : Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Sign-up form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Name field
                      CustomTextField(
                        controller: _nameController,
                        hintText: 'Full Name',
                        prefixIcon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Email field
                      CustomTextField(
                        controller: _emailController,
                        hintText: 'Email',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Phone field
                      CustomTextField(
                        controller: _phoneController,
                        hintText: 'Phone Number (Optional)',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      
                      // Password field
                      CustomTextField(
                        controller: _passwordController,
                        hintText: 'Password',
                        prefixIcon: Icons.lock_outline,
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Confirm password field
                      CustomTextField(
                        controller: _confirmPasswordController,
                        hintText: 'Confirm Password',
                        prefixIcon: Icons.lock_outline,
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      
                      // Sign up button
                      CustomButton(
                        text: 'Create Account',
                        onPressed: _signUp,
                      ),
                      const SizedBox(height: 16),
                      
                      // Or divider
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Colors.grey[300],
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Or',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Colors.grey[300],
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Google sign-in button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: Icon(
                            Icons.g_mobiledata,
                            size: 24,
                            color: Colors.red,
                          ),
                          label: const Text('Sign up with Google'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                          onPressed: _signInWithGoogle,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account?',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      child: Text(
                        'Log In',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 