import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kalakritiapp/screens/home_screen.dart';
import 'package:kalakritiapp/utils/theme.dart';
import 'package:kalakritiapp/widgets/custom_button.dart';
import 'package:lottie/lottie.dart';

class OrderConfirmationScreen extends ConsumerStatefulWidget {
  final String orderId;
  final double orderTotal;

  const OrderConfirmationScreen({
    super.key,
    required this.orderId,
    required this.orderTotal,
  });

  @override
  ConsumerState<OrderConfirmationScreen> createState() => _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends ConsumerState<OrderConfirmationScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 5));
    
    // Start the confetti animation after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _confettiController.play();
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 2,
    );
    
    // Generate a random estimate delivery date (3-5 days from now)
    final deliveryDate = DateTime.now().add(
      Duration(days: 3 + (DateTime.now().millisecondsSinceEpoch % 3)),
    );
    
    return WillPopScope(
      onWillPop: () async {
        _navigateToHome();
        return false;
      },
      child: Scaffold(
        backgroundColor: kBackgroundColor,
        body: Stack(
          children: [
            // Confetti
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                particleDrag: 0.05,
                emissionFrequency: 0.05,
                numberOfParticles: 20,
                gravity: 0.1,
                colors: [
                  kPrimaryColor,
                  kSecondaryColor,
                  kAccentColor,
                  kLightPink,
                ],
              ),
            ),
            
            // Main content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Success animation
                      Lottie.network(
                        'https://assets10.lottiefiles.com/packages/lf20_jbrw3hcz.json',
                        height: 200,
                        repeat: false,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Success heading
                      Text(
                        'Order Confirmed!',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryColor,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Success message
                      Text(
                        'Your order has been successfully placed and is being processed.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: kTextColor,
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Order details card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildOrderDetailRow(
                              'Order ID',
                              '#${widget.orderId.substring(0, 8).toUpperCase()}',
                            ),
                            _buildDivider(),
                            _buildOrderDetailRow(
                              'Order Date',
                              DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now()),
                            ),
                            _buildDivider(),
                            _buildOrderDetailRow(
                              'Order Amount',
                              formatter.format(widget.orderTotal),
                              valueColor: kPrimaryColor,
                              isBold: true,
                            ),
                            _buildDivider(),
                            _buildOrderDetailRow(
                              'Payment Method',
                              'Credit Card',
                            ),
                            _buildDivider(),
                            _buildOrderDetailRow(
                              'Estimated Delivery',
                              DateFormat('dd MMM yyyy').format(deliveryDate),
                              valueColor: kSecondaryColor,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // What happens next section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'What happens next?',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: kPrimaryColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildStepItem(
                              '1',
                              'Order Processing',
                              "We're preparing your order for shipping.",
                            ),
                            _buildStepItem(
                              '2',
                              'Order Shipped',
                              'Your order will be on its way to you soon.',
                            ),
                            _buildStepItem(
                              '3',
                              'Order Delivered',
                              'Enjoy your beautiful Kalakriti products!',
                              isLast: true,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Continue Shopping Button
                      CustomButton(
                        text: 'Continue Shopping',
                        onPressed: _navigateToHome,
                        backgroundColor: kAccentColor,
                        textColor: Colors.white,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Track Order Button
                      CustomButton(
                        text: 'Track Order',
                        onPressed: () {
                          // TODO: Implement order tracking
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Order tracking will be available soon!'),
                            ),
                          );
                        },
                        isOutlined: true,
                        backgroundColor: kPrimaryColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetailRow(String label, String value, {Color? valueColor, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: kTextColor.withOpacity(0.8),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: valueColor ?? kTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.grey[200],
      height: 1,
    );
  }

  Widget _buildStepItem(String number, String title, String description, {bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step number circle
        Container(
          width: 24,
          height: 24,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            color: kSecondaryColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Step content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: kTextColor.withOpacity(0.8),
                ),
              ),
              if (!isLast)
                Container(
                  margin: const EdgeInsets.only(left: 0, top: 8, bottom: 8),
                  width: 2,
                  height: 20,
                  color: kSecondaryColor.withOpacity(0.3),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _navigateToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }
} 