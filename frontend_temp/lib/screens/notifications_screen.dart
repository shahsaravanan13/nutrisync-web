import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> mockNotifications = [
      {
        'title': 'Daily Reminder',
        'body': 'Don\'t forget to log your breakfast! It is the most important meal of the day.',
        'time': '10 mins ago',
        'icon': Icons.wb_sunny_rounded,
        'color': AppTheme.warningAmber,
        'isNew': true,
      },
      {
        'title': 'New Feature Available',
        'body': 'NutriBot is now live! Chat with your personal AI nutritionist directly from the home screen.',
        'time': '2 hours ago',
        'icon': Icons.auto_awesome_rounded,
        'color': AppTheme.primaryGreen,
        'isNew': true,
      },
      {
        'title': 'Goal Reached!',
        'body': 'You hit your protein goal for the day yesterday. Keep up the great work!',
        'time': 'Yesterday',
        'icon': Icons.emoji_events_rounded,
        'color': const Color(0xFFE91E63),
        'isNew': false,
      },
      {
        'title': 'Recipe Recommendation',
        'body': 'Based on your saved recipes, we think you\'ll love our High-Protein Avocado Toast.',
        'time': '2 days ago',
        'icon': Icons.restaurant_rounded,
        'color': AppTheme.accentTeal,
        'isNew': false,
      },
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: mockNotifications.length,
        itemBuilder: (context, index) {
          final notif = mockNotifications[index];
          return _buildNotificationCard(notif, index);
        },
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notif, int index) {
    final bool isNew = notif['isNew'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isNew ? Colors.white : AppTheme.backgroundWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isNew ? AppTheme.softShadow : null,
        border: isNew ? null : Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (notif['color'] as Color).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(notif['icon'] as IconData, color: notif['color'] as Color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        notif['title'] as String,
                        style: AppTheme.titleMedium.copyWith(fontSize: 15),
                      ),
                    ),
                    if (isNew)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  notif['body'] as String,
                  style: AppTheme.bodyMedium.copyWith(height: 1.4, color: isNew ? AppTheme.textSecondary : AppTheme.textTertiary),
                ),
                const SizedBox(height: 10),
                Text(
                  notif['time'] as String,
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.textTertiary, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (50 * index).ms).slideY(begin: 0.1, end: 0);
  }
}
