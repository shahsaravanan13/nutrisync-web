import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfileService {
  static const _keyName = 'profile_name';
  static const _keyBio = 'profile_bio';
  static const _keyDietTag = 'profile_diet_tag';
  static const _keyGoal = 'profile_goal';
  static const _keyCalorieTarget = 'profile_calorie_target';
  static const _keyProteinPct = 'profile_protein_pct';
  static const _keyCarbsPct = 'profile_carbs_pct';
  static const _keyFatPct = 'profile_fat_pct';
  static const _keyDarkMode = 'pref_dark_mode';
  static const _keyNotifications = 'pref_notifications';
  static const _keyReminderTime = 'pref_reminder_time';
  static const _keyHistory = 'recipe_history';
  static const _keyDaysActive = 'days_active';
  static const _keyLastActive = 'last_active_date';

  // ── Profile ───────────────────────────────────────────────────────
  static Future<Map<String, String>> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString(_keyName) ?? 'Your Name',
      'bio': prefs.getString(_keyBio) ?? 'Nutrition Enthusiast',
      'dietTag': prefs.getString(_keyDietTag) ?? 'Healthy Eater',
    };
  }

  static Future<void> saveProfile({
    required String name,
    required String bio,
    required String dietTag,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, name);
    await prefs.setString(_keyBio, bio);
    await prefs.setString(_keyDietTag, dietTag);
  }

  // ── Nutrition Goal ────────────────────────────────────────────────
  static Future<Map<String, dynamic>> loadGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'goal': prefs.getString(_keyGoal) ?? 'Weight Loss',
      'calorieTarget': prefs.getInt(_keyCalorieTarget) ?? 2000,
      'proteinPct': prefs.getDouble(_keyProteinPct) ?? 30.0,
      'carbsPct': prefs.getDouble(_keyCarbsPct) ?? 40.0,
      'fatPct': prefs.getDouble(_keyFatPct) ?? 30.0,
    };
  }

  static Future<void> saveGoal({
    required String goal,
    required int calorieTarget,
    required double proteinPct,
    required double carbsPct,
    required double fatPct,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyGoal, goal);
    await prefs.setInt(_keyCalorieTarget, calorieTarget);
    await prefs.setDouble(_keyProteinPct, proteinPct);
    await prefs.setDouble(_keyCarbsPct, carbsPct);
    await prefs.setDouble(_keyFatPct, fatPct);
  }

  // ── Preferences ───────────────────────────────────────────────────
  static Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDarkMode) ?? false;
  }

  static Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, value);
  }

  static Future<bool> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNotifications) ?? true;
  }

  static Future<void> setNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotifications, value);
  }

  static Future<String> getReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyReminderTime) ?? '08:00 AM';
  }

  static Future<void> setReminderTime(String time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyReminderTime, time);
  }

  // ── Recipe History ────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_keyHistory) ?? [];
    return raw
        .map((e) => Map<String, dynamic>.from(jsonDecode(e) as Map))
        .toList()
        .reversed
        .toList();
  }

  static Future<void> addToHistory({
    required String recipeName,
    required int calories,
    required int protein,
    required int carbs,
    required int fat,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_keyHistory) ?? [];
    final entry = jsonEncode({
      'name': recipeName,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'date': DateTime.now().toIso8601String(),
    });
    raw.add(entry);
    // Keep last 100 entries
    if (raw.length > 100) raw.removeAt(0);
    await prefs.setStringList(_keyHistory, raw);
    await _updateDaysActive(prefs);
  }

  static Future<void> deleteHistoryEntry(int reversedIndex, List<Map<String, dynamic>> currentHistory) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_keyHistory) ?? [];
    // currentHistory is reversed, so map back to original index
    final originalIndex = raw.length - 1 - reversedIndex;
    if (originalIndex >= 0 && originalIndex < raw.length) {
      raw.removeAt(originalIndex);
      await prefs.setStringList(_keyHistory, raw);
    }
  }

  static Future<int> getHistoryCount() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_keyHistory) ?? []).length;
  }

  // ── Days Active ───────────────────────────────────────────────────
  static Future<void> _updateDaysActive(SharedPreferences prefs) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastActive = prefs.getString(_keyLastActive) ?? '';
    if (lastActive != today) {
      final days = (prefs.getInt(_keyDaysActive) ?? 0) + 1;
      await prefs.setInt(_keyDaysActive, days);
      await prefs.setString(_keyLastActive, today);
    }
  }

  static Future<int> getDaysActive() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyDaysActive) ?? 0;
  }
}
