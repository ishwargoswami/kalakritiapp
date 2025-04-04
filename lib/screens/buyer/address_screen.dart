import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalakritiapp/models/user.dart';
import 'package:kalakritiapp/providers/auth_provider.dart';
import 'package:kalakritiapp/utils/theme.dart';
import 'package:kalakritiapp/widgets/custom_button.dart';
import 'package:kalakritiapp/widgets/loading_overlay.dart';

class AddressScreen extends ConsumerStatefulWidget {
  const AddressScreen({super.key});

  @override
  ConsumerState<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends ConsumerState<AddressScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userDataProvider);
    
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Addresses'),
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
        ),
        body: userAsync.when(
          data: (userData) {
            if (userData == null) {
              return const Center(
                child: Text('Please log in to view your addresses'),
              );
            }
            
            final addresses = userData.shippingAddresses;
            
            return Column(
              children: [
                Expanded(
                  child: addresses.isEmpty
                      ? _buildEmptyState()
                      : _buildAddressList(addresses),
                ),
                _buildAddAddressButton(context, userData),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Text('Error loading addresses: $error'),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _showAddEditAddressDialog(context, null);
          },
          backgroundColor: kPrimaryColor,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No addresses yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: kTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Add your delivery addresses to make checkout faster',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: kTextColor.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressList(List<Map<String, dynamic>> addresses) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: addresses.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final address = addresses[index];
        final bool isDefault = address['isDefault'] ?? false;
        
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          address['name'] ?? 'Address',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: kPrimaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Default',
                              style: TextStyle(
                                fontSize: 10,
                                color: kPrimaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () {
                            _showAddEditAddressDialog(context, address);
                          },
                          splashRadius: 24,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          onPressed: () {
                            _confirmDeleteAddress(index);
                          },
                          splashRadius: 24,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(),
                Text(
                  '${address['addressLine1']}\n'
                  '${address['addressLine2']}\n'
                  '${address['city']}, ${address['state']} ${address['postalCode']}',
                  style: TextStyle(
                    fontSize: 14,
                    color: kTextColor.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Phone: ${address['phoneNumber'] ?? 'Not provided'}',
                  style: TextStyle(
                    fontSize: 14,
                    color: kTextColor.withOpacity(0.8),
                  ),
                ),
                if (!isDefault) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      _setAsDefaultAddress(index);
                    },
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('Set as default'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kPrimaryColor,
                      side: BorderSide(color: kPrimaryColor),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      minimumSize: const Size(0, 36),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddAddressButton(BuildContext context, UserModel userData) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: CustomButton(
        text: 'Add New Address',
        onPressed: () {
          _showAddEditAddressDialog(context, null);
        },
        backgroundColor: kPrimaryColor,
        textColor: Colors.white,
        icon: Icons.add,
        width: double.infinity,
      ),
    );
  }

  void _showAddEditAddressDialog(BuildContext context, Map<String, dynamic>? existingAddress) {
    final isEditing = existingAddress != null;
    final _formKey = GlobalKey<FormState>();
    
    // Text controllers
    final nameController = TextEditingController(text: existingAddress?['name'] ?? '');
    final addressLine1Controller = TextEditingController(text: existingAddress?['addressLine1'] ?? '');
    final addressLine2Controller = TextEditingController(text: existingAddress?['addressLine2'] ?? '');
    final cityController = TextEditingController(text: existingAddress?['city'] ?? '');
    final stateController = TextEditingController(text: existingAddress?['state'] ?? '');
    final postalCodeController = TextEditingController(text: existingAddress?['postalCode'] ?? '');
    final phoneNumberController = TextEditingController(text: existingAddress?['phoneNumber'] ?? '');
    
    bool isDefault = existingAddress?['isDefault'] ?? false;
    
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEditing ? 'Edit Address' : 'Add New Address'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) => value!.isEmpty ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: addressLine1Controller,
                    decoration: const InputDecoration(
                      labelText: 'Address Line 1',
                      prefixIcon: Icon(Icons.home),
                    ),
                    validator: (value) => value!.isEmpty ? 'Address Line 1 is required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: addressLine2Controller,
                    decoration: const InputDecoration(
                      labelText: 'Address Line 2 (Optional)',
                      prefixIcon: Icon(Icons.home),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: cityController,
                    decoration: const InputDecoration(
                      labelText: 'City',
                      prefixIcon: Icon(Icons.location_city),
                    ),
                    validator: (value) => value!.isEmpty ? 'City is required' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: stateController,
                          decoration: const InputDecoration(
                            labelText: 'State',
                            prefixIcon: Icon(Icons.map),
                          ),
                          validator: (value) => value!.isEmpty ? 'State is required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: postalCodeController,
                          decoration: const InputDecoration(
                            labelText: 'Postal Code',
                            prefixIcon: Icon(Icons.pin),
                          ),
                          validator: (value) => value!.isEmpty ? 'Postal Code is required' : null,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Phone Number is required';
                      }
                      if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                        return 'Please enter a valid 10-digit phone number';
                      }
                      return null;
                    },
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('Set as default address'),
                    value: isDefault,
                    onChanged: (value) {
                      setState(() {
                        isDefault = value!;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext);
                  
                  final newAddress = {
                    'name': nameController.text,
                    'addressLine1': addressLine1Controller.text,
                    'addressLine2': addressLine2Controller.text,
                    'city': cityController.text,
                    'state': stateController.text,
                    'postalCode': postalCodeController.text,
                    'phoneNumber': phoneNumberController.text,
                    'isDefault': isDefault,
                  };
                  
                  if (isEditing) {
                    _updateAddress(existingAddress, newAddress);
                  } else {
                    _addNewAddress(newAddress);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
              ),
              child: Text(isEditing ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _addNewAddress(Map<String, dynamic> newAddress) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final userData = ref.read(userDataProvider).value;
      if (userData == null) return;
      
      final List<Map<String, dynamic>> addresses = List.from(userData.shippingAddresses);
      
      // If the new address is set as default, update all existing addresses
      if (newAddress['isDefault'] == true) {
        for (int i = 0; i < addresses.length; i++) {
          addresses[i] = {...addresses[i], 'isDefault': false};
        }
      }
      // If there are no addresses yet, set this one as default
      else if (addresses.isEmpty) {
        newAddress['isDefault'] = true;
      }
      
      addresses.add(newAddress);
      
      // Update user data in Firestore
      await ref.read(authServiceProvider).updateUserProfile(
        shippingAddresses: addresses,
      );
      
      // Refresh user data
      ref.refresh(userDataProvider);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding address: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateAddress(Map<String, dynamic> oldAddress, Map<String, dynamic> newAddress) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final userData = ref.read(userDataProvider).value;
      if (userData == null) return;
      
      final List<Map<String, dynamic>> addresses = List.from(userData.shippingAddresses);
      final int index = addresses.indexOf(oldAddress);
      
      if (index == -1) {
        throw Exception('Address not found');
      }
      
      // If the updated address is set as default, update all existing addresses
      if (newAddress['isDefault'] == true) {
        for (int i = 0; i < addresses.length; i++) {
          addresses[i] = {...addresses[i], 'isDefault': false};
        }
      }
      // If this was the default address and is no longer, set the first address as default
      else if (oldAddress['isDefault'] == true && addresses.length > 0) {
        addresses[0] = {...addresses[0], 'isDefault': true};
      }
      
      addresses[index] = newAddress;
      
      // Update user data in Firestore
      await ref.read(authServiceProvider).updateUserProfile(
        shippingAddresses: addresses,
      );
      
      // Refresh user data
      ref.refresh(userDataProvider);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating address: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _setAsDefaultAddress(int index) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final userData = ref.read(userDataProvider).value;
      if (userData == null) return;
      
      final List<Map<String, dynamic>> addresses = List.from(userData.shippingAddresses);
      
      // Set all addresses to non-default
      for (int i = 0; i < addresses.length; i++) {
        addresses[i] = {...addresses[i], 'isDefault': i == index};
      }
      
      // Update user data in Firestore
      await ref.read(authServiceProvider).updateUserProfile(
        shippingAddresses: addresses,
      );
      
      // Refresh user data
      ref.refresh(userDataProvider);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Default address updated')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating default address: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _confirmDeleteAddress(int index) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Address?'),
        content: const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _deleteAddress(index);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteAddress(int index) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final userData = ref.read(userDataProvider).value;
      if (userData == null) return;
      
      final List<Map<String, dynamic>> addresses = List.from(userData.shippingAddresses);
      final bool wasDefault = addresses[index]['isDefault'] ?? false;
      
      addresses.removeAt(index);
      
      // If we removed the default address and there are other addresses,
      // make the first one the default
      if (wasDefault && addresses.isNotEmpty) {
        addresses[0] = {...addresses[0], 'isDefault': true};
      }
      
      // Update user data in Firestore
      await ref.read(authServiceProvider).updateUserProfile(
        shippingAddresses: addresses,
      );
      
      // Refresh user data
      ref.refresh(userDataProvider);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting address: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
} 