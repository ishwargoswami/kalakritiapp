import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class GLBCreationGuideScreen extends StatelessWidget {
  const GLBCreationGuideScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create 3D Models (.glb)'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, 'What is a GLB file?'),
              const SizedBox(height: 8),
              const Text(
                'GLB files are 3D model files that contain textures, materials, and animations in a single binary file. '
                'They are ideal for web and mobile 3D applications, including AR experiences in Kalakriti.',
              ),
              const SizedBox(height: 24),
              
              _buildHeader(context, 'Options to Create GLB Models'),
              const SizedBox(height: 8),
              
              // Option 1: Online Services
              _buildOption(
                context,
                '1. Use Online 3D Model Creators',
                'Online tools let you create 3D models without installing software.',
                [
                  _buildToolCard(
                    context,
                    'Sketchfab',
                    'A platform to publish, share, and discover 3D content. It also offers tools to convert existing 3D models to GLB format.',
                    'https://sketchfab.com/',
                    Icons.hub,
                  ),
                  _buildToolCard(
                    context,
                    'SculptGL',
                    'A free online 3D sculpting tool that allows you to create simple to complex 3D models directly in your browser.',
                    'https://stephaneginier.com/sculptgl/',
                    Icons.bubble_chart,
                  ),
                  _buildToolCard(
                    context,
                    'Vectary',
                    'An easy-to-use online 3D design and modeling tool with GLB export functionality.',
                    'https://www.vectary.com/',
                    Icons.view_in_ar,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Option 2: Desktop Software
              _buildOption(
                context,
                '2. Professional 3D Modeling Software',
                'If you need more control and advanced features:',
                [
                  _buildToolCard(
                    context,
                    'Blender (Free)',
                    'A free and open-source 3D creation suite supporting modeling, rigging, animation, simulation, rendering, and game creation.',
                    'https://www.blender.org/',
                    Icons.architecture,
                  ),
                  _buildToolCard(
                    context,
                    'Maya & 3DS Max',
                    'Professional 3D modeling software by Autodesk with comprehensive tools for 3D rendering and animation.',
                    'https://www.autodesk.com/',
                    Icons.precision_manufacturing,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Option 3: Mobile Apps
              _buildOption(
                context,
                '3. Mobile 3D Scanning Apps',
                'Create 3D models by scanning real objects:',
                [
                  _buildToolCard(
                    context,
                    'Polycam',
                    'Capture 3D scans of objects and spaces with your phone camera.',
                    'https://poly.cam/',
                    Icons.camera,
                  ),
                  _buildToolCard(
                    context,
                    'Scaniverse',
                    'Create detailed 3D scans with your phone and export them in various formats including GLB.',
                    'https://scaniverse.com/',
                    Icons.view_in_ar_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Step-by-step guide section
              _buildHeader(context, 'Step-by-Step Guide'),
              const SizedBox(height: 8),
              
              _buildStepCard(
                context,
                1,
                'Create or Obtain a 3D Model',
                'Use one of the tools above to create a 3D model, or use an existing model you have the rights to use.',
              ),
              _buildStepCard(
                context,
                2,
                'Optimize Your Model',
                'Keep your model under 10MB for best performance. Reduce polygon count and texture sizes if needed.',
              ),
              _buildStepCard(
                context,
                3,
                'Export as GLB Format',
                'Most 3D tools have an export option. Select GLB as your output format.',
              ),
              _buildStepCard(
                context,
                4,
                'Upload to Kalakriti',
                'Use the \'Upload 3D Model\' button in the product editor to add your GLB file.',
              ),
              _buildStepCard(
                context,
                5,
                'Preview and Confirm',
                'Preview your model in the AR viewer to ensure it appears correctly before saving.',
              ),
              
              const SizedBox(height: 32),
              
              // Tips section
              _buildHeader(context, 'Tips for Great 3D Models'),
              const SizedBox(height: 8),
              _buildTips(context),
              
              const SizedBox(height: 32),
              
              // AI-Generated models section
              _buildHeader(context, 'Try AI-Generated 3D Models'),
              const SizedBox(height: 8),
              const Text(
                'New AI tools can create 3D models from text descriptions or images:',
              ),
              const SizedBox(height: 16),
              _buildToolCard(
                context,
                'Kaedim',
                'Upload a 2D image and get a 3D model created by AI.',
                'https://www.kaedim3d.com/',
                Icons.psychology,
              ),
              _buildToolCard(
                context,
                'Luma AI',
                'Generate 3D models and scenes from text descriptions.',
                'https://lumalabs.ai/',
                Icons.auto_awesome,
              ),
              const SizedBox(height: 32),
              
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Return to Upload Screen'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
    );
  }

  Widget _buildOption(
    BuildContext context,
    String title,
    String description,
    List<Widget> tools,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(description),
        const SizedBox(height: 16),
        ...tools,
      ],
    );
  }

  Widget _buildToolCard(
    BuildContext context,
    String title,
    String description,
    String url,
    IconData icon,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _launchUrl(url),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 32,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(description),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.open_in_new, size: 16),
                          label: const Text('Visit'),
                          onPressed: () => _launchUrl(url),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepCard(
    BuildContext context,
    int stepNumber,
    String title,
    String description,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  stepNumber.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(description),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTips(BuildContext context) {
    final tips = [
      'Keep file size under 10MB for optimal performance',
      'Use appropriate scale - people are about 1.8 units high',
      'Center your model at the origin (0,0,0) for correct positioning in AR',
      'Reduce polygon count to improve loading speed and performance',
      'Ensure your model has proper lighting and materials for best appearance',
      'Test your model in AR view before publishing your product',
    ];

    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...tips.map((tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle, size: 20, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(child: Text(tip)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }
} 