import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalakritiapp/models/user.dart';
import 'package:kalakritiapp/providers/auth_provider.dart';
import 'package:kalakritiapp/screens/auth/login_screen.dart';
import 'package:kalakritiapp/widgets/custom_button.dart';
import 'package:kalakritiapp/widgets/loading_overlay.dart';
import 'package:kalakritiapp/screens/seller/edit_artisan_profile_screen.dart';
import 'package:kalakritiapp/screens/seller/edit_profile_screen.dart';
import 'package:kalakritiapp/screens/seller/edit_business_info_screen.dart';
import 'package:kalakritiapp/services/auth_service.dart';

class SellerProfileScreen extends ConsumerStatefulWidget {
  const SellerProfileScreen({super.key});

  @override
  ConsumerState<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends ConsumerState<SellerProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userDataProvider);
    
    return Scaffold(
      body: userAsync.when(
        data: (userData) {
          if (userData == null) {
            return _buildNotLoggedIn(context);
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile header
                _buildProfileHeader(context, userData),
                const SizedBox(height: 24),
                
                // Business Information
                _buildBusinessInfo(context, userData),
                const SizedBox(height: 24),
                
                // Seller specific section
                if (userData.isSeller)
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Artisan Profile',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditArtisanProfileScreen(userData: userData),
                                    ),
                                  ).then((result) {
                                    if (result == true) {
                                      // Refresh user data if artisan profile was updated
                                      ref.refresh(userDataProvider);
                                    }
                                  });
                                },
                                tooltip: 'Edit Artisan Profile',
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(8),
                              ),
                            ],
                          ),
                          const Divider(),
                          // ...
                          // ... Artisan profile details
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditArtisanProfileScreen(userData: userData),
                                ),
                              ).then((result) {
                                if (result == true) {
                                  // Refresh user data if artisan profile was updated
                                  ref.refresh(userDataProvider);
                                }
                              });
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text('Complete Artisan Profile'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Theme.of(context).colorScheme.primary,
                              side: BorderSide(color: Theme.of(context).colorScheme.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                
                // Account settings
                _buildAccountSettings(context),
                const SizedBox(height: 24),
                
                // App settings
                _buildAppSettings(context),
                const SizedBox(height: 24),
                
                // Sign out button
                Center(
                  child: CustomButton(
                    text: 'Sign Out',
                    onPressed: () async {
                      await ref.read(authServiceProvider).signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      }
                    },
                    backgroundColor: Colors.red,
                    textColor: Colors.white,
                    width: 200,
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error loading profile: $error',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(userDataProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotLoggedIn(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_circle,
            size: 100,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          const Text(
            'You are not logged in',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Please log in to view your profile and manage your account',
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: CustomButton(
              text: 'Login',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, UserModel userData) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile picture and edit button
            Stack(
              children: [
                // Profile picture
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: userData.photoURL != null
                      ? CachedNetworkImageProvider(userData.photoURL!)
                      : null,
                  child: userData.photoURL == null
                      ? const Icon(Icons.person, size: 50, color: Colors.white)
                      : null,
                ),
                
                // Edit button
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfileScreen(userData: userData),
                        ),
                      ).then((result) {
                        if (result == true) {
                          // Refresh user data if profile was updated
                          ref.refresh(userDataProvider);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // User name
            Text(
              userData.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 4),
            
            // Email
            Text(
              userData.email,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            
            const SizedBox(height: 4),
            
            // Phone
            if (userData.phoneNumber != null)
              Text(
                userData.phoneNumber!,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Edit Profile button
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfileScreen(userData: userData),
                  ),
                ).then((result) {
                  if (result == true) {
                    // Refresh user data if profile was updated
                    ref.refresh(userDataProvider);
                  }
                });
              },
              icon: const Icon(Icons.edit),
              label: const Text('Edit Profile'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                side: BorderSide(color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessInfo(BuildContext context, UserModel userData) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Business Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditBusinessInfoScreen(userData: userData),
                      ),
                    ).then((result) {
                      if (result == true) {
                        // Refresh user data if business info was updated
                        ref.refresh(userDataProvider);
                      }
                    });
                  },
                  tooltip: 'Edit Business Info',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
              ],
            ),
            const Divider(),
            
            // Business name
            ListTile(
              leading: const Icon(Icons.store),
              title: const Text('Business Name'),
              subtitle: Text(userData.businessName ?? 'Not set'),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            
            // Business description
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Business Description'),
              subtitle: Text(
                userData.businessDescription ?? 'Not set',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            
            // Business address
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('Business Address'),
              subtitle: Text(userData.businessAddress ?? 'Not set'),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            
            // Verification status
            ListTile(
              leading: Icon(
                userData.isVerifiedSeller
                    ? Icons.verified
                    : Icons.pending,
                color: userData.isVerifiedSeller
                    ? Colors.green
                    : Colors.orange,
              ),
              title: const Text('Verification Status'),
              subtitle: Text(
                userData.isVerifiedSeller
                    ? 'Verified Seller'
                    : 'Verification Pending',
                style: TextStyle(
                  color: userData.isVerifiedSeller
                      ? Colors.green
                      : Colors.orange,
                ),
              ),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSettings(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Account Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 0),
          
          // Change password
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Change Password'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () async {
              final authService = ref.read(authServiceProvider);
              final user = authService.currentUser;
              
              if (user != null && user.email != null) {
                try {
                  await showDialog(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Reset Password'),
                      content: Text(
                        'We will send a password reset link to ${user.email}. Would you like to proceed?'
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () async {
                            try {
                              Navigator.pop(dialogContext);
                              
                              // Show loading indicator
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Sending reset link...'), duration: Duration(seconds: 1)),
                              );
                              
                              await authService.sendPasswordResetEmail(user.email!);
                              
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Password reset link sent to ${user.email}'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: ${e.toString()}'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          child: const Text('Send Reset Link'),
                        ),
                      ],
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('User not logged in or email not available'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
          
          const Divider(height: 0),
          
          // Privacy settings
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Settings'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Navigate to privacy settings screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Privacy Settings coming soon')),
              );
            },
          ),
          
          const Divider(height: 0),
          
          // Payment methods
          ListTile(
            leading: const Icon(Icons.payment_outlined),
            title: const Text('Payment Methods'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Navigate to payment methods screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Payment Methods coming soon')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppSettings(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'App Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 0),
          
          // Notifications
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('Push Notifications'),
            value: true, // TODO: Get actual notification settings
            onChanged: (value) {
              // TODO: Update notification settings
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Notifications ${value ? 'enabled' : 'disabled'}')),
              );
            },
          ),
          
          const Divider(height: 0),
          
          // Language settings
          ListTile(
            leading: const Icon(Icons.language_outlined),
            title: const Text('Language'),
            subtitle: const Text('English'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Navigate to language settings screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Language Settings coming soon')),
              );
            },
          ),
          
          const Divider(height: 0),
          
          // Help and Support
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help & Support'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Navigate to help and support screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Help & Support coming soon')),
              );
            },
          ),
          
          const Divider(height: 0),
          
          // About
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Navigate to about screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('About coming soon')),
              );
            },
          ),
        ],
      ),
    );
  }
} 