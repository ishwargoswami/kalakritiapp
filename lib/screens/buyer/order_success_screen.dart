import 'package:flutter/material.dart';
import 'package:kalakritiapp/constants.dart';
import 'package:kalakritiapp/screens/buyer/order_details_screen.dart';
import 'package:kalakritiapp/screens/home_screen.dart';
import 'package:lottie/lottie.dart';

class OrderSuccessScreen extends StatelessWidget {
  final String orderId;

  const OrderSuccessScreen({
    Key? key,
    required this.orderId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Title at the top
                const Text(
                  'Your Order is on the Way!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: kSecondaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                
                // Delivery car animation
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: double.infinity,
                    height: 220,
                    decoration: BoxDecoration(
                      color: kSecondaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Stack(
                      children: [
                        // Animated car with package delivery
                        Lottie.asset(
                          'assets/animations/Animation - 1743794838241.json',
                          fit: BoxFit.cover,
                          repeat: true,
                        ),
                        
                        // Overlay message on top of animation
                        Positioned(
                          top: 15,
                          right: 15,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Preparing Delivery',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: kSecondaryColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                
                // Order success card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 2,
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Success icon
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: kSecondaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          size: 40,
                          color: kSecondaryColor,
                        ),
                      ),
                      const SizedBox(height: 15),
                      
                      // Success message
                      const Text(
                        'Order Placed Successfully!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: kTextColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      
                      // Order ID
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                        decoration: BoxDecoration(
                          color: kSecondaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Order ID: $orderId',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: kSecondaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      
                      // Thank you message
                      const Text(
                        'Thank you for your purchase! We\'ve received your order and will notify you once it\'s on its way.',
                        style: TextStyle(
                          fontSize: 14,
                          color: kTextColor,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                
                // Buttons row
                Row(
                  children: [
                    // View Order Details Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrderDetailsScreen(orderId: orderId),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kSecondaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'View Order Details',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                
                // Continue Shopping Button
                OutlinedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HomeScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    side: const BorderSide(color: kSecondaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_bag_outlined, color: kSecondaryColor),
                      SizedBox(width: 8),
                      Text(
                        'Continue Shopping',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: kSecondaryColor,
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