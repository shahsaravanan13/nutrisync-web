import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../models/recipe_model.dart';
import 'recipe_detail_screen.dart';

class RecommendedRecipesScreen extends StatelessWidget {
  const RecommendedRecipesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> allRecipes = [
      {
        'name': 'Asian Noodle Bowl',
        'cal': '380 kcal',
        'time': '15 min',
        'color': const Color(0xFF4A7C59),
        'image': 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?q=80&w=600&auto=format&fit=crop',
      },
      {
        'name': 'Lentil Curry Soup',
        'cal': '290 kcal',
        'time': '25 min',
        'color': const Color(0xFFB8860B),
        'image': 'https://images.unsplash.com/photo-1548943487-a2e4f43b4859?q=80&w=600&auto=format&fit=crop',
      },
      {
        'name': 'Grilled Chicken Wrap',
        'cal': '420 kcal',
        'time': '12 min',
        'color': const Color(0xFF8B4513),
        'image': 'https://images.unsplash.com/photo-1626700051175-6818013e1d4f?q=80&w=600&auto=format&fit=crop',
      },
      {
        'name': 'Veggie Stir Fry',
        'cal': '310 kcal',
        'time': '18 min',
        'color': const Color(0xFF2E8B57),
        'image': 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?q=80&w=600&auto=format&fit=crop',
      },
      {
        'name': 'Avocado Toast',
        'cal': '250 kcal',
        'time': '5 min',
        'color': const Color(0xFF43A047),
        'image': 'https://images.unsplash.com/photo-1541519227354-08fa5d50c44d?q=80&w=600&auto=format&fit=crop',
      },
      {
        'name': 'Berry Smoothie Bowl',
        'cal': '210 kcal',
        'time': '10 min',
        'color': const Color(0xFF8E24AA),
        'image': 'https://images.unsplash.com/photo-1494597564530-871f2b93ac55?q=80&w=600&auto=format&fit=crop',
      },
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text('Recommended for you'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        itemCount: allRecipes.length,
        itemBuilder: (context, index) {
          final recipe = allRecipes[index];
          return _buildRecipeCard(context, recipe, index);
        },
      ),
    );
  }

  Widget _buildRecipeCard(BuildContext context, Map<String, dynamic> recipe, int index) {
    return GestureDetector(
      onTap: () {
        // Open mock detail
        final mockRecipe = RecipeResponse(
          recipeName: recipe['name'] as String,
          totalTime: int.tryParse((recipe['time'] as String).replaceAll(RegExp(r'[^0-9]'), '')) ?? 15,
          ingredientsUsed: [
            Ingredient(name: 'Main Ingredient', quantity: '200g'),
            Ingredient(name: 'Vegetables', quantity: '1 cup'),
            Ingredient(name: 'Spices', quantity: '1 tbsp'),
          ],
          steps: [
            RecipeStep(stepNumber: 1, instruction: 'Prepare the ingredients by washing and chopping them.'),
            RecipeStep(stepNumber: 2, instruction: 'Cook the main ingredient in a pan with some oil.'),
            RecipeStep(stepNumber: 3, instruction: 'Add vegetables and spices, cook until tender.'),
            RecipeStep(stepNumber: 4, instruction: 'Serve hot and enjoy your healthy meal!'),
          ],
          nutritionFacts: NutritionFacts(
            calories: double.tryParse((recipe['cal'] as String).replaceAll(RegExp(r'[^0-9.]'), '')) ?? 300,
            protein: 20.0,
            carbohydrates: 30.0,
            fat: 12.0,
            fiber: 5.0,
          ),
          imageUrl: recipe['image'] as String,
        );
        Navigator.push(context, MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: mockRecipe)));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with rounded top corners
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.network(
                  recipe['image'] as String,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: (recipe['color'] as Color).withOpacity(0.3),
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          (recipe['color'] as Color).withOpacity(0.8),
                          (recipe['color'] as Color),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Icon(Icons.restaurant_rounded, size: 40, color: Colors.white.withOpacity(0.7)),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      recipe['name'] as String,
                      style: AppTheme.titleMedium.copyWith(fontSize: 13, height: 1.2),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Icon(Icons.local_fire_department_rounded, size: 14, color: AppTheme.calorieColor),
                        const SizedBox(width: 4),
                        Text(recipe['cal'] as String, style: AppTheme.bodySmall.copyWith(fontSize: 11)),
                        const Spacer(),
                        Icon(Icons.schedule_rounded, size: 14, color: AppTheme.textTertiary),
                        const SizedBox(width: 4),
                        Text(recipe['time'] as String, style: AppTheme.bodySmall.copyWith(fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: (50 * index).ms, duration: 400.ms).slideY(begin: 0.1, end: 0),
    );
  }
}
