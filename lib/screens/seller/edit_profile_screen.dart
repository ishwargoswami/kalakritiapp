import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kalakritiapp/models/user.dart';
import 'package:kalakritiapp/providers/auth_provider.dart';
import 'package:kalakritiapp/services/auth_service.dart';
import 'package:kalakritiapp/widgets/custom_button.dart';
import 'package:kalakritiapp/widgets/custom_text_field.dart';
import 'package:kalakritiapp/widgets/loading_overlay.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final UserModel userData;

  const EditProfileScreen({
    super.key,
    required this.userData,
  });

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Text controllers
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  
  // Profile photo
  String? _photoURL;
  File? _newProfilePhoto;
  
  // Form state
  bool _isLoading = false;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userData.name);
    _phoneController = TextEditingController(text: widget.userData.phoneNumber ?? '');
    _emailController = TextEditingController(text: widget.userData.email);
    _photoURL = widget.userData.photoURL;
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }
  
  Future<void> _pickProfilePhoto() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _newProfilePhoto = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }
  
  Future<String?> _uploadProfilePhoto() async {
    if (_newProfilePhoto == null) return null;
    
    try {
      final storage = FirebaseStorage.instance;
      final user = ref.read(authServiceProvider).currentUser;
      
      if (user == null) throw Exception('User not authenticated');
      
      final fileExtension = _newProfilePhoto!.path.split('.').last;
      final storageRef = storage.ref().child('profile_photos/${user.uid}.$fileExtension');
      
      final uploadTask = storageRef.putFile(_newProfilePhoto!);
      final snapshot = await uploadTask;
      
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading profile photo: $e');
      rethrow;
    }
  }
  
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final authService = ref.read(authServiceProvider);
      
      // Upload new profile photo if selected
      String? newPhotoURL;
      if (_newProfilePhoto != null) {
        newPhotoURL = await _uploadProfilePhoto();
      }
      
      // Update profile
      await authService.updateUserProfile(
        name: _nameController.text,
        phoneNumber: _phoneController.text,
        photoURL: newPhotoURL,
      );
      
      // Invalidate user data provider to refresh profile data
      ref.refresh(userDataProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context, true); // Return true to indicate update was successful
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error updating profile: $e';
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
          title: const Text('Edit Profile'),
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
                
                // Profile Photo
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _pickProfilePhoto,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.grey[300],
                              backgroundImage: _newProfilePhoto != null
                                  ? FileImage(_newProfilePhoto!) as ImageProvider
                                  : (_photoURL != null
                                      ? CachedNetworkImageProvider(_photoURL!) as ImageProvider
                                      : null),
                              child: (_newProfilePhoto == null && _photoURL == null)
                                  ? const Icon(Icons.person, size: 60, color: Colors.white)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to change profile photo',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Basic Information
                const Text(
                  'Basic Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                CustomTextField(
                  controller: _nameController,
                  hintText: 'Full Name',
                  prefixIcon: Icons.person,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Display email (read-only)
                CustomTextField(
                  controller: _emailController,
                  hintText: 'Email',
                  prefixIcon: Icons.email,
                  readOnly: true,
                  enabled: false,
                ),
                const SizedBox(height: 16),
                
                CustomTextField(
                  controller: _phoneController,
                  hintText: 'Phone Number',
                  prefixIcon: Icons.phone,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 32),
                
                // Save Button
                Center(
                  child: CustomButton(
                    text: 'Save Changes',
                    onPressed: _saveProfile,
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