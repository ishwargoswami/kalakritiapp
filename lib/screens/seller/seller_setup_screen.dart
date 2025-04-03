import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalakritiapp/providers/auth_provider.dart';
import 'package:kalakritiapp/screens/home_screen.dart';
import 'package:kalakritiapp/services/auth_service.dart';
import 'package:kalakritiapp/widgets/custom_button.dart';
import 'package:kalakritiapp/widgets/custom_text_field.dart';
import 'package:kalakritiapp/widgets/loading_overlay.dart';

class SellerSetupScreen extends ConsumerStatefulWidget {
  final User user;
  final bool isNewUser;
  
  const SellerSetupScreen({
    required this.user,
    this.isNewUser = false,
    super.key,
  });

  @override
  ConsumerState<SellerSetupScreen> createState() => _SellerSetupScreenState();
}

class _SellerSetupScreenState extends ConsumerState<SellerSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _businessDescriptionController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveBusiness() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Update the user's profile with business information
      final authService = ref.read(authServiceProvider);
      
      await authService.updateUserProfile(
        businessName: _businessNameController.text.trim(),
        businessDescription: _businessDescriptionController.text.trim(),
      );
      
      // Navigate to home screen after successful setup
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error setting up your seller account. Please try again.';
      });
      print('Error in seller setup: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        appBar: AppBar(
          title: const Text('Set Up Your Shop'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome message
                Text(
                  'Welcome, ${widget.user.displayName}!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                
                Text(
                  'Let\'s set up your seller profile so you can start listing your craft products.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Display any error message
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
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Business information form
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Business name field
                      const Text(
                        'Business Name',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      CustomTextField(
                        controller: _businessNameController,
                        hintText: 'Enter your shop or business name',
                        prefixIcon: Icons.store,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your business name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      
                      // Business description field
                      const Text(
                        'Business Description',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      TextFormField(
                        controller: _businessDescriptionController,
                        decoration: InputDecoration(
                          hintText: 'Tell us about your business, products, and craftsmanship...',
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a description for your business';
                          }
                          return null;
                        },
                        maxLines: 5,
                        maxLength: 500,
                      ),
                      const SizedBox(height: 32),
                      
                      // Save button
                      CustomButton(
                        text: 'Complete Setup',
                        onPressed: _saveBusiness,
                      ),
                      const SizedBox(height: 16),
                      
                      // Skip for now button (will take them to home but as a seller)
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const HomeScreen()),
                            (route) => false,
                          );
                        },
                        child: const Text('Skip for now'),
                      ),
                    ],
                  ),
                ),
                
                // Benefits and information
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),
                
                Text(
                  'Benefits of being a seller:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Benefits list
                _buildBenefitItem(
                  icon: Icons.handshake,
                  title: 'Direct Customer Connection',
                  description: 'Build relationships with customers who appreciate your craft.',
                ),
                _buildBenefitItem(
                  icon: Icons.payments,
                  title: 'Earn on Your Terms',
                  description: 'Set your own prices and manage your own inventory.',
                ),
                _buildBenefitItem(
                  icon: Icons.insights,
                  title: 'Business Insights',
                  description: 'Access analytics to understand customer preferences and sales patterns.',
                ),
                _buildBenefitItem(
                  icon: Icons.local_shipping,
                  title: 'Shipping Integration',
                  description: 'Our platform handles shipping logistics for a seamless experience.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 