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

class EditArtisanProfileScreen extends ConsumerStatefulWidget {
  final UserModel userData;
  
  const EditArtisanProfileScreen({
    super.key,
    required this.userData,
  });

  @override
  ConsumerState<EditArtisanProfileScreen> createState() => _EditArtisanProfileScreenState();
}

class _EditArtisanProfileScreenState extends ConsumerState<EditArtisanProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  
  // Text controllers
  final _businessNameController = TextEditingController();
  final _businessDescriptionController = TextEditingController();
  final _businessAddressController = TextEditingController();
  final _artisanStoryController = TextEditingController();
  final _craftHistoryController = TextEditingController();
  final _yearsOfExperienceController = TextEditingController();
  final _craftRegionController = TextEditingController();
  
  // Lists
  List<String> _businessImages = [];
  List<String> _craftProcessImages = [];
  List<String> _awards = [];
  List<String> _certifications = [];
  List<String> _skillsAndTechniques = [];
  List<Map<String, dynamic>> _virtualEvents = [];
  
  // New image files to upload
  List<File> _newBusinessImages = [];
  List<File> _newCraftProcessImages = [];
  
  // Form state
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  
  // Text controllers for adding new items
  final _newAwardController = TextEditingController();
  final _newCertificationController = TextEditingController();
  final _newSkillController = TextEditingController();
  
  // Event controllers
  final _eventTitleController = TextEditingController();
  final _eventDateController = TextEditingController();
  final _eventDescriptionController = TextEditingController();
  final _eventLinkController = TextEditingController();
  DateTime? _selectedEventDate;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  @override
  void dispose() {
    _businessNameController.dispose();
    _businessDescriptionController.dispose();
    _businessAddressController.dispose();
    _artisanStoryController.dispose();
    _craftHistoryController.dispose();
    _yearsOfExperienceController.dispose();
    _craftRegionController.dispose();
    _newAwardController.dispose();
    _newCertificationController.dispose();
    _newSkillController.dispose();
    _eventTitleController.dispose();
    _eventDateController.dispose();
    _eventDescriptionController.dispose();
    _eventLinkController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUserData() async {
    try {
      setState(() {
        _businessNameController.text = widget.userData.businessName ?? '';
        _businessDescriptionController.text = widget.userData.businessDescription ?? '';
        _businessAddressController.text = widget.userData.businessAddress ?? '';
        _artisanStoryController.text = widget.userData.artisanStory ?? '';
        _craftHistoryController.text = widget.userData.craftHistory ?? '';
        _yearsOfExperienceController.text = widget.userData.yearsOfExperience?.toString() ?? '';
        _craftRegionController.text = widget.userData.craftRegion ?? '';
        
        _businessImages = widget.userData.businessImages?.toList() ?? [];
        _craftProcessImages = widget.userData.craftProcessImages?.toList() ?? [];
        _awards = widget.userData.awards?.toList() ?? [];
        _certifications = widget.userData.certifications?.toList() ?? [];
        _skillsAndTechniques = widget.userData.skillsAndTechniques?.toList() ?? [];
        _virtualEvents = widget.userData.virtualEvents?.toList() ?? [];
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading profile data: $e';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _pickImages(bool forBusinessImages) async {
    final picker = ImagePicker();
    final pickedImages = await picker.pickMultiImage();
    
    if (pickedImages.isNotEmpty) {
      setState(() {
        for (final image in pickedImages) {
          if (forBusinessImages) {
            _newBusinessImages.add(File(image.path));
          } else {
            _newCraftProcessImages.add(File(image.path));
          }
        }
      });
    }
  }
  
  void _addAward() {
    final award = _newAwardController.text.trim();
    if (award.isNotEmpty) {
      setState(() {
        _awards.add(award);
        _newAwardController.clear();
      });
    }
  }
  
  void _addCertification() {
    final certification = _newCertificationController.text.trim();
    if (certification.isNotEmpty) {
      setState(() {
        _certifications.add(certification);
        _newCertificationController.clear();
      });
    }
  }
  
  void _addSkill() {
    final skill = _newSkillController.text.trim();
    if (skill.isNotEmpty) {
      setState(() {
        _skillsAndTechniques.add(skill);
        _newSkillController.clear();
      });
    }
  }
  
  Future<void> _selectEventDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedEventDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        _selectedEventDate = picked;
        _eventDateController.text = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }
  
  void _addEvent() {
    final title = _eventTitleController.text.trim();
    final description = _eventDescriptionController.text.trim();
    final link = _eventLinkController.text.trim();
    
    if (title.isNotEmpty && _selectedEventDate != null) {
      setState(() {
        _virtualEvents.add({
          'title': title,
          'date': _selectedEventDate!.millisecondsSinceEpoch,
          'description': description,
          'link': link,
        });
        
        _eventTitleController.clear();
        _eventDateController.clear();
        _eventDescriptionController.clear();
        _eventLinkController.clear();
        _selectedEventDate = null;
      });
    }
  }
  
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    
    try {
      final authService = ref.read(authServiceProvider);
      
      // Convert years of experience to int (if provided)
      int? yearsOfExperience;
      if (_yearsOfExperienceController.text.isNotEmpty) {
        yearsOfExperience = int.tryParse(_yearsOfExperienceController.text);
      }
      
      // TODO: Upload new images to Firebase Storage and get URLs
      // This would involve creating a method in authService to handle image uploads
      
      // For now, we'll just save the text fields
      await authService.updateUserProfile(
        businessName: _businessNameController.text,
        businessDescription: _businessDescriptionController.text,
        businessAddress: _businessAddressController.text,
        artisanStory: _artisanStoryController.text,
        craftHistory: _craftHistoryController.text,
        yearsOfExperience: yearsOfExperience,
        craftRegion: _craftRegionController.text,
        awards: _awards,
        certifications: _certifications,
        skillsAndTechniques: _skillsAndTechniques,
        virtualEvents: _virtualEvents,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error updating profile: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading || _isSaving,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Enhance Your Artisan Profile'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                controller: _scrollController,
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
                      
                      // Basic Business Information
                      _buildSectionHeader(context, 'Basic Business Information'),
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
                      ),
                      const SizedBox(height: 16),
                      
                      CustomTextField(
                        controller: _businessDescriptionController,
                        hintText: 'Business Description',
                        prefixIcon: Icons.description,
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a business description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      
                      // Business Images
                      _buildSectionHeader(context, 'Business Images'),
                      _buildImageSelector(
                        context,
                        'Add photos of your shop or business',
                        _businessImages,
                        _newBusinessImages,
                        () => _pickImages(true),
                      ),
                      const SizedBox(height: 24),
                      
                      // Your Story
                      _buildSectionHeader(context, 'Your Artisan Story'),
                      const Text(
                        'Share your personal journey and passion for your craft',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      CustomTextField(
                        controller: _artisanStoryController,
                        hintText: 'Your Personal Story',
                        prefixIcon: Icons.history_edu,
                        maxLines: 5,
                      ),
                      const SizedBox(height: 24),
                      
                      // Craft Process Images
                      _buildSectionHeader(context, 'Your Craft Process'),
                      _buildImageSelector(
                        context,
                        'Add photos showing your craft creation process',
                        _craftProcessImages,
                        _newCraftProcessImages,
                        () => _pickImages(false),
                      ),
                      const SizedBox(height: 24),
                      
                      // Craft History
                      _buildSectionHeader(context, 'Craft History & Tradition'),
                      CustomTextField(
                        controller: _craftHistoryController,
                        hintText: 'History and tradition of your craft',
                        prefixIcon: Icons.auto_stories,
                        maxLines: 4,
                      ),
                      const SizedBox(height: 24),
                      
                      // Experience and Region
                      _buildSectionHeader(context, 'Experience & Region'),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _yearsOfExperienceController,
                              hintText: 'Years of Experience',
                              prefixIcon: Icons.timeline,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomTextField(
                              controller: _craftRegionController,
                              hintText: 'Region of Your Craft',
                              prefixIcon: Icons.place,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Awards and Recognitions
                      _buildSectionHeader(context, 'Awards & Recognitions'),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _newAwardController,
                              hintText: 'Add an award or recognition',
                              prefixIcon: Icons.emoji_events,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _addAward,
                            icon: const Icon(Icons.add_circle),
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildChipList(_awards, (index) {
                        setState(() {
                          _awards.removeAt(index);
                        });
                      }),
                      const SizedBox(height: 24),
                      
                      // Certifications
                      _buildSectionHeader(context, 'Certifications'),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _newCertificationController,
                              hintText: 'Add a certification',
                              prefixIcon: Icons.verified,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _addCertification,
                            icon: const Icon(Icons.add_circle),
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildChipList(_certifications, (index) {
                        setState(() {
                          _certifications.removeAt(index);
                        });
                      }),
                      const SizedBox(height: 24),
                      
                      // Skills and Techniques
                      _buildSectionHeader(context, 'Skills & Techniques'),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _newSkillController,
                              hintText: 'Add a skill or technique',
                              prefixIcon: Icons.construction,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _addSkill,
                            icon: const Icon(Icons.add_circle),
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildChipList(_skillsAndTechniques, (index) {
                        setState(() {
                          _skillsAndTechniques.removeAt(index);
                        });
                      }),
                      const SizedBox(height: 24),
                      
                      // Virtual Events
                      _buildSectionHeader(context, 'Virtual Events'),
                      const Text(
                        'Schedule live sessions where buyers can watch you work',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomTextField(
                                controller: _eventTitleController,
                                hintText: 'Event Title',
                                prefixIcon: Icons.event,
                              ),
                              const SizedBox(height: 12),
                              
                              GestureDetector(
                                onTap: _selectEventDate,
                                child: AbsorbPointer(
                                  child: CustomTextField(
                                    controller: _eventDateController,
                                    hintText: 'Event Date',
                                    prefixIcon: Icons.calendar_today,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              
                              CustomTextField(
                                controller: _eventDescriptionController,
                                hintText: 'Event Description',
                                prefixIcon: Icons.description,
                                maxLines: 3,
                              ),
                              const SizedBox(height: 12),
                              
                              CustomTextField(
                                controller: _eventLinkController,
                                hintText: 'Event Link (Optional)',
                                prefixIcon: Icons.link,
                              ),
                              const SizedBox(height: 16),
                              
                              Center(
                                child: ElevatedButton.icon(
                                  onPressed: _addEvent,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add Event'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).colorScheme.primary,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Display existing events
                      ..._virtualEvents.map((event) {
                        final eventDate = DateTime.fromMillisecondsSinceEpoch(event['date']);
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(event['title']),
                            subtitle: Text(
                              '${eventDate.day}/${eventDate.month}/${eventDate.year}\n${event['description']}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _virtualEvents.remove(event);
                                });
                              },
                            ),
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 32),
                      
                      // Save Button
                      Center(
                        child: CustomButton(
                          text: 'Save Profile',
                          onPressed: _saveProfile,
                          width: double.infinity,
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
  
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const Divider(),
        const SizedBox(height: 8),
      ],
    );
  }
  
  Widget _buildImageSelector(
    BuildContext context,
    String hint,
    List<String> existingImages,
    List<File> newImages,
    VoidCallback onSelectImages,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(hint, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 8),
        
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(8),
            children: [
              // Add image button
              GestureDetector(
                onTap: onSelectImages,
                child: Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate,
                        size: 32,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add Images',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Existing images from network
              ...existingImages.asMap().entries.map((entry) {
                final index = entry.key;
                final imageUrl = entry.value;
                
                return Stack(
                  children: [
                    Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.grey[300],
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.broken_image),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            existingImages.removeAt(index);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
              
              // New images from device
              ...newImages.asMap().entries.map((entry) {
                final index = entry.key;
                final image = entry.value;
                
                return Stack(
                  children: [
                    Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          image,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            newImages.removeAt(index);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildChipList(List<String> items, Function(int) onDelete) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.asMap().entries.map((entry) {
        return Chip(
          label: Text(entry.value),
          deleteIcon: const Icon(Icons.close, size: 18),
          onDeleted: () => onDelete(entry.key),
          backgroundColor: Colors.grey[200],
        );
      }).toList(),
    );
  }
} 