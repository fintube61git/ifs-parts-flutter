// lib/screens/landing_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/theme_controller.dart';
import '../screens/ifs_overview_screen.dart';
import '../screens/what_are_parts_screen.dart';
import '../screens/what_is_self_screen.dart';
import '../screens/card_screen.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWide = constraints.maxWidth >= 700;

          return SingleChildScrollView( // ✅ Scrollable root
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: isWide
                    ? _buildWideLayout(context)
                    : _buildNarrowLayout(context),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWideLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildImagePanel()),
        const SizedBox(width: 16),
        Expanded(child: _buildButtonPanel(context)),
      ],
    );
  }

  Widget _buildNarrowLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildImagePanelNarrow(context),
        const SizedBox(height: 16),
        _buildButtonPanel(context),
      ],
    );
  }

  Widget _buildImagePanel() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey, width: 2),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Manually build a 3x3 grid using Rows to ensure bounded height
          _buildImageRow(0),
          const SizedBox(height: 8),
          _buildImageRow(3),
          const SizedBox(height: 8),
          _buildImageRow(6),
        ],
      ),
    );
  }

  Widget _buildImageRow(int startIndex) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildImageCell(startIndex),
        const SizedBox(width: 8),
        _buildImageCell(startIndex + 1),
        const SizedBox(width: 8),
        _buildImageCell(startIndex + 2),
      ],
    );
  }

  Widget _buildImageCell(int index) {
    String assetPath = 'assets/landing_images/part_${(index + 1).toString().padLeft(2, '0')}.png';
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(4),
        child: Image.asset(
          assetPath,
          fit: BoxFit.contain,
          semanticLabel: 'Part illustration ${index + 1}',
        ),
      ),
    );
  }

  Widget _buildImagePanelNarrow(BuildContext context) {
    double availableWidth = MediaQuery.of(context).size.width - 32;
    double cellWidth = (availableWidth - 16) / 3;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey, width: 2),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: List.generate(9, (index) {
          String assetPath = 'assets/landing_images/part_${(index + 1).toString().padLeft(2, '0')}.png';
          return SizedBox(
            width: cellWidth,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(4),
              child: Image.asset(
                assetPath,
                fit: BoxFit.contain,
                semanticLabel: 'Part illustration ${index + 1}',
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildButtonPanel(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey, width: 2),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IFSOverviewScreen())),
            child: const Text('IFS Overview', style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WhatArePartsScreen())),
            child: const Text('What are Parts', style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WhatIsSelfScreen())),
            child: const Text('What is Self', style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CardScreen())),
            child: const Text('Let’s Explore!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}