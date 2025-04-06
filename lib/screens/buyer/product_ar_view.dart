import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalakritiapp/widgets/ar_model_viewer.dart';
import 'package:kalakritiapp/screens/custom_camera_ar_view.dart';
import 'package:kalakritiapp/models/product.dart';
import 'package:kalakritiapp/providers/product_provider.dart';
import 'package:kalakritiapp/utils/ar_utils.dart';
import 'package:flutter/foundation.dart';

class ProductARView extends ConsumerWidget {
  final String productId;

  const ProductARView({
    Key? key,
    required this.productId,
  }) : super(key: key);

  // Helper method to determine the correct model path
  String _getModelPath(String? modelPath) {
    if (modelPath == null) return '';
    
    return ARUtils.getModelPath(modelPath);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productDetailsProvider(productId));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('AR View'),
      ),
      body: productAsync.when(
        data: (product) {
          if (product == null) {
            return const Center(child: Text('Product not found'));
          }
          
          // All products should have an AR model at this point due to our provider transformation
          final modelPath = _getModelPath(product.arModelUrl);
          
          return Column(
            children: [
              Expanded(
                child: ARModelViewer(
                  modelPath: modelPath,
                  autoRotate: true,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    
                    // KalaKriti Custom AR View Button
                    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || 
                                 defaultTargetPlatform == TargetPlatform.android))
                      ElevatedButton.icon(
                        icon: const Icon(Icons.view_in_ar),
                        label: const Text('View in Your Space (AR)'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CustomCameraARView(
                                modelPath: modelPath,
                                productName: product.name,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      'Experience your product in real surroundings with our custom AR technology!',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text('Error loading product: $error'),
        ),
      ),
    );
  }
} 