import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/recipe_model.dart';
import 'recipe_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  final String initialQuery;
  const SearchScreen({super.key, this.initialQuery = ''});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) return;
    
    // Create a mock recipe based on the search query
    final mockRecipe = RecipeResponse(
      recipeName: '${query.substring(0, 1).toUpperCase()}${query.substring(1)} Special',
      totalTime: 20,
      ingredientsUsed: [
        Ingredient(name: query, quantity: 'as needed'),
        Ingredient(name: 'Healthy Greens', quantity: '2 cups'),
        Ingredient(name: 'Olive Oil', quantity: '1 tbsp'),
      ],
      steps: [
        RecipeStep(stepNumber: 1, instruction: 'Gather all ingredients for your $query dish.'),
        RecipeStep(stepNumber: 2, instruction: 'Cook them perfectly using NutriSync AI guidance.'),
        RecipeStep(stepNumber: 3, instruction: 'Enjoy your healthy meal!'),
      ],
      nutritionFacts: NutritionFacts(
        calories: 350,
        protein: 15.0,
        carbohydrates: 40.0,
        fat: 10.0,
        fiber: 6.0,
      ),
      imageUrl: 'https://images.unsplash.com/photo-1490645935967-10de6ba17061?q=80&w=600&auto=format&fit=crop',
    );
    
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: mockRecipe)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text('Search'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.softShadow,
                border: Border.all(color: AppTheme.dividerColor.withOpacity(0.5)),
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onSubmitted: _performSearch,
                decoration: InputDecoration(
                  hintText: 'Search recipes, ingredients, or nutrients...',
                  hintStyle: AppTheme.bodyMedium.copyWith(color: AppTheme.textTertiary),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(left: 16, right: 12),
                    child: Icon(Icons.search_rounded, color: AppTheme.textTertiary, size: 22),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text('Popular Searches', style: AppTheme.titleMedium),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['High Protein', 'Keto', 'Vegan', 'Chicken', 'Under 300 kcal', 'Breakfast'].map((tag) {
                return GestureDetector(
                  onTap: () {
                    _searchController.text = tag;
                    _performSearch(tag);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(tag, style: AppTheme.bodyMedium.copyWith(color: AppTheme.primaryGreenDark)),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
