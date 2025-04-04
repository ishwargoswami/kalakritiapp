import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kalakritiapp/providers/auth_provider.dart';
import 'package:kalakritiapp/providers/chat_provider.dart';
import 'package:kalakritiapp/screens/auth/login_screen.dart';
import 'package:kalakritiapp/screens/chats_list_screen.dart';
import 'package:kalakritiapp/screens/seller/orders_screen.dart';
import 'package:kalakritiapp/screens/seller/seller_dashboard_screen.dart';
import 'package:kalakritiapp/screens/seller/seller_profile_screen.dart';
import 'package:page_transition/page_transition.dart';

class SellerHomeScreen extends ConsumerStatefulWidget {
  const SellerHomeScreen({super.key});

  @override
  ConsumerState<SellerHomeScreen> createState() => _SellerHomeScreenState();
}

class _SellerHomeScreenState extends ConsumerState<SellerHomeScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  
  // Seller-specific screens
  final List<Widget> _pages = [
    const SellerDashboardScreen(),
    const OrdersScreen(),
    const ChatsListScreen(),
    const SellerProfileScreen(),
  ];
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get unread messages count for badge
    final unreadMessagesCount = ref.watch(unreadMessagesCountProvider).asData?.value ?? 0;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(
          'कलाकृति Seller',
          style: GoogleFonts.notoSansDevanagari(
            textStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
              letterSpacing: 1.5,
            ),
          ),
        ),
        actions: [
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
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Orders',
          ),
          // Messages tab with unread count badge
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.chat_outlined),
                if (unreadMessagesCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: Text(
                        unreadMessagesCount > 9 ? '9+' : unreadMessagesCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Messages',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 10,
      ),
    );
  }
} 