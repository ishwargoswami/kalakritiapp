import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalakritiapp/models/seller_product.dart';
import 'package:kalakritiapp/providers/category_provider.dart';
import 'package:kalakritiapp/providers/seller_provider.dart';
import 'package:kalakritiapp/providers/seller_service_provider.dart';
import 'package:kalakritiapp/screens/seller/product_ar_upload.dart';
import 'package:kalakritiapp/widgets/custom_button.dart';
import 'package:kalakritiapp/widgets/custom_text_field.dart';
import 'package:kalakritiapp/widgets/image_picker_widget.dart';
import 'package:kalakritiapp/widgets/loading_overlay.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kalakritiapp/models/product.dart';

class EditProductScreen extends ConsumerStatefulWidget {
  final String productId;

  const EditProductScreen({
    Key? key,
    required this.productId,
  }) : super(key: key);

  @override
  ConsumerState<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends ConsumerState<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  String? _errorMessage;
  
  // Form controllers
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _quantityController;
  late TextEditingController _sizeController;
  late TextEditingController _weightController;
  late TextEditingController _materialController;
  late TextEditingController _discountController;
  
  // Product data
  List<String> _existingImageUrls = [];
  List<XFile> _newImages = [];
  List<String> _selectedCategories = [];
  bool _isFeatured = false;
  String? _arModelUrl;
  
