import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kalakritiapp/models/category.dart';
import 'package:kalakritiapp/models/product.dart';
import 'package:kalakritiapp/models/user_role.dart';
import 'package:kalakritiapp/providers/auth_provider.dart';
import 'package:kalakritiapp/providers/cart_provider.dart';
import 'package:kalakritiapp/providers/category_provider.dart';
import 'package:kalakritiapp/providers/product_provider.dart';
import 'package:kalakritiapp/providers/seller_provider.dart';
import 'package:kalakritiapp/providers/wishlist_provider.dart';
import 'package:kalakritiapp/screens/auth/login_screen.dart';
import 'package:kalakritiapp/screens/cart_screen.dart';
import 'package:kalakritiapp/screens/category_screen.dart';
import 'package:kalakritiapp/screens/product_detail_screen.dart';
import 'package:kalakritiapp/screens/profile_screen.dart';
import 'package:kalakritiapp/screens/rentals_screen.dart';
import 'package:kalakritiapp/screens/search_screen.dart';
import 'package:kalakritiapp/screens/seller/seller_home_screen.dart';
import 'package:kalakritiapp/screens/wishlist_screen.dart';
import 'package:kalakritiapp/screens/all_categories_screen.dart';
import 'package:kalakritiapp/screens/chats_list_screen.dart';
import 'package:kalakritiapp/services/auth_service.dart';
import 'package:kalakritiapp/utils/theme.dart';
import 'package:kalakritiapp/widgets/animated_navigation.dart';
import 'package:kalakritiapp/widgets/category_card.dart';
import 'package:kalakritiapp/widgets/enhanced_carousel_slider.dart';
import 'package:kalakritiapp/widgets/loading_overlay.dart';
import 'package:kalakritiapp/widgets/product_card.dart';
import 'package:kalakritiapp/widgets/section_title.dart';
import 'package:animate_do/animate_do.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shimmer/shimmer.dart';
import 'package:kalakritiapp/utils/sample_data_util.dart';
import 'package:kalakritiapp/providers/chat_provider.dart';
import 'package:kalakritiapp/widgets/string_category_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  bool _isLoading = true;
  bool _isSeller = false;
  
  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }
  
  Future<void> _checkUserRole() async {
    final authService = ref.read(authServiceProvider);
    
    try {
      final role = await authService.getCurrentUserRole();
      
      if (mounted) {
        if (role == UserRole.seller) {
          // If user is a seller, redirect to the seller home screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const SellerHomeScreen()),
          );
        } else {
          setState(() {
            _isSeller = false;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSeller = false;
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavItemTapped(AnimatedNavItemType type) {
    final index = type.index;
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    // Explicitly allow screenshots by setting DeviceOrientation
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    
    if (_isLoading) {
      return const LoadingOverlay(
        isLoading: true,
        child: Scaffold(
          body: Center(
            child: Text('Loading...'),
          ),
        ),
      );
    }
    
    // Buyer-specific pages
    final List<Widget> _pages = [
      const _PageWithBottomPadding(child: HomePage()),
      const _PageWithBottomPadding(child: AllCategoriesScreen()),
      const _PageWithBottomPadding(child: RentalsScreen()),
      const _PageWithBottomPadding(child: ChatsListScreen()),
      const _PageWithBottomPadding(child: WishlistScreen()),
      const _PageWithBottomPadding(child: CartScreen()),
      const _PageWithBottomPadding(child: ProfileScreen()),
    ];
    
    final wishlistCount = ref.watch(wishlistCountProvider);
    final cartItemCount = ref.watch(cartItemCountProvider);
    final unreadMessagesCountAsyncValue = ref.watch(unreadMessagesCountProvider);
    final unreadMessagesCount = unreadMessagesCountAsyncValue.when(
      data: (count) => count,
      loading: () => 0,
      error: (_, __) => 0,
    );
    
    return Scaffold(
      appBar: _currentIndex == 0 ? AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(
          'कलाकृति',
          style: GoogleFonts.notoSansDevanagari(
            textStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 28,
              letterSpacing: 1.5,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                PageTransition(
                  type: PageTransitionType.rightToLeft,
                  child: const SearchScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {
              // TODO: Implement notifications
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications coming soon!')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  PageTransition(
                    type: PageTransitionType.fade,
                    child: const LoginScreen(),
                  ),
                );
              }
            },
          ),
        ],
      ) : null,
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            children: _pages,
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedNavigation(
              selectedItem: AnimatedNavItemType.values[_currentIndex],
              onItemSelected: _onNavItemTapped,
              wishlistCount: wishlistCount,
              cartItemCount: cartItemCount,
              unreadMessagesCount: unreadMessagesCount,
            ),
          ),
        ],
      ),
    );
  }
}

// Wrapper for pages to add bottom padding
class _PageWithBottomPadding extends StatelessWidget {
  final Widget child;
  
  const _PageWithBottomPadding({required this.child});
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 80),
      child: child,
    );
  }
}

