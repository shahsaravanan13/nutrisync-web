import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../services/user_profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import 'edit_profile_screen.dart';
import 'nutrition_goal_screen.dart';
import 'recipe_history_screen.dart';
import 'help_support_screen.dart';
import 'privacy_policy_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  String _reminderTime = '08:00 AM';

  // Profile data
  String _name = 'Your Name';
  String _bio = 'Nutrition Enthusiast';
  String _dietTag = 'Healthy Eater';
  String _selectedGoal = 'Weight Loss';

  // Stats
  int _recipesGenerated = 0;
  int _savedRecipes = 0;
  int _daysActive = 0;
  int _calorieTarget = 2000;

  @override
  void initState() {
    super.initState();
    _darkModeEnabled = themeNotifier.value == ThemeMode.dark;
    _loadAll();
  }

  Future<void> _loadAll() async {
    final profile = await UserProfileService.loadProfile();
    final goal = await UserProfileService.loadGoal();
    final notifs = await UserProfileService.getNotifications();
    final reminder = await UserProfileService.getReminderTime();
    final historyCount = await UserProfileService.getHistoryCount();
    final daysActive = await UserProfileService.getDaysActive();
    final prefs = await SharedPreferences.getInstance();
    final savedRecipesList = prefs.getStringList('saved_recipes') ?? [];

    setState(() {
      _name = profile['name'] ?? 'Your Name';
      _bio = profile['bio'] ?? 'Nutrition Enthusiast';
      _dietTag = profile['dietTag'] ?? 'Healthy Eater';
      _selectedGoal = goal['goal'] as String? ?? 'Weight Loss';
      _calorieTarget = goal['calorieTarget'] as int? ?? 2000;
      _notificationsEnabled = notifs;
      _reminderTime = reminder;
      _recipesGenerated = historyCount;
      _daysActive = daysActive;
      _savedRecipes = savedRecipesList.length;
    });
  }

  List<Map<String, dynamic>> get _stats => [
    {'label': 'Recipes\nGenerated', 'value': '$_recipesGenerated', 'icon': Icons.restaurant_menu_rounded},
    {'label': 'Saved\nRecipes', 'value': '$_savedRecipes', 'icon': Icons.bookmark_rounded},
    {'label': 'Days\nActive', 'value': '$_daysActive', 'icon': Icons.calendar_today_rounded},
    {'label': 'Calorie\nTarget', 'value': '$_calorieTarget', 'icon': Icons.local_fire_department_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1A1D27) : Colors.white;
    final bgColor = isDark ? const Color(0xFF0F1117) : AppTheme.backgroundWhite;

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ─── Header ─────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryGreenDark,
                    AppTheme.primaryGreen,
                    AppTheme.accentTeal,
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Stack(
                  children: [
                    Positioned(right: -40, top: -20,
                      child: Container(width: 180, height: 180,
                        decoration: BoxDecoration(shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05)))),
                    Positioned(left: -30, bottom: -20,
                      child: Container(width: 120, height: 120,
                        decoration: BoxDecoration(shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05)))),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(children: [
                                Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(14)),
                                  child: const Icon(Icons.restaurant_menu_rounded,
                                      color: Colors.white, size: 20)),
                                const SizedBox(width: 10),
                                Text('NutriSync',
                                    style: AppTheme.headlineMedium.copyWith(
                                        color: Colors.white, fontWeight: FontWeight.w800)),
                              ]),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(14)),
                                child: IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.white),
                                  onPressed: _navigateToEditProfile,
                                  tooltip: 'Edit Profile',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          // Avatar with initials
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                width: 88, height: 88,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(colors: [
                                    Colors.white.withOpacity(0.3),
                                    Colors.white.withOpacity(0.1),
                                  ]),
                                  border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                                ),
                                child: Center(
                                  child: Text(
                                    _name.isNotEmpty ? _name[0].toUpperCase() : '?',
                                    style: const TextStyle(
                                        fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white),
                                  ),
                                ),
                              ).animate().scale(begin: const Offset(0.5, 0.5),
                                  end: const Offset(1.0, 1.0), duration: 600.ms, curve: Curves.elasticOut),
                              GestureDetector(
                                onTap: _navigateToEditProfile,
                                child: Container(
                                  width: 28, height: 28,
                                  decoration: BoxDecoration(color: Colors.white,
                                      shape: BoxShape.circle, boxShadow: AppTheme.softShadow),
                                  child: const Icon(Icons.edit_rounded, size: 14, color: AppTheme.primaryGreen),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(_name,
                              style: AppTheme.headlineLarge.copyWith(
                                  color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22))
                              .animate().fadeIn(delay: 200.ms, duration: 400.ms),
                          const SizedBox(height: 4),
                          Text('$_bio • $_dietTag',
                              style: AppTheme.bodySmall.copyWith(
                                  color: Colors.white.withOpacity(0.75), fontSize: 12),
                              textAlign: TextAlign.center,
                              maxLines: 1, overflow: TextOverflow.ellipsis)
                              .animate().fadeIn(delay: 300.ms, duration: 400.ms),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ─── Stats ───────────────────────────────────────
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: AppTheme.mediumShadow,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: _stats.asMap().entries.map((e) =>
                        Expanded(child: _buildStatItem(e.value, e.key))).toList(),
                  ),
                ),
              ),
            ),
          ),

          // ─── Body ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),

                  // Goal
                  _buildSectionTitle('Nutrition Goal'),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _navigateToNutritionGoal,
                    child: _buildGoalCard(cardColor),
                  ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

                  const SizedBox(height: 28),

                  // Preferences
                  _buildSectionTitle('Preferences'),
                  const SizedBox(height: 12),
                  _buildSettingsCard(cardColor)
                      .animate().fadeIn(delay: 400.ms, duration: 400.ms),

                  const SizedBox(height: 28),

                  // Account
                  _buildSectionTitle('Account'),
                  const SizedBox(height: 12),
                  _buildMenuCard(cardColor)
                      .animate().fadeIn(delay: 500.ms, duration: 400.ms),

                  const SizedBox(height: 20),

                  // Logout placeholder
                  GestureDetector(
                    onTap: () => _showLogoutDialog(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.errorRed.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.errorRed.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.logout_rounded, color: AppTheme.errorRed, size: 20),
                          const SizedBox(width: 8),
                          Text('Log Out',
                              style: AppTheme.titleMedium.copyWith(
                                  color: AppTheme.errorRed, fontWeight: FontWeight.w600, fontSize: 15)),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 600.ms, duration: 400.ms),

                  const SizedBox(height: 16),
                  Center(
                    child: Text('NutriSync v1.0.0 • AI Powered',
                        style: AppTheme.bodySmall.copyWith(fontSize: 11)),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Navigation helpers ───────────────────────────────────────────
  Future<void> _navigateToEditProfile() async {
    final result = await Navigator.push(context,
        MaterialPageRoute(builder: (_) => const EditProfileScreen()));
    if (result == true) _loadAll();
  }

  Future<void> _navigateToNutritionGoal() async {
    final result = await Navigator.push(context,
        MaterialPageRoute(builder: (_) => const NutritionGoalScreen()));
    if (result == true) _loadAll();
  }

  // ── Widgets ──────────────────────────────────────────────────────
  Widget _buildSectionTitle(String title) =>
      Text(title, style: AppTheme.headlineLarge.copyWith(fontSize: 18))
          .animate().fadeIn(duration: 400.ms);

  Widget _buildStatItem(Map<String, dynamic> stat, int index) {
    return Column(
      children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
              color: AppTheme.surfaceGreen, borderRadius: BorderRadius.circular(14)),
          child: Icon(stat['icon'] as IconData, color: AppTheme.primaryGreen, size: 22),
        ).animate().scale(begin: const Offset(0.5, 0.5), end: const Offset(1.0, 1.0),
            delay: (100 * index).ms + 400.ms, duration: 400.ms, curve: Curves.elasticOut),
        const SizedBox(height: 8),
        Text(stat['value'] as String,
            style: AppTheme.headlineMedium.copyWith(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(stat['label'] as String,
            style: AppTheme.bodySmall.copyWith(fontSize: 10), textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildGoalCard(Color cardColor) {
    final goals = ['Weight Loss', 'Muscle Gain', 'Maintenance', 'Improve Immunity', 'Better Digestion', 'Athletic Performance'];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardColor,
          borderRadius: BorderRadius.circular(20), boxShadow: AppTheme.softShadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Current Goal',
                  style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.primaryGreen, fontWeight: FontWeight.w700,
                      fontSize: 11, letterSpacing: 1)),
              Text('Tap to change →',
                  style: AppTheme.bodySmall.copyWith(fontSize: 11)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: goals.map((goal) {
              final selected = goal == _selectedGoal;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  gradient: selected ? AppTheme.primaryGradient : null,
                  color: selected ? null : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: selected ? AppTheme.greenGlow : [],
                ),
                child: Text(goal,
                    style: AppTheme.bodySmall.copyWith(
                        color: selected ? Colors.white : AppTheme.textSecondary,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 13)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(Color cardColor) {
    return Container(
      decoration: BoxDecoration(color: cardColor,
          borderRadius: BorderRadius.circular(20), boxShadow: AppTheme.softShadow),
      child: Column(
        children: [
          _buildToggleTile(
            icon: Icons.notifications_outlined,
            label: 'Push Notifications',
            subtitle: 'Daily meal reminders',
            value: _notificationsEnabled,
            onChanged: (val) async {
              setState(() => _notificationsEnabled = val);
              await UserProfileService.setNotifications(val);
            },
          ),
          Divider(height: 1, color: AppTheme.dividerColor.withOpacity(0.5)),
          _buildToggleTile(
            icon: Icons.dark_mode_outlined,
            label: 'Dark Mode',
            subtitle: 'Enable dark theme',
            value: _darkModeEnabled,
            onChanged: (val) async {
              setState(() => _darkModeEnabled = val);
              themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
              await UserProfileService.setDarkMode(val);
            },
          ),
          Divider(height: 1, color: AppTheme.dividerColor.withOpacity(0.5)),
          _buildReminderTile(),
        ],
      ),
    );
  }

  Widget _buildReminderTile() {
    return InkWell(
      onTap: _pickReminderTime,
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                  color: AppTheme.surfaceGreen, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.alarm_outlined, color: AppTheme.primaryGreen, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Daily Reminder', style: AppTheme.titleMedium.copyWith(fontSize: 14)),
                const SizedBox(height: 2),
                Text('Tap to set time', style: AppTheme.bodySmall.copyWith(fontSize: 12)),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.surfaceGreen, borderRadius: BorderRadius.circular(10)),
              child: Text(_reminderTime,
                  style: const TextStyle(
                      color: AppTheme.primaryGreen, fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickReminderTime() async {
    final parts = _reminderTime.split(RegExp(r'[: ]'));
    var hour = int.tryParse(parts[0]) ?? 8;
    final minute = int.tryParse(parts[1]) ?? 0;
    final isPm = parts.length > 2 && parts[2] == 'PM';
    if (isPm && hour != 12) hour += 12;
    if (!isPm && hour == 12) hour = 0;

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour, minute: minute),
    );
    if (picked != null) {
      final formatted = picked.format(context);
      setState(() => _reminderTime = formatted);
      await UserProfileService.setReminderTime(formatted);
    }
  }

  Widget _buildToggleTile({
    required IconData icon, required String label,
    required String subtitle, required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
              color: AppTheme.surfaceGreen, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: AppTheme.primaryGreen, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: AppTheme.titleMedium.copyWith(fontSize: 14)),
          const SizedBox(height: 2),
          Text(subtitle, style: AppTheme.bodySmall.copyWith(fontSize: 12)),
        ])),
        Switch.adaptive(value: value, onChanged: onChanged, activeColor: AppTheme.primaryGreen),
      ]),
    );
  }

  Widget _buildMenuCard(Color cardColor) {
    final items = [
      {'icon': Icons.person_outline_rounded, 'label': 'Edit Profile', 'color': AppTheme.primaryGreen, 'action': 'edit_profile'},
      {'icon': Icons.fitness_center_rounded, 'label': 'Nutrition Goals', 'color': AppTheme.infoBlue, 'action': 'nutrition_goal'},
      {'icon': Icons.history_rounded, 'label': 'Recipe History', 'color': AppTheme.warningAmber, 'action': 'recipe_history'},
      {'icon': Icons.share_rounded, 'label': 'Share NutriSync', 'color': AppTheme.accentTeal, 'action': 'share'},
      {'icon': Icons.star_outline_rounded, 'label': 'Rate the App', 'color': AppTheme.carbsColor, 'action': 'rate'},
      {'icon': Icons.help_outline_rounded, 'label': 'Help & Support', 'color': AppTheme.textSecondary, 'action': 'help'},
      {'icon': Icons.privacy_tip_outlined, 'label': 'Privacy Policy', 'color': AppTheme.textSecondary, 'action': 'privacy'},
    ];

    return Container(
      decoration: BoxDecoration(color: cardColor,
          borderRadius: BorderRadius.circular(20), boxShadow: AppTheme.softShadow),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final isLast = i == items.length - 1;
          return Column(children: [
            InkWell(
              onTap: () => _handleMenuAction(item['action'] as String),
              borderRadius: BorderRadius.only(
                topLeft: i == 0 ? const Radius.circular(20) : Radius.zero,
                topRight: i == 0 ? const Radius.circular(20) : Radius.zero,
                bottomLeft: isLast ? const Radius.circular(20) : Radius.zero,
                bottomRight: isLast ? const Radius.circular(20) : Radius.zero,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: (item['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12)),
                    child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Text(item['label'] as String,
                      style: AppTheme.titleMedium.copyWith(fontSize: 14))),
                  const Icon(Icons.chevron_right_rounded, color: AppTheme.textTertiary, size: 22),
                ]),
              ),
            ),
            if (!isLast) Divider(height: 1, indent: 70, color: AppTheme.dividerColor.withOpacity(0.5)),
          ]);
        }).toList(),
      ),
    );
  }

  Future<void> _handleMenuAction(String action) async {
    switch (action) {
      case 'edit_profile':
        _navigateToEditProfile();
        break;
      case 'nutrition_goal':
        _navigateToNutritionGoal();
        break;
      case 'recipe_history':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const RecipeHistoryScreen()));
        break;
      case 'share':
        await Share.share(
          '🥗 Check out NutriSync — the AI-powered recipe & nutrition app!\n\nGenerate personalized recipes from your ingredients with accurate nutrition info.\n\nhttps://nutrisync-project-production.up.railway.app',
          subject: 'NutriSync - AI Recipe App',
        );
        break;
      case 'rate':
        final uri = Uri.parse('https://apps.apple.com/app/id6745788887');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
        break;
      case 'help':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen()));
        break;
      case 'privacy':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()));
        break;
    }
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log Out?'),
        content: const Text('Are you sure you want to log out?\nYour data will remain on this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Clear auth state
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isLoggedIn', false);

              if (!ctx.mounted) return;
              Navigator.pop(ctx); // close dialog
              
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: Text('Log Out',
                style: TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
