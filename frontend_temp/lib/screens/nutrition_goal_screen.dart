import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../services/user_profile_service.dart';

class NutritionGoalScreen extends StatefulWidget {
  const NutritionGoalScreen({super.key});

  @override
  State<NutritionGoalScreen> createState() => _NutritionGoalScreenState();
}

class _NutritionGoalScreenState extends State<NutritionGoalScreen> {
  String _selectedGoal = 'Weight Loss';
  int _calorieTarget = 2000;
  double _proteinPct = 30;
  double _carbsPct = 40;
  double _fatPct = 30;
  bool _isSaving = false;

  final List<Map<String, dynamic>> _goals = [
    {'label': 'Weight Loss', 'icon': '🔥', 'calories': 1600},
    {'label': 'Muscle Gain', 'icon': '💪', 'calories': 2800},
    {'label': 'Maintenance', 'icon': '⚖️', 'calories': 2000},
    {'label': 'Improve Immunity', 'icon': '🛡️', 'calories': 2200},
    {'label': 'Better Digestion', 'icon': '🥗', 'calories': 1900},
    {'label': 'Athletic Performance', 'icon': '🏃', 'calories': 3000},
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await UserProfileService.loadGoal();
    setState(() {
      _selectedGoal = data['goal'] as String;
      _calorieTarget = data['calorieTarget'] as int;
      _proteinPct = data['proteinPct'] as double;
      _carbsPct = data['carbsPct'] as double;
      _fatPct = data['fatPct'] as double;
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    await UserProfileService.saveGoal(
      goal: _selectedGoal,
      calorieTarget: _calorieTarget,
      proteinPct: _proteinPct,
      carbsPct: _carbsPct,
      fatPct: _fatPct,
    );
    setState(() => _isSaving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Nutrition goals saved!'),
          backgroundColor: AppTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pop(context, true);
    }
  }

  void _selectGoal(Map<String, dynamic> goal) {
    setState(() {
      _selectedGoal = goal['label'] as String;
      _calorieTarget = goal['calories'] as int;
      // Adjust macros based on goal
      if (_selectedGoal == 'Weight Loss') {
        _proteinPct = 35; _carbsPct = 35; _fatPct = 30;
      } else if (_selectedGoal == 'Muscle Gain') {
        _proteinPct = 40; _carbsPct = 40; _fatPct = 20;
      } else if (_selectedGoal == 'Athletic Performance') {
        _proteinPct = 30; _carbsPct = 50; _fatPct = 20;
      } else {
        _proteinPct = 30; _carbsPct = 40; _fatPct = 30;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text('Nutrition Goals'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save',
                    style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Goal Selection
            Text('Select Your Goal',
                style: AppTheme.headlineMedium.copyWith(fontSize: 17))
                .animate().fadeIn(duration: 300.ms),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: _goals.map((goal) {
                final selected = goal['label'] == _selectedGoal;
                return GestureDetector(
                  onTap: () => _selectGoal(goal),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    decoration: BoxDecoration(
                      gradient: selected ? AppTheme.primaryGradient : null,
                      color: selected ? null : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected
                            ? Colors.transparent
                            : AppTheme.dividerColor,
                      ),
                      boxShadow: selected ? AppTheme.greenGlow : AppTheme.softShadow,
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(goal['icon'] as String,
                            style: const TextStyle(fontSize: 22)),
                        const Spacer(),
                        Text(
                          goal['label'] as String,
                          style: TextStyle(
                            color: selected ? Colors.white : AppTheme.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

            const SizedBox(height: 28),

            // Calorie Target
            Text('Daily Calorie Target',
                style: AppTheme.headlineMedium.copyWith(fontSize: 17))
                .animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.softShadow,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$_calorieTarget',
                        style: AppTheme.headlineLarge.copyWith(
                          fontSize: 40,
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('kcal/day',
                          style: AppTheme.bodySmall.copyWith(fontSize: 14)),
                    ],
                  ),
                  Slider(
                    value: _calorieTarget.toDouble(),
                    min: 1200,
                    max: 4000,
                    divisions: 56,
                    activeColor: AppTheme.primaryGreen,
                    inactiveColor: AppTheme.surfaceGreen,
                    onChanged: (v) => setState(() => _calorieTarget = v.round()),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('1200 kcal', style: AppTheme.bodySmall),
                      Text('4000 kcal', style: AppTheme.bodySmall),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 250.ms, duration: 400.ms),

            const SizedBox(height: 28),

            // Macro Split
            Text('Macro Split',
                style: AppTheme.headlineMedium.copyWith(fontSize: 17))
                .animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.softShadow,
              ),
              child: Column(
                children: [
                  _buildMacroSlider('Protein', _proteinPct, AppTheme.proteinColor,
                      (v) => setState(() => _proteinPct = v)),
                  const SizedBox(height: 16),
                  _buildMacroSlider('Carbs', _carbsPct, AppTheme.carbsColor,
                      (v) => setState(() => _carbsPct = v)),
                  const SizedBox(height: 16),
                  _buildMacroSlider('Fat', _fatPct, AppTheme.fatColor,
                      (v) => setState(() => _fatPct = v)),
                ],
              ),
            ).animate().fadeIn(delay: 350.ms, duration: 400.ms),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Save Goals',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroSlider(
      String label, double value, Color color, ValueChanged<double> onChanged) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: AppTheme.titleMedium.copyWith(fontSize: 14)),
            Text('${value.round()}%',
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            thumbColor: color,
            inactiveTrackColor: color.withOpacity(0.15),
            overlayColor: color.withOpacity(0.1),
          ),
          child: Slider(
            value: value,
            min: 10,
            max: 70,
            divisions: 60,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
