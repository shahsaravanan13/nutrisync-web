import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const List<Map<String, String>> _faqs = [
    {
      'q': 'How does recipe generation work?',
      'a': 'NutriSync uses Groq AI (powered by Llama 3.3) to generate authentic recipes from your ingredients. Just type what you have and tap Generate!',
    },
    {
      'q': 'Are the nutrition values accurate?',
      'a': 'Yes! Nutrition values are calculated using a built-in USDA-based database. We calculate macros mathematically based on the exact quantities you provide.',
    },
    {
      'q': 'Why do I keep getting different recipes for the same ingredients?',
      'a': 'NutriSync tracks your recipe history and avoids repeating the same dish. This ensures you get variety every time!',
    },
    {
      'q': 'Can I use this app offline?',
      'a': 'The recipe generation feature requires an internet connection to reach the AI backend. Your profile, goals, and history are stored locally and work offline.',
    },
    {
      'q': 'How do I set dietary preferences?',
      'a': 'Go to Edit Profile and select your Diet Style. You can also type dietary preferences (e.g. "Vegan, gluten-free") when generating a recipe.',
    },
    {
      'q': 'How do I change my nutrition goals?',
      'a': 'Tap "Nutrition Goals" in the Profile screen. You can set your goal type, daily calorie target, and macro split (protein/carbs/fat).',
    },
    {
      'q': 'My recipe generation is slow — why?',
      'a': 'The AI backend is hosted on Railway\'s free tier which may have occasional cold starts. The first request of the day may take 10-20 seconds.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Text('🤝', style: TextStyle(fontSize: 36)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('We\'re here to help!',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('Find answers to common questions below.',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0),

          Text('Frequently Asked Questions',
              style: AppTheme.headlineMedium.copyWith(fontSize: 16))
              .animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 12),

          // FAQs
          ...List.generate(_faqs.length, (i) {
            final faq = _faqs[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppTheme.softShadow,
              ),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                iconColor: AppTheme.primaryGreen,
                collapsedIconColor: AppTheme.textTertiary,
                title: Text(faq['q']!,
                    style: AppTheme.titleMedium.copyWith(fontSize: 14)),
                children: [
                  Text(faq['a']!,
                      style: AppTheme.bodyMedium.copyWith(
                          fontSize: 13, height: 1.6)),
                ],
              ),
            ).animate().fadeIn(delay: ((i + 2) * 60).ms, duration: 300.ms);
          }),

          const SizedBox(height: 24),

          // Contact
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Still need help?',
                    style: AppTheme.titleMedium.copyWith(fontSize: 15)),
                const SizedBox(height: 4),
                Text('Send us an email and we\'ll get back to you.',
                    style: AppTheme.bodySmall.copyWith(fontSize: 12)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.email_outlined, size: 18),
                    label: const Text('Contact Support'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryGreen,
                      side: const BorderSide(color: AppTheme.primaryGreen),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final uri = Uri(
                        scheme: 'mailto',
                        path: 'support@nutrisync.app',
                        query: 'subject=NutriSync Support Request',
                      );
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 500.ms, duration: 300.ms),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
