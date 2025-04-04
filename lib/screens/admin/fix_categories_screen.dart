import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalakritiapp/providers/category_provider.dart';
import 'package:kalakritiapp/services/firestore_service.dart';

class FixCategoriesScreen extends ConsumerStatefulWidget {
  const FixCategoriesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<FixCategoriesScreen> createState() => _FixCategoriesScreenState();
}

class _FixCategoriesScreenState extends ConsumerState<FixCategoriesScreen> {
  bool _isLoading = false;
  String _statusMessage = '';

  Future<void> _fixCategories() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Fixing category inconsistencies...';
    });

    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.fixProductCategories();
      
      // Refresh the categories list
      ref.invalidate(categoriesProvider);
      ref.invalidate(allCategoriesProvider);
      
      setState(() {
        _statusMessage = 'Categories fixed successfully!';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error fixing categories: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fix Categories'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Category Maintenance',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'This utility will fix inconsistencies in product categories:',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text('• Ensure all products have a categories array'),
                    Text('• Make sure category field matches the first element in categories'),
                    Text('• Remove duplicate categories'),
                    Text('• Fix any miscategorized products'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _fixCategories,
                icon: const Icon(Icons.build_circle),
                label: const Text('Fix Categories'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
            if (_statusMessage.isNotEmpty)
              Card(
                color: _statusMessage.contains('Error')
                    ? Colors.red[50]
                    : Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        _statusMessage.contains('Error')
                            ? Icons.error
                            : Icons.check_circle,
                        color: _statusMessage.contains('Error')
                            ? Colors.red
                            : Colors.green,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _statusMessage,
                          style: TextStyle(
                            color: _statusMessage.contains('Error')
                                ? Colors.red
                                : Colors.green[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
} 