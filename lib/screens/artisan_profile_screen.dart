import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kalakritiapp/models/user.dart';
import 'package:kalakritiapp/providers/auth_provider.dart';
import 'package:kalakritiapp/screens/chat_screen.dart';
import 'package:kalakritiapp/widgets/loading_overlay.dart';
import 'package:url_launcher/url_launcher.dart';

// Provider to fetch artisan data by ID
final artisanProvider = FutureProvider.family<UserModel?, String>((ref, artisanId) async {
  try {
    final authService = ref.read(authServiceProvider);
    return await authService.getUserDataById(artisanId);
  } catch (e) {
    print('Error fetching artisan: $e');
    return null;
  }
});

class ArtisanProfileScreen extends ConsumerWidget {
  final String artisanId;
  final String artisanName;

  const ArtisanProfileScreen({
    required this.artisanId,
    required this.artisanName,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artisanAsync = ref.watch(artisanProvider(artisanId));
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Artisan: $artisanName'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: artisanAsync.when(
        data: (artisan) {
          if (artisan == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Artisan not found',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }
          
          return _buildArtisanProfile(context, artisan, ref);
        },
        loading: () => const LoadingOverlay(
          isLoading: true,
          child: Center(child: Text('Loading artisan profile...')),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error: $error',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(artisanProvider(artisanId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildMessageFAB(context, ref),
    );
  }

  Widget _buildMessageFAB(BuildContext context, WidgetRef ref) {
    // Only show FAB if the user is logged in and the artisan is not the current user
    final currentUser = FirebaseAuth.instance.currentUser;
    final showFAB = currentUser != null && currentUser.uid != artisanId;
    
    if (!showFAB) return const SizedBox.shrink();
    
    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              otherUserId: artisanId,
              otherUserName: artisanName,
            ),
          ),
        );
      },
      label: const Text('Message Artisan'),
      icon: const Icon(Icons.chat),
      backgroundColor: Theme.of(context).colorScheme.secondary,
      foregroundColor: Colors.white,
    );
  }

  Widget _buildArtisanProfile(BuildContext context, UserModel artisan, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Artisan Header
          _buildArtisanHeader(context, artisan),
          const SizedBox(height: 24),
          
          // Artisan Story
          if (artisan.artisanStory != null && artisan.artisanStory!.isNotEmpty)
            _buildSection(
              context,
              title: 'Their Story',
              icon: Icons.history_edu,
              child: Text(
                artisan.artisanStory!,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Colors.grey[800],
                ),
              ),
            ),
          
          // Craft Process Images
          if (artisan.craftProcessImages != null && artisan.craftProcessImages!.isNotEmpty)
            _buildSection(
              context,
              title: 'Craft Process',
              icon: Icons.auto_awesome,
              child: SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: artisan.craftProcessImages!.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 200,
                      margin: const EdgeInsets.only(right: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: artisan.craftProcessImages![index],
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[200],
                            child: const Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.error),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          
          // Craft History
          if (artisan.craftHistory != null && artisan.craftHistory!.isNotEmpty)
            _buildSection(
              context,
              title: 'Craft History & Tradition',
              icon: Icons.auto_stories,
              child: Text(
                artisan.craftHistory!,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Colors.grey[800],
                ),
              ),
            ),
          
          // Experience and Region
          if ((artisan.yearsOfExperience != null) || (artisan.craftRegion != null && artisan.craftRegion!.isNotEmpty))
            _buildSection(
              context,
              title: 'Experience & Region',
              icon: Icons.place,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (artisan.yearsOfExperience != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.timeline, size: 18, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            '${artisan.yearsOfExperience} ${artisan.yearsOfExperience == 1 ? 'year' : 'years'} of experience',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  if (artisan.craftRegion != null && artisan.craftRegion!.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.language, size: 18, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          'Craft from ${artisan.craftRegion}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          
          // Awards and Recognitions
          if (artisan.awards != null && artisan.awards!.isNotEmpty)
            _buildSection(
              context,
              title: 'Awards & Recognitions',
              icon: Icons.emoji_events,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: artisan.awards!.map((award) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.star, size: 18, color: Colors.amber),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            award,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          
          // Skills and Techniques
          if (artisan.skillsAndTechniques != null && artisan.skillsAndTechniques!.isNotEmpty)
            _buildSection(
              context,
              title: 'Skills & Techniques',
              icon: Icons.construction,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: artisan.skillsAndTechniques!.map((skill) {
                  return Chip(
                    label: Text(skill),
                    backgroundColor: Colors.grey[200],
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  );
                }).toList(),
              ),
            ),
          
          // Upcoming Virtual Events
          if (artisan.virtualEvents != null && artisan.virtualEvents!.isNotEmpty)
            _buildSection(
              context,
              title: 'Upcoming Virtual Events',
              icon: Icons.event,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _getUpcomingEvents(artisan.virtualEvents!).map((event) {
                  final eventDate = DateTime.fromMillisecondsSinceEpoch(event['date']);
                  final formattedDate = DateFormat('EEEE, MMMM d, y').format(eventDate);
                  final formattedTime = DateFormat('h:mm a').format(eventDate);
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Event title and date
                          Text(
                            event['title'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          
                          // Date and time
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(formattedDate),
                              const SizedBox(width: 12),
                              const Icon(Icons.access_time, size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(formattedTime),
                            ],
                          ),
                          
                          // Description
                          if (event['description'] != null && event['description'].isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              event['description'],
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ],
                          
                          // Link to join
                          if (event['link'] != null && event['link'].isNotEmpty) ...[
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () => _launchURL(event['link']),
                              icon: const Icon(Icons.videocam),
                              label: const Text('Join Event'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          
          const SizedBox(height: 60), // Bottom space for FAB
        ],
      ),
    );
  }

  Widget _buildArtisanHeader(BuildContext context, UserModel artisan) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Artisan image
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey[200],
              backgroundImage: artisan.photoURL != null
                  ? CachedNetworkImageProvider(artisan.photoURL!)
                  : null,
              child: artisan.photoURL == null
                  ? const Icon(Icons.person, size: 60, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 16),
            
            // Artisan name
            Text(
              artisan.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            // Business name
            if (artisan.businessName != null && artisan.businessName!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  artisan.businessName!,
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            
            // Verification badge
            if (artisan.isVerifiedSeller)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified, size: 16, color: Colors.green),
                    const SizedBox(width: 4),
                    const Text(
                      'Verified Artisan',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            
            // Business description
            if (artisan.businessDescription != null && artisan.businessDescription!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Text(
                  artisan.businessDescription!,
                  style: TextStyle(
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            
            // Location
            if (artisan.businessAddress != null && artisan.businessAddress!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      artisan.businessAddress!,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Row(
            children: [
              Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 8),
          
          // Section content
          child,
        ],
      ),
    );
  }
  
  List<Map<String, dynamic>> _getUpcomingEvents(List<Map<String, dynamic>> events) {
    final now = DateTime.now();
    return events.where((event) {
      final eventDate = DateTime.fromMillisecondsSinceEpoch(event['date']);
      return eventDate.isAfter(now);
    }).toList()
      ..sort((a, b) {
        final dateA = DateTime.fromMillisecondsSinceEpoch(a['date']);
        final dateB = DateTime.fromMillisecondsSinceEpoch(b['date']);
        return dateA.compareTo(dateB);
      });
  }
  
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  }
} 