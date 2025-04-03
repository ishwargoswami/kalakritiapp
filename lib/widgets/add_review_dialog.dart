import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kalakritiapp/models/review.dart';
import 'package:kalakritiapp/providers/review_provider.dart';
import 'package:kalakritiapp/services/review_service.dart';
import 'package:kalakritiapp/utils/theme.dart';
import 'package:kalakritiapp/widgets/custom_button.dart';
import 'package:kalakritiapp/widgets/rating_bar.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class AddReviewDialog extends ConsumerStatefulWidget {
  final String productId;
  final Review? existingReview;

  const AddReviewDialog({
    super.key,
    required this.productId,
    this.existingReview,
  });

  @override
  ConsumerState<AddReviewDialog> createState() => _AddReviewDialogState();
}

class _AddReviewDialogState extends ConsumerState<AddReviewDialog> {
  final TextEditingController _reviewController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();
  
  double _rating = 0;
  List<XFile> _selectedImages = [];
  bool _isSubmitting = false;
  bool _isVerifiedPurchase = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    
    if (widget.existingReview != null) {
      _rating = widget.existingReview!.rating;
      _reviewController.text = widget.existingReview!.comment;
      _isVerifiedPurchase = widget.existingReview!.isVerifiedPurchase;
    } else {
      _checkIfUserPurchasedProduct();
    }
  }

  Future<void> _checkIfUserPurchasedProduct() async {
    final reviewService = ref.read(reviewServiceProvider);
    final hasPurchased = await reviewService.hasUserPurchasedProduct(widget.productId);
    if (mounted) {
      setState(() {
        _isVerifiedPurchase = hasPurchased;
      });
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final pickedImages = await _picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (pickedImages.isNotEmpty && mounted) {
        setState(() {
          _selectedImages = pickedImages;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking images: $e')),
        );
      }
    }
  }

  Future<List<String>> _uploadImages() async {
    if (_selectedImages.isEmpty) return [];
    
    setState(() {
      _isUploading = true;
    });
    
    try {
      final List<String> uploadedUrls = [];
      final reviewService = ref.read(reviewServiceProvider);
      final userId = reviewService.currentUserId;
      
      if (userId == null) {
        throw Exception('User not logged in');
      }
      
      for (final image in _selectedImages) {
        // Create a unique filename
        final String fileName = '${_uuid.v4()}${path.extension(image.path)}';
        final storageRef = _storage.ref().child('reviews/$userId/${widget.productId}/$fileName');
        
        // Upload the file
        final uploadTask = storageRef.putFile(File(image.path));
        
        // Wait for the upload to complete
        await uploadTask;
        
        // Get the download URL
        final String downloadUrl = await storageRef.getDownloadURL();
        uploadedUrls.add(downloadUrl);
      }
      
      return uploadedUrls;
    } catch (e) {
      print('Error uploading images: $e');
      rethrow;
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    if (_reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a review')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final reviewService = ref.read(reviewServiceProvider);
      
      // Upload images if selected
      List<String>? imageUrls;
      if (_selectedImages.isNotEmpty) {
        imageUrls = await _uploadImages();
      }
      
      if (widget.existingReview != null) {
        // Update existing review
        await reviewService.addReview(
          productId: widget.productId,
          rating: _rating,
          comment: _reviewController.text.trim(),
          imageUrls: imageUrls ?? widget.existingReview!.imageUrls,
        );
      } else {
        // Add new review
        await reviewService.addReview(
          productId: widget.productId,
          rating: _rating,
          comment: _reviewController.text.trim(),
          imageUrls: imageUrls,
          isVerifiedPurchase: _isVerifiedPurchase,
        );
      }
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingReview != null
                ? 'Review updated successfully'
                : 'Review added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting review: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            widget.existingReview != null ? 'Edit Review' : 'Write a Review',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Rating
              Text(
                'Rating',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: List.generate(5, (index) {
                  final starValue = index + 1;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _rating = starValue.toDouble();
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        starValue <= _rating ? Icons.star : Icons.star_border,
                        color: starValue <= _rating ? Colors.amber : Colors.grey,
                        size: 32,
                      ),
                    ),
                  );
                }),
              ),
              
              const SizedBox(height: 16),
              
              // Review text
              Text(
                'Review',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _reviewController,
                maxLines: 6,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'Share your experience with this product...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Add images
              Text(
                'Add Photos (Optional)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  // Add images button
                  GestureDetector(
                    onTap: _isSubmitting || _isUploading ? null : _pickImages,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: _isUploading 
                          ? const Center(
                              child: SizedBox(
                                width: 30,
                                height: 30,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : const Icon(Icons.add_a_photo, color: Colors.grey),
                    ),
                  ),
                  
                  // Selected images preview
                  if (_selectedImages.isNotEmpty)
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _selectedImages.map((image) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(image.path),
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: _isSubmitting || _isUploading ? null : () {
                                        setState(() {
                                          _selectedImages.remove(image);
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                ],
              ),
              
              // Verified purchase badge
              if (_isVerifiedPurchase) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified,
                        size: 16,
                        color: Colors.green[700],
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Verified Purchase',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Submit button
              CustomButton(
                text: widget.existingReview != null ? 'Update Review' : 'Submit Review',
                onPressed: _isSubmitting || _isUploading ? null : _submitReview,
                isLoading: _isSubmitting || _isUploading,
                isFullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 