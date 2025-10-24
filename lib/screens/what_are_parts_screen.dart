// lib/screens/what_are_parts_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/theme_controller.dart';

class WhatArePartsScreen extends StatelessWidget {
  const WhatArePartsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('What are Parts?'),
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
            _buildParagraph(
              'It’s helpful to think of your mind as an inner family, made up of different "Parts" and your calm, compassionate core Self.'
            ),
            _buildParagraph(
              'A quick, gentle note on the word "Part": If that term feels a bit strange or even minimizing at first, that makes perfect sense. In IFS, this word is actually chosen to be more respectful. Instead of using a label that sounds "disordered", we use "Part" to honor that this is a whole, complex piece of you, with its own feelings, beliefs, and memories shaped by your life. (And if "Part" doesn’t feel right, we can always use the word that works best for you, as this process is collaborative and respects your pace).'
            ),
            _buildParagraph(
              'It’s important to know that these Parts aren’t just a single feeling (like "sadness") or a simple job (like "the critic"). Each one is a complex personality within you.'
            ),
            _buildParagraph(
              'A core, gentle idea in IFS is that all of your Parts are welcome and trying to help. If their strategies sometimes cause problems, it’s often because they are loyally using a strategy that worked to protect you in the past, but which may be out of date or no longer needed in the same way. We don’t see any Part as a flaw to be fixed. Instead, we meet them with curiosity to understand them.'
            ),
            _buildSectionTitle('Each Part Has an Important Job'),
            _buildParagraph(
              'Every Part you have has taken on a role to help you.'
            ),
            _buildBulletPoint(
              'Protective Parts: Some Parts step in to protect you, perhaps by managing emotions or helping you avoid discomfort.'
            ),
            _buildBulletPoint(
              'Hurt-Holding Parts: Other Parts quietly carry the hurt, difficult memories, or strong feelings that have been pushed aside.'
            ),
            _buildSectionTitle('How Parts Communicate'),
            _buildParagraph(
              'Often, Parts speak to us through our bodies. That sudden tightness in your chest, a sinking feeling in your stomach, or a clenched jaw is frequently a Part trying to be heard. IFS invites you to pause with gentle curiosity and ask, "What is this Part trying to tell me?".'
            ),
            _buildParagraph(
              'The goal is never to get rid of, judge, or force any Part. The journey is about building a trusting, compassionate relationship with them, helping them relax, and allowing your own calm, clear Self to lead.'
            ),
            // ✅ NO Spacer() here — it breaks layout in SingleChildScrollView
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