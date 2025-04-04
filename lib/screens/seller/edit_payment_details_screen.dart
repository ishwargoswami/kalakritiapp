import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalakritiapp/models/user.dart';
import 'package:kalakritiapp/providers/auth_provider.dart';
import 'package:kalakritiapp/services/auth_service.dart';
import 'package:kalakritiapp/widgets/custom_button.dart';
import 'package:kalakritiapp/widgets/custom_text_field.dart';
import 'package:kalakritiapp/widgets/loading_overlay.dart';

class EditPaymentDetailsScreen extends ConsumerStatefulWidget {
  final UserModel userData;

  const EditPaymentDetailsScreen({
    super.key,
    required this.userData,
  });

  @override
  ConsumerState<EditPaymentDetailsScreen> createState() => _EditPaymentDetailsScreenState();
}

class _EditPaymentDetailsScreenState extends ConsumerState<EditPaymentDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Text controllers
  late TextEditingController _bankAccountNameController;
  late TextEditingController _bankAccountNumberController;
  late TextEditingController _bankIFSCController;
  late TextEditingController _upiIdController;
  
  // Radio value
  late String _selectedPayoutMethod;
  
  // Form state
  bool _isLoading = false;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _bankAccountNameController = TextEditingController(text: widget.userData.bankAccountName ?? '');
    _bankAccountNumberController = TextEditingController(text: widget.userData.bankAccountNumber ?? '');
    _bankIFSCController = TextEditingController(text: widget.userData.bankIFSC ?? '');
    _upiIdController = TextEditingController(text: widget.userData.upiId ?? '');
    
    // Initialize the selected payout method
    _selectedPayoutMethod = widget.userData.preferredPayoutMethod ?? 'bank';
  }
  
  @override
  void dispose() {
    _bankAccountNameController.dispose();
    _bankAccountNumberController.dispose();
    _bankIFSCController.dispose();
    _upiIdController.dispose();
    super.dispose();
  }
  
  Future<void> _savePaymentDetails() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final authService = ref.read(authServiceProvider);
      
      // Update payment details
      await authService.updateUserProfile(
        bankAccountName: _bankAccountNameController.text,
        bankAccountNumber: _bankAccountNumberController.text,
        bankIFSC: _bankIFSCController.text,
        upiId: _upiIdController.text,
        preferredPayoutMethod: _selectedPayoutMethod,
      );
      
      // Invalidate user data provider to refresh profile data
      ref.refresh(userDataProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment details updated successfully')),
        );
        Navigator.pop(context, true); // Return true to indicate update was successful
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error updating payment details: $e';
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
          title: const Text('Edit Payment Details'),
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
                
                // Payment Method Selection
                const Text(
                  'Preferred Payout Method',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Bank Account'),
                        value: 'bank',
                        groupValue: _selectedPayoutMethod,
                        onChanged: (value) {
                          setState(() {
                            _selectedPayoutMethod = value!;
                          });
                        },
                        activeColor: Theme.of(context).colorScheme.primary,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('UPI'),
                        value: 'upi',
                        groupValue: _selectedPayoutMethod,
                        onChanged: (value) {
                          setState(() {
                            _selectedPayoutMethod = value!;
                          });
                        },
                        activeColor: Theme.of(context).colorScheme.primary,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                
                const Divider(),
                const SizedBox(height: 16),
                
                // Bank Account Information
                const Text(
                  'Bank Account Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                CustomTextField(
                  controller: _bankAccountNameController,
                  hintText: 'Account Holder Name',
                  prefixIcon: Icons.person,
                  validator: (value) {
                    if (_selectedPayoutMethod == 'bank' && (value == null || value.isEmpty)) {
                      return 'Please enter the account holder name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                CustomTextField(
                  controller: _bankAccountNumberController,
                  hintText: 'Account Number',
                  prefixIcon: Icons.account_balance,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (_selectedPayoutMethod == 'bank') {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the account number';
                      }
                      if (!RegExp(r'^\d{9,18}$').hasMatch(value)) {
                        return 'Please enter a valid account number';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                CustomTextField(
                  controller: _bankIFSCController,
                  hintText: 'IFSC Code',
                  prefixIcon: Icons.code,
                  validator: (value) {
                    if (_selectedPayoutMethod == 'bank') {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the IFSC code';
                      }
                      if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(value)) {
                        return 'Please enter a valid IFSC code';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                
                const Divider(),
                const SizedBox(height: 16),
                
                // UPI Information
                const Text(
                  'UPI Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                CustomTextField(
                  controller: _upiIdController,
                  hintText: 'UPI ID (e.g. name@upi)',
                  prefixIcon: Icons.payment,
                  validator: (value) {
                    if (_selectedPayoutMethod == 'upi') {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your UPI ID';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid UPI ID';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                
                // Information Notice
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 18,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Payment Information',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'We process payouts every Monday. Funds typically appear in your account within 2-3 business days after processing.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Save Button
                Center(
                  child: CustomButton(
                    text: 'Save Payment Details',
                    onPressed: _savePaymentDetails,
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