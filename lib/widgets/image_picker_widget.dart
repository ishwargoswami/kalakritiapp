import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerWidget extends StatelessWidget {
  final List<XFile> images;
  final Function(List<XFile>) onImagesSelected;
  final bool multiple;

  const ImagePickerWidget({
    Key? key,
    required this.images,
    required this.onImagesSelected,
    this.multiple = true,
  }) : super(key: key);

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    
    if (multiple) {
      final List<XFile> selectedImages = await picker.pickMultiImage();
      if (selectedImages.isNotEmpty) {
        onImagesSelected(selectedImages);
      }
    } else {
      final XFile? selectedImage = await picker.pickImage(source: ImageSource.gallery);
      if (selectedImage != null) {
        onImagesSelected([selectedImage]);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (images.isNotEmpty)
          Container(
            height: 120,
            margin: const EdgeInsets.only(bottom: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: Image.file(
                          File(images[index].path),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 8,
                      child: InkWell(
                        onTap: () {
                          final List<XFile> updatedImages = List.from(images);
                          updatedImages.removeAt(index);
                          onImagesSelected(updatedImages);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
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
                );
              },
            ),
          ),

        ElevatedButton.icon(
          onPressed: _pickImages,
          icon: const Icon(Icons.add_photo_alternate),
          label: Text(multiple ? 'Add Images' : 'Add Image'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
} 