// Home page content
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get data from providers
    final featuredProductsAsync = ref.watch(featuredProductsProvider);
    final newArrivalsAsync = ref.watch(newArrivalsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final bestSellersAsync = ref.watch(bestSellersProvider);
    final handicraftsAsync = ref.watch(productsByCategoryNameProvider('Handicrafts'));
    final traditionalAsync = ref.watch(productsByCategoryNameProvider('Traditional'));
    
    // Function to refresh all data
    Future<void> _refreshData() async {
      // Invalidate all providers to force refresh
      ref.invalidate(featuredProductsProvider);
      ref.invalidate(newArrivalsProvider);
      ref.invalidate(categoriesProvider);
      ref.invalidate(bestSellersProvider);
      ref.invalidate(productsByCategoryNameProvider('Handicrafts'));
      ref.invalidate(productsByCategoryNameProvider('Traditional'));
      
      // For StreamProviders, we need to wait a bit to ensure the data is refreshed
      return Future.delayed(const Duration(milliseconds: 500));
    }
    
    // Carousel items
    final List<Map<String, dynamic>> carouselItems = [
      {
        'image': 'https://images.pexels.com/photos/6464421/pexels-photo-6464421.jpeg',
        'title': 'Authentic Indian Crafts',
        'subtitle': 'Explore our collection of handcrafted items',
        'color': Colors.indigo,
        'button': 'Explore',
        'buttonAction': () {
          Navigator.push(
            context,
            PageTransition(
              type: PageTransitionType.rightToLeft,
              child: const CategoryScreen(
                category: const Category(
                  id: 'handicrafts',
                  name: 'Handicrafts',
                  description: 'Beautiful handcrafted items from skilled artisans',
                  imageUrl: 'https://images.pexels.com/photos/12029653/pexels-photo-12029653.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
                  productCount: 0,
                  displayOrder: 4,
                ),
              ),
            ),
          );
        },
        'badge': 'Featured',
        'badgeColor': Colors.orange,
      },
      {
        'image': 'https://images.pexels.com/photos/6192401/pexels-photo-6192401.jpeg',
        'title': 'Traditional Artistry',
        'subtitle': 'Discover the beauty of Indian heritage',
        'color': Colors.teal,
        'button': 'View Collection',
        'buttonAction': () {
          Navigator.push(
            context,
            PageTransition(
              type: PageTransitionType.rightToLeft,
              child: const CategoryScreen(
                category: const Category(
                  id: 'traditional',
                  name: 'Traditional',
                  description: 'Timeless traditional pieces celebrating Indian heritage',
                  imageUrl: 'https://images.pexels.com/photos/6192401/pexels-photo-6192401.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
                  productCount: 0,
                  displayOrder: 5,
                ),
              ),
            ),
          );
        },
      },
      {
        'image': 'https://images.pexels.com/photos/11721610/pexels-photo-11721610.jpeg',
        'title': 'Rent Exclusive Items',
        'subtitle': 'Special pieces for special occasions',
        'color': Colors.deepOrange,
        'button': 'Rent Now',
        'buttonAction': () {
          // Navigate to rentals screen
          Navigator.push(
            context,
            PageTransition(
              type: PageTransitionType.rightToLeft,
              child: const RentalsScreen(),
            ),
          );
        },
        'badge': 'Hot',
        'badgeColor': Colors.red,
      },
      {
        'image': 'https://images.pexels.com/photos/6191709/pexels-photo-6191709.jpeg',
        'title': 'Support Local Artisans',
        'subtitle': 'Every purchase empowers our craftspeople',
        'color': Colors.purple,
        'button': 'Learn More',
        'buttonAction': () {
          // TODO: Navigate to about page
        },
      },
    ];
    
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: AnimationLimiter(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(), // Important for RefreshIndicator to work
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: AnimationConfiguration.toStaggeredList(
              duration: const Duration(milliseconds: 375),
              childAnimationBuilder: (widget) => SlideAnimation(
                horizontalOffset: 50.0,
                child: FadeInAnimation(
                  child: widget,
                ),
              ),
              children: [
                // Enhanced Carousel slider at the top
                const SizedBox(height: 16),
                EnhancedCarouselSlider(
                  items: carouselItems,
                  height: 220,
                ),
                
                // Categories section with See All
                SectionTitle(
                  title: 'Categories',
                  onSeeAllPressed: () {
                    Navigator.push(
                      context,
                      PageTransition(
                        type: PageTransitionType.fade,
                        child: const AllCategoriesScreen(),
                      ),
                    );
                  },
                ),
                SizedBox(
                  height: 120,
                  child: categoriesAsync.when(
                    data: (categories) {
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          return StringCategoryCard(categoryName: categories[index]);
                        },
                      );
                    },
                    loading: () => _buildCategoryLoadingShimmer(),
                    error: (error, stackTrace) => Center(
                      child: Text(
                        'Error loading categories: $error',
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    ),
                  ),
                ),
                
                // Featured products section with See All
                SectionTitle(
                  title: 'Featured Products',
                  onSeeAllPressed: () {
                    Navigator.push(
                      context,
                      PageTransition(
                        type: PageTransitionType.rightToLeft,
                        child: const CategoryScreen(
                          category: const Category(
                            id: 'featured',
                            name: 'Featured Products',
                            description: 'Our specially curated selection of featured products',
                            imageUrl: 'https://images.pexels.com/photos/6464421/pexels-photo-6464421.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
                            productCount: 0,
                            displayOrder: 1,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(
                  height: 280,
                  child: featuredProductsAsync.when(
                    data: (products) {
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          return ProductCard(
                            product: products[index],
                            showWishlistButton: true,
                          );
                        },
                      );
                    },
                    loading: () => _buildProductLoadingShimmer(),
                    error: (error, stackTrace) => Center(
                      child: Text(
                        'Error loading products: $error',
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    ),
                  ),
                ),
                
                // New arrivals section with See All
                SectionTitle(
                  title: 'New Arrivals',
                  onSeeAllPressed: () {
                    Navigator.push(
                      context,
                      PageTransition(
                        type: PageTransitionType.rightToLeft,
                        child: const CategoryScreen(
                          category: const Category(
                            id: 'new',
                            name: 'New Arrivals',
                            description: 'The latest additions to our collection',
                            imageUrl: 'https://images.pexels.com/photos/6192401/pexels-photo-6192401.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
                            productCount: 0,
                            displayOrder: 2,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(
                  height: 280,
                  child: newArrivalsAsync.when(
                    data: (products) {
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          return ProductCard(
                            product: products[index],
                            showWishlistButton: true,
                          );
                        },
                      );
                    },
                    loading: () => _buildProductLoadingShimmer(),
                    error: (error, stackTrace) => Center(
                      child: Text(
                        'Error loading products: $error',
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    ),
                  ),
                ),
                
                // Best sellers section
                SectionTitle(
                  title: 'Best Sellers',
                  onSeeAllPressed: () {
                    Navigator.push(
                      context,
                      PageTransition(
                        type: PageTransitionType.rightToLeft,
                        child: const CategoryScreen(
                          category: const Category(
                            id: 'bestseller',
                            name: 'Best Sellers',
                            description: 'Our most popular items loved by customers',
                            imageUrl: 'https://images.pexels.com/photos/11721610/pexels-photo-11721610.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
                            productCount: 0,
                            displayOrder: 3,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(
                  height: 280,
                  child: bestSellersAsync.when(
                    data: (products) {
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          return ProductCard(
                            product: products[index],
                            showWishlistButton: true,
                          );
                        },
                      );
                    },
                    loading: () => _buildProductLoadingShimmer(),
                    error: (error, stackTrace) => Center(
                      child: Text(
                        'Error loading products: $error',
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    ),
                  ),
                ),
                
                // Handicrafts section
                SectionTitle(
                  title: 'Handicrafts',
                  onSeeAllPressed: () {
                    Navigator.push(
                      context,
                      PageTransition(
                        type: PageTransitionType.rightToLeft,
                        child: const CategoryScreen(
                          category: const Category(
                            id: 'handicrafts',
                            name: 'Handicrafts',
                            description: 'Beautiful handcrafted items from skilled artisans',
                            imageUrl: 'https://images.pexels.com/photos/12029653/pexels-photo-12029653.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
                            productCount: 0,
                            displayOrder: 4,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(
                  height: 280,
                  child: handicraftsAsync.when(
                    data: (products) {
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          return ProductCard(
                            product: products[index],
                            showWishlistButton: true,
                          );
                        },
                      );
                    },
                    loading: () => _buildProductLoadingShimmer(),
                    error: (error, stackTrace) => Center(
                      child: Text(
                        'Error loading products: $error',
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    ),
                  ),
                ),
                
                // Traditional section
                SectionTitle(
                  title: 'Traditional',
                  onSeeAllPressed: () {
                    Navigator.push(
                      context,
                      PageTransition(
                        type: PageTransitionType.rightToLeft,
                        child: const CategoryScreen(
                          category: const Category(
                            id: 'traditional',
                            name: 'Traditional',
                            description: 'Timeless traditional pieces celebrating Indian heritage',
                            imageUrl: 'https://images.pexels.com/photos/6192401/pexels-photo-6192401.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
                            productCount: 0,
                            displayOrder: 5,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(
                  height: 280,
                  child: traditionalAsync.when(
                    data: (products) {
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          return ProductCard(
                            product: products[index],
                            showWishlistButton: true,
                          );
                        },
                      );
                    },
                    loading: () => _buildProductLoadingShimmer(),
                    error: (error, stackTrace) => Center(
                      child: Text(
                        'Error loading products: $error',
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Category loading shimmer
  Widget _buildCategoryLoadingShimmer() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            width: 100,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
    );
  }

  // Product loading shimmer
  Widget _buildProductLoadingShimmer() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            width: 160,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
    );
  }
} 