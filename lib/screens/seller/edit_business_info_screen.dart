import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalakritiapp/models/user.dart';
import 'package:kalakritiapp/providers/auth_provider.dart';
import 'package:kalakritiapp/services/auth_service.dart';
import 'package:kalakritiapp/widgets/custom_button.dart';
import 'package:kalakritiapp/widgets/custom_text_field.dart';
import 'package:kalakritiapp/widgets/loading_overlay.dart';

class EditBusinessInfoScreen extends ConsumerStatefulWidget {
  final UserModel userData;

  const EditBusinessInfoScreen({
    super.key,
    required this.userData,
  });

  @override
  ConsumerState<EditBusinessInfoScreen> createState() => _EditBusinessInfoScreenState();
}

class _EditBusinessInfoScreenState extends ConsumerState<EditBusinessInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Text controllers
  late TextEditingController _businessNameController;
  late TextEditingController _businessDescriptionController;
  late TextEditingController _businessAddressController;
  
  // Form state
  bool _isLoading = false;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _businessNameController = TextEditingController(text: widget.userData.businessName ?? '');
    _businessDescriptionController = TextEditingController(text: widget.userData.businessDescription ?? '');
    _businessAddressController = TextEditingController(text: widget.userData.businessAddress ?? '');
  }
  
  @override
  void dispose() {
    _businessNameController.dispose();
    _businessDescriptionController.dispose();
    _businessAddressController.dispose();
    super.dispose();
  }
  
  Future<void> _saveBusinessInfo() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final authService = ref.read(authServiceProvider);
      
      // Update business info
      await authService.updateUserProfile(
        businessName: _businessNameController.text,
        businessDescription: _businessDescriptionController.text,
        businessAddress: _businessAddressController.text,
      );
      
      // Invalidate user data provider to refresh profile data
      ref.refresh(userDataProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Business information updated successfully')),
        );
        Navigator.pop(context, true); // Return true to indicate update was successful
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error updating business information: $e';
      });
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
        appBar: AppBar(
          title: const Text('Edit Business Information'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
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
                
                // Business Information
                const Text(
                  'Business Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                CustomTextField(
                  controller: _businessNameController,
                  hintText: 'Business Name',
                  prefixIcon: Icons.business,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your business name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                CustomTextField(
                  controller: _businessAddressController,
                  hintText: 'Business Address',
                  prefixIcon: Icons.location_on,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your business address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                CustomTextField(
                  controller: _businessDescriptionController,
                  hintText: 'Business Description',
                  prefixIcon: Icons.description,
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a business description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                
                // Verification status indicator
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: widget.userData.isVerifiedSeller 
                        ? Colors.green.shade50 
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: widget.userData.isVerifiedSeller 
                          ? Colors.green.shade200 
                          : Colors.orange.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        widget.userData.isVerifiedSeller 
                            ? Icons.verified 
                            : Icons.pending,
                        color: widget.userData.isVerifiedSeller 
                            ? Colors.green 
                            : Colors.orange,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.userData.isVerifiedSeller 
                                  ? 'Verified Seller' 
                                  : 'Verification Pending',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: widget.userData.isVerifiedSeller 
                                    ? Colors.green 
                                    : Colors.orange,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.userData.isVerifiedSeller 
                                  ? 'Your business is verified on our platform.' 
                                  : 'We are currently reviewing your business information. This process may take 1-3 business days.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Save Button
                Center(
                  child: CustomButton(
                    text: 'Save Changes',
                    onPressed: _saveBusinessInfo,
                    width: double.infinity,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 