  // For specifications
  List<Map<String, String>> _specifications = [];
  final TextEditingController _specKeyController = TextEditingController();
  final TextEditingController _specValueController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadProductData();
  }
  
  void _initializeControllers() {
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _priceController = TextEditingController();
    _quantityController = TextEditingController();
    _sizeController = TextEditingController();
    _weightController = TextEditingController();
    _materialController = TextEditingController();
    _discountController = TextEditingController();
  }
  
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
    _specKeyController.dispose();
    _specValueController.dispose();
    super.dispose();
  }
  
  Future<void> _loadProductData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final product = await ref.read(sellerServiceProvider).getProductById(widget.productId);
      if (product == null) {
        setState(() {
          _errorMessage = 'Product not found';
          _isLoading = false;
        });
        return;
      }
      
      // Set form values
      _nameController.text = product.name;
      _descriptionController.text = product.description;
      _priceController.text = product.price.toString();
      _quantityController.text = product.quantity.toString();
      if (product.size != null) _sizeController.text = product.size!;
      if (product.weight != null) _weightController.text = product.weight!;
      if (product.material != null) _materialController.text = product.material!;
      _discountController.text = product.discountPercentage.toString();
      
      setState(() {
        _existingImageUrls = List<String>.from(product.imageUrls);
        _selectedCategories = List<String>.from(product.categories);
        _isFeatured = product.isFeatured;
        _arModelUrl = product.arModelUrl;
        
        // Parse specifications
        if (product.specifications != null) {
          product.specifications!.forEach((key, value) {
            _specifications.add({
              'key': key,
              'value': value.toString(),
            });
          });
        }
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading product: $e';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_existingImageUrls.isEmpty && _newImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one product image')),
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
      // Prepare specifications map
      final Map<String, dynamic> specifications = {};
      for (var spec in _specifications) {
        specifications[spec['key']!] = spec['value'];
      }
      
      await ref.read(sellerServiceProvider).updateProduct(
        productId: widget.productId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text),
        quantity: int.parse(_quantityController.text),
        newImages: _newImages,
        existingImageUrls: _existingImageUrls,
        categories: _selectedCategories,
        size: _sizeController.text.trim(),
        weight: _weightController.text.trim(),
        material: _materialController.text.trim(),
        specifications: specifications,
        discountPercentage: _discountController.text.isNotEmpty 
            ? double.parse(_discountController.text) 
            : 0.0,
        isFeatured: _isFeatured,
        arModelUrl: _arModelUrl,
      );
      
      // Refresh the products list
      ref.refresh(sellerProductsProvider);
      
      // Navigate back on success
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product updated successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error updating product: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    
    if (images.isNotEmpty) {
      setState(() {
        _newImages.addAll(images);
      });
    }
  }
  
  void _removeExistingImage(int index) {
    setState(() {
      _existingImageUrls.removeAt(index);
    });
  }
  
  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }
  
  void _addSpecification() {
    final key = _specKeyController.text.trim();
    final value = _specValueController.text.trim();
    
    if (key.isNotEmpty && value.isNotEmpty) {
      setState(() {
        _specifications.add({
          'key': key,
          'value': value,
        });
        _specKeyController.clear();
        _specValueController.clear();
      });
    }
  }
  
  void _removeSpecification(int index) {
    setState(() {
      _specifications.removeAt(index);
    });
  }

  Future<void> _navigateToARModelUpload() async {
    // Create a temporary Product object from current data
    final tempProduct = Product(
      id: widget.productId,
      name: _nameController.text,
      description: _descriptionController.text,
      price: double.tryParse(_priceController.text) ?? 0,
      isAvailableForRent: false,
      isAvailableForSale: true,
      categoryId: _selectedCategories.firstOrNull ?? '',
      imageUrls: _existingImageUrls,
      isFeatured: _isFeatured,
      rating: 0,
      ratingCount: 0,
      specifications: {},
      createdAt: DateTime.now(),
      artisanId: '',
      artisanName: '',
      stock: int.tryParse(_quantityController.text) ?? 0,
      arModelUrl: _arModelUrl,
    );
    
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => ProductARUpload(product: tempProduct),
      ),
    );
    
    if (result != null) {
      setState(() {
        _arModelUrl = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Product'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          actions: [
            TextButton(
              onPressed: _updateProduct,
              child: const Text(
                'Save',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        body: _errorMessage != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Error',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
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
                      
                      // Existing images
                      if (_existingImageUrls.isNotEmpty)
                        Container(
                          height: 120,
                          margin: const EdgeInsets.only(bottom: 16),
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _existingImageUrls.length,
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
                                      child: CachedNetworkImage(
                                        imageUrl: _existingImageUrls[index],
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                        errorWidget: (context, url, error) => const Center(
                                          child: Icon(Icons.error),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 8,
                                    child: InkWell(
                                      onTap: () => _removeExistingImage(index),
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
                      
                      // New images
                      if (_newImages.isNotEmpty)
                        Container(
                          height: 120,
                          margin: const EdgeInsets.only(bottom: 16),
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _newImages.length,
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
                                        File(_newImages[index].path),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 8,
                                    child: InkWell(
                                      onTap: () => _removeNewImage(index),
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
                      
                      // Add image button
                      ElevatedButton.icon(
                        onPressed: _pickImages,
                        icon: const Icon(Icons.add_photo_alternate),
                        label: const Text('Add Images'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Basic product info
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
                      
                      // Product description
                      CustomTextField(
                        controller: _descriptionController,
                        hintText: 'Product Description',
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
                      
                      // Price and quantity
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _priceController,
                              hintText: 'Price (₹)',
                              prefixIcon: Icons.currency_rupee,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                final price = double.tryParse(value);
                                if (price == null || price <= 0) {
                                  return 'Invalid price';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomTextField(
                              controller: _quantityController,
                              hintText: 'Quantity',
                              prefixIcon: Icons.inventory,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                final quantity = int.tryParse(value);
                                if (quantity == null || quantity < 0) {
                                  return 'Invalid';
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
                        hintText: 'Discount Percentage (e.g., 10)',
                        prefixIcon: Icons.discount,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 24),
                      
                      // Featured product switch
                      SwitchListTile(
                        title: const Text('Featured Product'),
                        subtitle: const Text('Show this product on the homepage'),
                        value: _isFeatured,
                        onChanged: (value) {
                          setState(() {
                            _isFeatured = value;
                          });
                        },
                        activeColor: Theme.of(context).colorScheme.primary,
                      ),
                      const Divider(),
                      const SizedBox(height: 16),
                      
                      // Categories
                      Text(
                        'Categories',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      categoriesAsync.when(
                        data: (categories) {
                          if (categories.isEmpty) {
                            return const Text('No categories available');
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
                        error: (_, __) => const Text('Error loading categories'),
                      ),
                      const SizedBox(height: 24),
                      
                      // Product details
                      Text(
                        'Product Specifications',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Size, weight, material
                      CustomTextField(
                        controller: _sizeController,
                        hintText: 'Size (e.g., 10x15 cm)',
                        prefixIcon: Icons.straighten,
                      ),
                      const SizedBox(height: 16),
                      
                      CustomTextField(
                        controller: _weightController,
                        hintText: 'Weight (e.g., 500g)',
                        prefixIcon: Icons.fitness_center,
                      ),
                      const SizedBox(height: 16),
                      
                      CustomTextField(
                        controller: _materialController,
                        hintText: 'Material (e.g., Clay, Wood)',
                        prefixIcon: Icons.category,
                      ),
                      const SizedBox(height: 24),
                      
                      // Custom specifications
                      Text(
                        'Additional Specifications',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Add spec form
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _specKeyController,
                              hintText: 'Feature (e.g., Color)',
                              dense: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: CustomTextField(
                              controller: _specValueController,
                              hintText: 'Value (e.g., Red)',
                              dense: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.add_circle),
                            onPressed: _addSpecification,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Specifications list
                      ..._specifications.asMap().entries.map((entry) {
                        final index = entry.key;
                        final spec = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text('${spec['key']}: ${spec['value']}'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20),
                                onPressed: () => _removeSpecification(index),
                                color: Colors.red,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 32),
                      
                      // Add 3D model section after the specifications section
                      _build3DModelSection(),
                      
                      // Submit button
                      CustomButton(
                        text: 'Update Product',
                        onPressed: _updateProduct,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _build3DModelSection() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.view_in_ar,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '3D Model',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_arModelUrl != null) ...[
              Text(
                'This product has a 3D model',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
            ],
            
            ElevatedButton.icon(
              icon: Icon(_arModelUrl == null ? Icons.add : Icons.edit),
              label: Text(_arModelUrl == null ? 'Add 3D Model' : 'Change 3D Model'),
              onPressed: _navigateToARModelUpload,
            ),
          ],
        ),
      ),
    );
  }
} 