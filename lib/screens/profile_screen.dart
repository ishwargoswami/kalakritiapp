import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalakritiapp/models/user_model.dart';
import 'package:kalakritiapp/providers/auth_provider.dart';
import 'package:kalakritiapp/screens/auth/login_screen.dart';
import 'package:kalakritiapp/utils/theme.dart';
import 'package:kalakritiapp/widgets/custom_button.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userDataProvider);
    
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: userAsync.when(
        data: (userData) {
          // If userData is null, user is not logged in
          if (userData == null) {
            return _buildNotLoggedIn(context);
          }
          
          return _buildProfileContent(context, userData, ref);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: kAccentColor),
              const SizedBox(height: 16),
              Text(
                'Error loading profile: $error',
                style: TextStyle(color: kAccentColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(userDataProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kSecondaryColor,
                  foregroundColor: Colors.white,
                ),
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
            color: kSlateGray.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'You are not logged in',
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
              'Please log in to view your profile and manage your account',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: kTextColor.withOpacity(0.7),
              ),
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
              backgroundColor: kPrimaryColor,
              textColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, UserModel userData, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile header
          _buildProfileHeader(context, userData, ref),
          const SizedBox(height: 24),
          
          // Orders, wishlist, and reviews
          _buildQuickActions(context),
          const SizedBox(height: 24),
          
          // Account settings
          _buildAccountSettings(context, ref),
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
  }

  Widget _buildProfileHeader(BuildContext context, UserModel userData, WidgetRef ref) {
    final String displayName = userData.name ?? 'User';
    final String email = userData.email ?? '';
    final String phone = userData.phoneNumber ?? '';
    final String profilePicture = userData.photoURL ?? '';
    
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
                  backgroundColor: kSlateGray.withOpacity(0.2),
                  backgroundImage: profilePicture.isNotEmpty
                      ? CachedNetworkImageProvider(profilePicture)
                      : null,
                  child: profilePicture.isEmpty
                      ? const Icon(Icons.person, size: 50, color: Colors.white)
                      : null,
                ),
                
                // Edit button
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: kSecondaryColor,
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
              ],
            ),
            
            const SizedBox(height: 16),
            
            // User name
            Text(
              displayName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // User email
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.email, size: 16, color: kTextColor.withOpacity(0.6)),
                const SizedBox(width: 8),
                Text(
                  email,
                  style: TextStyle(
                    color: kTextColor.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            
            if (phone.isNotEmpty) ...[
              const SizedBox(height: 4),
              // User phone
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.phone, size: 16, color: kTextColor.withOpacity(0.6)),
                  const SizedBox(width: 8),
                  Text(
                    phone,
                    style: TextStyle(
                      color: kTextColor.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Edit profile button
            OutlinedButton.icon(
              onPressed: () {
                // TODO: Navigate to edit profile screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Edit profile functionality coming soon!'),
                  ),
                );
              },
              icon: const Icon(Icons.edit),
              label: const Text('Edit Profile'),
              style: OutlinedButton.styleFrom(
                foregroundColor: kPrimaryColor,
                side: BorderSide(color: kPrimaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
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
            Text(
              'My Activities',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),
            
            // Grid of quick actions
            Row(
              children: [
                Expanded(
                  child: _buildActionItem(
                    context,
                    Icons.shopping_bag,
                    'Orders',
                    'View your order history',
                    onTap: () {
                      // TODO: Navigate to orders screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Orders screen coming soon!'),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionItem(
                    context,
                    Icons.favorite,
                    'Wishlist',
                    'View your saved items',
                    onTap: () {
                      // TODO: Navigate to wishlist screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Wishlist screen coming soon!'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionItem(
                    context,
                    Icons.watch_later,
                    'Rentals',
                    'View your rental history',
                    onTap: () {
                      // TODO: Navigate to rentals screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Rentals screen coming soon!'),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionItem(
                    context,
                    Icons.star,
                    'Reviews',
                    'Manage your product reviews',
                    onTap: () {
                      // TODO: Navigate to reviews screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Reviews screen coming soon!'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle, {
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kSlateGray.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: kPrimaryColor),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: kTextColor.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSettings(BuildContext context, WidgetRef ref) {
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
            Text(
              'Account Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildSettingItem(
              context,
              Icons.person,
              'Personal Information',
              'Update your personal details',
              onTap: () {
                // TODO: Navigate to personal info screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Personal information screen coming soon!'),
                  ),
                );
              },
            ),
            _buildSettingItem(
              context,
              Icons.location_on,
              'Addresses',
              'Manage your delivery addresses',
              onTap: () {
                // TODO: Navigate to addresses screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Addresses screen coming soon!'),
                  ),
                );
              },
            ),
            _buildSettingItem(
              context,
              Icons.payment,
              'Payment Methods',
              'Manage your payment methods',
              onTap: () {
                // TODO: Navigate to payment methods screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Payment methods screen coming soon!'),
                  ),
                );
              },
            ),
            _buildSettingItem(
              context,
              Icons.lock,
              'Change Password',
              'Update your password',
              onTap: () {
                // TODO: Navigate to change password screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Change password screen coming soon!'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppSettings(BuildContext context) {
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
            Text(
              'App Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildSettingItem(
              context,
              Icons.notifications,
              'Notifications',
              'Manage your notification preferences',
              onTap: () {
                // TODO: Navigate to notification settings screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notification settings screen coming soon!'),
                  ),
                );
              },
            ),
            _buildSettingItem(
              context,
              Icons.language,
              'Language',
              'Change your language preferences',
              onTap: () {
                // TODO: Navigate to language settings screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Language settings screen coming soon!'),
                  ),
                );
              },
            ),
            _buildSettingItem(
              context,
              Icons.dark_mode,
              'Dark Mode',
              'Toggle dark mode',
              onTap: () {
                // TODO: Implement dark mode toggle
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Dark mode toggle coming soon!'),
                  ),
                );
              },
            ),
            _buildSettingItem(
              context,
              Icons.help,
              'Help & Support',
              'Get help and contact support',
              onTap: () {
                // TODO: Navigate to help screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Help & support screen coming soon!'),
                  ),
                );
              },
            ),
            _buildSettingItem(
              context,
              Icons.info,
              'About',
              'Learn more about Kalakriti App',
              onTap: () {
                // TODO: Navigate to about screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('About screen coming soon!'),
                  ),
                );
              },
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle, {
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kSlateGray.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: kPrimaryColor),
          ),
          title: Text(title),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: kTextColor.withOpacity(0.6),
            ),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
        if (!isLast)
          Divider(
            color: Colors.grey[200],
            height: 1,
            indent: 56,
          ),
      ],
    );
  }
} 