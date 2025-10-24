// lib/screens/what_is_self_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/theme_controller.dart';

class WhatIsSelfScreen extends StatelessWidget {
  const WhatIsSelfScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('What is Self?'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            tooltip: 'Toggle theme',
            onPressed: () {
              Provider.of<ThemeController>(context, listen: false).toggle();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Meeting Your Core Self'),
            _buildParagraph(
              'At the center of your inner family of Parts is your core Self. This isn\'t about one aspect of you being "better" or "more real" than another; it\'s about a different role.'
            ),
            _buildParagraph(
              'You can think of your Self as the calm, compassionate partner at the center of your inner family. While your Parts have taken on specific, active jobs (like protecting you or holding memories), your Self is the natural, patient presence from which you can listen to and care for all your Parts. It\'s your core of compassion, curiosity, and calm.'
            ),
            _buildParagraph(
              'A beautiful idea in IFS is that your Self is always there, no matter what. It can get obscured by our active Parts, like the sun hidden behind clouds, but it can never be damaged or broken. The goal of IFS is not to create this Self, but to help you access it more easily.'
            ),
            
            _buildSectionTitle('The Qualities of Self (The 8 C’s)'),
            _buildParagraph(
              'How do you know when your Self is present? You\'ll often notice a shift in your feeling. The Self has many natural qualities, often called the "8 C\'s":'
            ),
            _buildBulletPoint('Calm'),
            _buildBulletPoint('Curiosity'),
            _buildBulletPoint('Clarity'),
            _buildBulletPoint('Compassion'),
            _buildBulletPoint('Confidence'),
            _buildBulletPoint('Courage'),
            _buildBulletPoint('Creativity'),
            _buildBulletPoint('Connectedness'),
            _buildParagraph(
              'You don\'t need to have all of these at once. Often, just a small amount of "Self energy," like a spark of curiosity or a moment of calm, is all that\'s needed to begin.'
            ),
            
            _buildSectionTitle('The Role of Self in Healing'),
            _buildParagraph(
              'The goal is never for the Self to dominate, control, or silence Parts. Instead, the Self acts as the compassionate leader and collaborator.'
            ),
            _buildParagraph(
              'When you can approach your Parts from this place of Self, you can build a trusting relationship with them. The Self is who can listen to their fears and stories, validate their efforts, and help them relax.'
            ),
            _buildParagraph(
              'From this compassionate and clear place, you can shift from feeling stuck in automatic reactions to making kinder, clearer choices. You can practice noticing your Self every day. When you pause and find a moment of genuine calm or curiosity, even for a second, that is your Self showing up.'
            ),
            
            // Standardized footer (as requested)
            Container(
              margin: const EdgeInsets.only(top: 24.0),
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red, width: 2.0),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: const Text(
                'This information is for educational use and is not a substitute for therapy or emergency care.',
                style: TextStyle(fontSize: 14.0, height: 1.4),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20.0,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16.0, height: 1.5),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16.0)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16.0, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}