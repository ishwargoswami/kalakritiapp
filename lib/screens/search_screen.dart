import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalakritiapp/models/product.dart';
import 'package:kalakritiapp/providers/product_provider.dart';
import 'package:kalakritiapp/utils/theme.dart';
import 'package:kalakritiapp/widgets/product_card_vertical.dart';
import 'package:shimmer/shimmer.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _showFilters = false;
  
  // Filter options
  RangeValues _priceRange = const RangeValues(0, 10000);
  double _maxPrice = 10000;
  List<String> _selectedCategories = [];
  bool _onlyAvailableForRent = false;
  String _sortBy = 'relevance';
  
  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text;
      });
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Only watch search results if query is not empty
    final searchResultsAsync = _query.isEmpty 
        ? const AsyncValue<List<Product>>.data([])
        : ref.watch(searchProductsProvider(_query));
    
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search for products...',
            hintStyle: const TextStyle(color: Colors.white70),
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                : null,
          ),
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_list_off : Icons.filter_list,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _showFilters ? 300 : 0,
            color: Colors.white,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Price range
                    Text(
                      'Price Range',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: kPrimaryColor,
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '₹${_priceRange.start.toInt()}',
                          style: TextStyle(
                            color: kTextColor,
                          ),
                        ),
                        Expanded(
                          child: RangeSlider(
                            values: _priceRange,
                            max: _maxPrice,
                            divisions: 100,
                            labels: RangeLabels(
                              '₹${_priceRange.start.toInt()}',
                              '₹${_priceRange.end.toInt()}',
                            ),
                            onChanged: (values) {
                              setState(() {
                                _priceRange = values;
                              });
                            },
                            activeColor: kSecondaryColor,
                            inactiveColor: kSlateGray.withOpacity(0.3),
                          ),
                        ),
                        Text(
                          '₹${_priceRange.end.toInt()}',
                          style: TextStyle(
                            color: kTextColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Categories
                    Text(
                      'Categories',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: kPrimaryColor,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildCategoryChip('Painting'),
                        _buildCategoryChip('Sculpture'),
                        _buildCategoryChip('Pottery'),
                        _buildCategoryChip('Textile'),
                        _buildCategoryChip('Jewelry'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Rental availability
                    Row(
                      children: [
                        Text(
                          'Available for Rent',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: kPrimaryColor,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        Switch(
                          value: _onlyAvailableForRent,
                          onChanged: (value) {
                            setState(() {
                              _onlyAvailableForRent = value;
                            });
                          },
                          activeColor: kSecondaryColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Sort by
                    Text(
                      'Sort By',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: kPrimaryColor,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildSortChip('relevance', 'Relevance'),
                        _buildSortChip('price_low', 'Price: Low to High'),
                        _buildSortChip('price_high', 'Price: High to Low'),
                        _buildSortChip('newest', 'Newest First'),
                        _buildSortChip('popularity', 'Popularity'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Apply button
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _priceRange = const RangeValues(0, 10000);
                              _selectedCategories = [];
                              _onlyAvailableForRent = false;
                              _sortBy = 'relevance';
                            });
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reset Filters'),
                          style: TextButton.styleFrom(
                            foregroundColor: kTextColor.withOpacity(0.7),
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _showFilters = false;
                            });
                          },
                          icon: const Icon(Icons.check),
                          label: const Text('Apply'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kAccentColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Search results
          Expanded(
            child: _query.isEmpty
                ? _buildEmptyState()
                : searchResultsAsync.when(
                    data: (products) => _buildSearchResults(products),
                    loading: () => _buildLoadingShimmer(),
                    error: (error, stackTrace) => Center(
                      child: Text('Error: $error'),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
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
      backgroundColor: Colors.white,
      selectedColor: kSecondaryColor.withOpacity(0.2),
      checkmarkColor: kSecondaryColor,
      labelStyle: TextStyle(
        color: isSelected ? kPrimaryColor : kTextColor,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? kSecondaryColor : Colors.grey[300]!,
      ),
    );
  }

  Widget _buildSortChip(String value, String label) {
    final isSelected = _sortBy == value;
    
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _sortBy = value;
          });
        }
      },
      backgroundColor: Colors.white,
      selectedColor: kSecondaryColor.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? kPrimaryColor : kTextColor,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? kSecondaryColor : Colors.grey[300]!,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 80,
            color: kSlateGray.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Search for products',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: kTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter keywords to find products',
            style: TextStyle(
              color: kTextColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(List<Product> products) {
    // Filter products based on search and filters
    final filteredProducts = products.where((product) {
      // Search query filter
      if (_query.isNotEmpty && !product.name.toLowerCase().contains(_query.toLowerCase())) {
        return false;
      }
      
      // Price range filter
      if (product.price < _priceRange.start || product.price > _priceRange.end) {
        return false;
      }
      
      // Category filter
      if (_selectedCategories.isNotEmpty && !_selectedCategories.contains(product.category)) {
        return false;
      }
      
      // Rental availability filter
      if (_onlyAvailableForRent && !product.isAvailableForRent) {
        return false;
      }
      
      return true;
    }).toList();
    
    // Sort products
    switch (_sortBy) {
      case 'price_low':
        filteredProducts.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_high':
        filteredProducts.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'newest':
        filteredProducts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'popularity':
        filteredProducts.sort((a, b) => b.rating.compareTo(a.rating));
        break;
    }
    
    if (filteredProducts.isEmpty) {
      return _buildEmptyState();
    }
    
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: filteredProducts.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return ProductCardVertical(product: filteredProducts[index]);
      },
    );
  }

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: 10,
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
} 