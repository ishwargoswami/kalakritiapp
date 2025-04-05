import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalakritiapp/providers/category_provider.dart';
import 'package:kalakritiapp/providers/seller_service_provider.dart';
import 'package:kalakritiapp/widgets/custom_button.dart';
import 'package:kalakritiapp/widgets/custom_text_field.dart';
import 'package:kalakritiapp/widgets/loading_overlay.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _sizeController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _materialController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  
  final List<String> _selectedCategories = [];
  final List<String> _imageUrls = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _sizeController.dispose();
    _weightController.dispose();
    _materialController.dispose();
    _discountController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }
  
  void _addImageUrl() {
    final url = _imageUrlController.text.trim();
    if (url.isNotEmpty) {
      if (Uri.tryParse(url)?.isAbsolute == true) {
        setState(() {
          _imageUrls.add(url);
          _imageUrlController.clear();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid URL')),
        );
      }
    }
  }
  
  Future<void> _addProduct() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_imageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one product image URL')),
      );
      return;
    }
    
    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one category')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final sellerService = ref.read(sellerServiceProvider);
      
      final price = double.parse(_priceController.text);
      final quantity = int.parse(_quantityController.text);
      final discount = _discountController.text.isNotEmpty
          ? double.parse(_discountController.text)
          : 0.0;
      
      await sellerService.addProductWithUrls(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: price,
        quantity: quantity,
        imageUrls: _imageUrls,
        categories: _selectedCategories,
        size: _sizeController.text.trim(),
        weight: _weightController.text.trim(),
        material: _materialController.text.trim(),
        discountPercentage: discount,
      );
      
      // Navigate back on success
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product added successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error adding product: $e';
      });
      print('Error adding product: $e');
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
    final categoriesAsync = ref.watch(categoriesProvider);
    
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Add New Product'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
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
                
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product images
                      Text(
                        'Product Images',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Image URL input
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _imageUrlController,
                              hintText: 'Enter image URL',
                              prefixIcon: Icons.link,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _addImageUrl,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            child: const Text('Add URL'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Display added image URLs
                      Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: _imageUrls.isEmpty
                            ? const Center(
                                child: Text(
                                  'No images added yet',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.all(8),
                                children: [
                                  ..._imageUrls.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final url = entry.value;
                                    
                                    return Stack(
                                      children: [
                                        Container(
                                          width: 100,
                                          height: 100,
                                          margin: const EdgeInsets.only(right: 8),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.grey[400]!),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(7),
                                            child: Image.network(
                                              url,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => 
                                                Container(
                                                  color: Colors.grey[200],
                                                  child: const Icon(Icons.broken_image, color: Colors.red),
                                                ),
                                              loadingBuilder: (context, child, loadingProgress) {
                                                if (loadingProgress == null) return child;
                                                return Center(
                                                  child: CircularProgressIndicator(
                                                    value: loadingProgress.expectedTotalBytes != null
                                                        ? loadingProgress.cumulativeBytesLoaded /
                                                            loadingProgress.expectedTotalBytes!
                                                        : null,
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 0,
                                          right: 8,
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _imageUrls.removeAt(index);
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
                                  }).toList(),
                                ],
                              ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Basic Information
                      Text(
                        'Basic Information',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Product name
                      CustomTextField(
                        controller: _nameController,
                        hintText: 'Product Name',
                        prefixIcon: Icons.shopping_bag,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a product name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Description
                      CustomTextField(
                        controller: _descriptionController,
                        hintText: 'Description',
                        prefixIcon: Icons.description,
                        maxLines: 5,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a product description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Price and quantity in a row
                      Row(
                        children: [
                          // Price
                          Expanded(
                            child: CustomTextField(
                              controller: _priceController,
                              hintText: 'Price',
                              prefixIcon: Icons.currency_rupee,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter price';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Please enter a valid number';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          // Quantity
                          Expanded(
                            child: CustomTextField(
                              controller: _quantityController,
                              hintText: 'Quantity',
                              prefixIcon: Icons.inventory,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter quantity';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Please enter a valid number';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Discount
                      CustomTextField(
                        controller: _discountController,
                        hintText: 'Discount Percentage (optional)',
                        prefixIcon: Icons.discount,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final discount = double.tryParse(value);
                            if (discount == null) {
                              return 'Please enter a valid number';
                            }
                            if (discount < 0 || discount > 100) {
                              return 'Discount must be between 0 and 100';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      
                      // Additional Details
                      Text(
                        'Additional Details',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Size/Dimensions
                      CustomTextField(
                        controller: _sizeController,
                        hintText: 'Size/Dimensions (optional)',
                        prefixIcon: Icons.straighten,
                      ),
                      const SizedBox(height: 16),
                      
                      // Weight
                      CustomTextField(
                        controller: _weightController,
                        hintText: 'Weight (optional)',
                        prefixIcon: Icons.scale,
                      ),
                      const SizedBox(height: 16),
                      
                      // Material
                      CustomTextField(
                        controller: _materialController,
                        hintText: 'Material (optional)',
                        prefixIcon: Icons.category,
                      ),
                      const SizedBox(height: 24),
                      
                      // Categories
                      Text(
                        'Categories',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Category selector
                      categoriesAsync.when(
                        data: (categories) {
                          if (categories.isEmpty) {
                            return Column(
                              children: [
                                const Text(
                                  'No categories available. Please try again in a moment.',
                                  style: TextStyle(color: Colors.red),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    // Refresh categories
                                    ref.refresh(categoriesProvider);
                                  },
                                  child: const Text('Refresh Categories'),
                                ),
                              ],
                            );
                          }
                          
                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: categories.map((category) {
                              final isSelected = _selectedCategories.contains(category);
                              return FilterChip(
                                label: Text(category),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedCategories.add(category);
                                    } else {
                                      _selectedCategories.remove(category);
                                    }
                                  });
                                },
                                selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                checkmarkColor: Theme.of(context).colorScheme.primary,
                              );
                            }).toList(),
                          );
                        },
                        loading: () => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        error: (_, __) => Center(
                          child: Text(
                            'Error loading categories',
                            style: TextStyle(color: Colors.red[700]),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Submit button
                      Center(
                        child: CustomButton(
                          text: 'Add Product',
                          onPressed: _addProduct,
                          width: double.infinity,
                        ),
                      ),
                    ],
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