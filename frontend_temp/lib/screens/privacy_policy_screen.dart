import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Privacy Policy',
              style: AppTheme.headlineLarge.copyWith(fontSize: 24)),
          const SizedBox(height: 4),
          Text('Last updated: May 2025',
              style: AppTheme.bodySmall.copyWith(fontSize: 12)),
          const SizedBox(height: 24),
          _section(
            '1. Information We Collect',
            'NutriSync collects minimal data to provide you with the best experience. We collect:\n\n• Ingredients you enter for recipe generation\n• Profile information you voluntarily provide (name, bio, goals)\n• App usage statistics (recipes generated, days active)\n\nAll personal profile data is stored locally on your device and is never transmitted to our servers.',
          ),
          _section(
            '2. How We Use Your Information',
            'Your data is used solely to:\n\n• Generate personalized recipes using AI\n• Display your nutrition goals and progress\n• Improve the app experience\n\nIngredient data is sent to our backend server only during recipe generation and is not stored permanently.',
          ),
          _section(
            '3. Data Storage',
            'Your profile, nutrition goals, and recipe history are stored exclusively on your device using local storage (SharedPreferences). We do not maintain a user database or cloud backup of your personal information.',
          ),
          _section(
            '4. Third-Party Services',
            'NutriSync uses the following third-party services:\n\n• Groq AI — for recipe text generation (groq.com/privacy)\n• Railway.app — for backend hosting\n• Pollinations AI — for recipe image generation\n• Google Fonts — for typography\n\nEach service has its own privacy policy. We recommend reviewing them.',
          ),
          _section(
            '5. Data Security',
            'We take data security seriously. All communication between the app and our backend is encrypted using HTTPS/TLS. No payment information is collected or stored.',
          ),
          _section(
            '6. Children\'s Privacy',
            'NutriSync is not intended for use by children under 13 years of age. We do not knowingly collect personal information from children under 13.',
          ),
          _section(
            '7. Your Rights',
            'You have the right to:\n\n• Delete your local data at any time by clearing app data\n• Opt out of any future data collection\n• Request information about what data we have\n\nTo exercise these rights, contact us at support@nutrisync.app',
          ),
          _section(
            '8. Changes to This Policy',
            'We may update this Privacy Policy from time to time. We will notify you of any significant changes through the app. Continued use of NutriSync after changes constitutes acceptance of the updated policy.',
          ),
          _section(
            '9. Contact Us',
            'If you have questions about this Privacy Policy, please contact us at:\n\nEmail: support@nutrisync.app\n\nWe are committed to resolving any privacy concerns promptly.',
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppTheme.titleMedium.copyWith(
                  color: AppTheme.primaryGreen, fontSize: 15)),
          const SizedBox(height: 8),
          Text(body,
              style: AppTheme.bodyMedium.copyWith(fontSize: 13, height: 1.7)),
        ],
      ),
    );
  }
}
