// lib/screens/ifs_overview_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/theme_controller.dart';

class IFSOverviewScreen extends StatelessWidget {
  const IFSOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IFS Overview'),
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
            _buildSectionTitle('What Internal Family Systems (IFS) Means for You'),
            _buildParagraph(
              'Internal Family Systems sees your mind as an inner family made up of Parts and a core Self. '
              'Each Part has an important job—holding feelings, protecting you from pain, or carrying memories and beliefs shaped by your life. '
              'Some Parts step in to protect by managing emotions or avoiding discomfort; others hold the hurt we’ve pushed aside. '
              'Rather than removing or judging any Part, IFS helps those Parts relax and learn to communicate from the leadership of your Self—your calm, compassionate center. '
              'Parts often speak through the body: a tight chest, a sinking stomach, or a clenched jaw can be a Part trying to be heard. '
              'IFS invites gentle curiosity about those sensations: What is this Part trying to tell me?'
            ),
            _buildSectionTitle('What makes IFS different from many other therapies'),
            _buildBulletPoint('Consent-focused: In IFS you never force a Part to do anything. Change happens only with the Part’s willingness and the client’s permission, so pace and timing are always respected.'),
            _buildBulletPoint('Non-pathologizing: Parts are seen as trying to help, even if their strategies cause problems. IFS does not label you as “disordered”; it treats difficult feelings and behaviors as understandable parts of you rather than flaws to be fixed.'),
            _buildBulletPoint('Collaborative stance: The therapist acts as a guide, helping you access your Self and build trusting relationships with your Parts rather than directing or interpreting them for you.'),
            _buildBulletPoint('Body-aware and experiential: IFS pays attention to bodily signals as messages from Parts and uses gentle, experiential exploration rather than only talking or analyzing.'),
            _buildParagraph('That compassionate awareness shifts you from automatic reactions to kinder, clearer choices.'),
            _buildParagraph('IFS is supported by research as an effective approach for trauma recovery, anxiety, depression, and improving relationships.'),
            
            _buildSectionTitle('The 6 F’s of IFS (in order)'),
            _buildParagraph('Follow steps 1 → 6, top-to-bottom.'),
            _buildSixFsLinear(context),
            
            _buildSectionTitle('Everyday Practice'),
            _buildBulletPoint('Pause and ask: Which Part of me is speaking right now?'),
            _buildBulletPoint('Notice sensations in your body and soften around them.'),
            _buildBulletPoint('Write or draw to help Parts express themselves safely.'),
            _buildBulletPoint('Acknowledge moments of calm or curiosity — that is your Self showing up.'),
            _buildBulletPoint('If emotions feel too strong, pause. Healing happens at your system’s pace.'),
            
            _buildSectionTitle('Evidence and Helpful Resources'),
            _buildLinkText(context, 'IFS Institute – Research and Articles', 'https://ifs-institute.com/resources/research'),
            const SizedBox(height: 8),
            _buildLinkText(context, 'Foundation for Self Leadership – Empirical Evidence', 'https://foundationifs.org/research/empirical-evidence'),
            const SizedBox(height: 8),
            _buildLinkText(context, 'Richard C. Schwartz – No Bad Parts', 'https://ifs-institute.com'),
            const SizedBox(height: 8),
           _buildLinkText(context, 'Susan McConnell – Somatic Internal Family Systems', 'https://www.embodiedself.net/'),
            
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

  Widget _buildSixFsLinear(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSixFStep('1. Find', 'Identify a part of yourself that is active, which can be a feeling, thought, or behavior.'),
        _buildSixFStep('2. Focus', 'Turn your attention to that part, noticing its presence in or around your body in a curious and non-judgmental way.'),
        _buildSixFStep('3. Flesh Out', 'Explore the part in more detail. Ask questions about its characteristics, like its age, shape, energy, and the story it holds.'),
        
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade800
                  : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade700
                    : Colors.grey.shade300,
                width: 1.0,
              ),
            ),
            child: const Text(
              'Pause before moving on.\nContinue only if you notice enough Self energy — calm, curiosity, or compassion.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.0,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
        
        _buildSixFStep('4. Feel Toward', 'Check how your core Self feels toward this part. A response of curiosity, compassion, calm, connectedness, clarity, courage, creativity, or confidence indicates the Self is present.'),
        _buildSixFStep('5. Befriend', 'From this place of Self, build a trusting and compassionate relationship with the part. Validate its intentions and appreciate its efforts.'),
        _buildSixFStep('6. Fear', 'Inquire about what the part fears would happen if it stopped doing its job. This step helps understand its protective role and allows it to be relieved of its burden.'),
      ],
    );
  }

  Widget _buildSixFStep(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            description,
            style: const TextStyle(fontSize: 16.0, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkText(BuildContext context, String label, String url) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      },
      child: Text(
        label,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          decoration: TextDecoration.underline,
          fontSize: 16.0,
        ),
        textAlign: TextAlign.left,
      ),
    );
  }
}