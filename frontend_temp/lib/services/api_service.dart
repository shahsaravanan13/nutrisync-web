import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/recipe_model.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  int _demoChatIdx = 0;
  final List<String> _demoChatReplies = [
    'For balanced nutrition, aim for half your plate as vegetables, a quarter lean protein, and a quarter whole grains.',
    'Getting 25-30g of protein per meal supports muscle health and keeps you full longer.',
    'Hydration matters - try to drink 8 glasses of water daily, more if you exercise.',
    'Meal prepping on Sundays saves time and makes healthy eating much easier during the week!',
    'Whole, minimally processed foods are always your best choice for long-term health.',
    'A moderate calorie deficit of 300-500 kcal per day is safe and sustainable for weight loss.',
    'High-fibre foods like legumes, oats, and vegetables help you stay full and support gut health.',
  ];

  RecipeResponse _generateDemoRecipe(List<String> ingredients) {
    final first = ingredients.isNotEmpty ? ingredients.first : 'Mixed';
    final all = ingredients.join(', ');
    
    return RecipeResponse(
      recipeName: "Chef's ${first[0].toUpperCase()}${first.substring(1)} Special",
      totalTime: 20,
      ingredientsUsed: ingredients.asMap().entries.map((entry) {
        return Ingredient(
          name: entry.value,
          quantity: entry.key == 0 ? '200g' : (entry.key == 1 ? '1 cup' : '2 tbsp'),
        );
      }).toList(),
      steps: [
        RecipeStep(stepNumber: 1, instruction: 'Prepare all ingredients: $all. Wash, peel, and chop as needed.'),
        RecipeStep(stepNumber: 2, instruction: 'Heat oil in a pan over medium heat. Add $first and cook for 4 minutes.'),
        RecipeStep(stepNumber: 3, instruction: 'Add remaining ingredients, stir well and cook for 8-10 more minutes.'),
        RecipeStep(stepNumber: 4, instruction: 'Season with salt and pepper. Plate elegantly and serve warm.'),
      ],
      nutritionFacts: NutritionFacts(
        calories: 360.0 + ingredients.length * 20.0,
        protein: 22.0,
        carbohydrates: 34.0,
        fat: 11.0,
        fiber: 5.0,
      ),
      imageUrl: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800&auto=format',
    );
  }

  /// Check if the backend is reachable
  Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.healthCheck}'),
            headers: ApiConfig.headers,
          )
          .timeout(const Duration(seconds: 4));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Generate a recipe from the given ingredients
  Future<RecipeResponse> generateRecipe(RecipeRequest request) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.generateRecipe}');

      final response = await http
          .post(
            uri,
            headers: ApiConfig.headers,
            body: jsonEncode(request.toJson()),
          )
          .timeout(ApiConfig.timeoutDuration);

      if (response.statusCode == 200) {
        final body = response.body.trim();
        final jsonData = jsonDecode(body);
        return RecipeResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to generate recipe (${response.statusCode})');
      }
    } catch (e) {
      print('Backend error: $e. Falling back to demo mode.');
      return _generateDemoRecipe(request.ingredients);
    }
  }

  /// Send a message to the AI Chatbot
  Future<String> sendChatMessage(String message, List<Map<String, String>> history) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.chatBot}');
      
      final requestBody = {
        'message': message,
        'history': history,
      };

      final response = await http
          .post(
            uri,
            headers: ApiConfig.headers,
            body: jsonEncode(requestBody),
          )
          .timeout(ApiConfig.timeoutDuration);

      if (response.statusCode == 200) {
        final body = response.body.trim();
        final jsonData = jsonDecode(body);
        return jsonData['response'] as String;
      } else {
        throw Exception('Chat failed (${response.statusCode})');
      }
    } catch (e) {
      print('Chat error: $e. Falling back to demo response.');
      await Future.delayed(const Duration(seconds: 1));
      final reply = _demoChatReplies[_demoChatIdx % _demoChatReplies.length];
      _demoChatIdx++;
      return '$reply\n\n_(Backend offline — showing demo response)_';
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException({required this.message, required this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}
