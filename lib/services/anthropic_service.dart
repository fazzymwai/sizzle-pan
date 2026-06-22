import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service for interacting with Anthropic's Claude API.
class AnthropicService {
  static const String _apiKey = String.fromEnvironment('ANTHROPIC_API_KEY');
  static const String _baseUrl = 'https://api.anthropic.com/v1/messages';
  static const String _model = 'claude-sonnet-4-20250514';

  static String? get apiKey => _apiKey.isNotEmpty ? _apiKey : null;

  /// Generate recipe suggestions from ingredients + filters.
  /// Returns raw JSON string from the API.
  static Future<String> generateRecipes({
    required List<String> ingredients,
    String? dietaryPreference,
    int? maxTime,
    String? skillLevel,
    String? cuisine,
    int? servings,
  }) async {
    final systemPrompt = '''
You are an expert chef and recipe developer. Given a list of ingredients the user has,
plus optional filters, suggest recipes they can make.

Return a JSON array of recipe objects. Each recipe object must have exactly this structure:
{
  "title": "Recipe Name",
  "description": "Short appetizing description",
  "cookingTime": 30,
  "difficulty": "Easy|Medium|Hard",
  "servings": 2,
  "category": "Pasta|Breakfast|etc",
  "ingredients": [
    {"name": "ingredient", "amount": "1 cup", "owned": true}
  ],
  "steps": ["Step 1...", "Step 2..."],
  "substitutions": {
    "ingredient_name": [{"swap": "alternative", "ratio": "same amount"}]
  },
  "dietaryInfo": ["vegan", "gluten-free"] (if applicable),
  "nutritionPerServing": {"calories": 350, "protein": "12g"} (optional)
}

Mark ingredients the user owns with "owned": true. For missing but recommended ingredients,
set "owned": false. Rank recipes by what they can make NOW vs with 1-2 extra items.
''';

    String userPrompt = 'I have these ingredients: ${ingredients.join(", ")}.';
    if (dietaryPreference != null && dietaryPreference.isNotEmpty) {
      userPrompt += '\nDietary preference: $dietaryPreference.';
    }
    if (maxTime != null) {
      userPrompt += '\nMaximum cooking time: $maxTime minutes.';
    }
    if (skillLevel != null && skillLevel.isNotEmpty) {
      userPrompt += '\nSkill level: $skillLevel.';
    }
    if (cuisine != null && cuisine.isNotEmpty) {
      userPrompt += '\nCuisine preference: $cuisine.';
    }
    if (servings != null) {
      userPrompt += '\nNumber of servings: $servings.';
    }
    userPrompt +=
        '\nSuggest up to 5 recipes. Return ONLY the JSON array, no other text.';

    return _callApi(systemPrompt, userPrompt);
  }

  /// Get cooking advice context-aware of the current recipe and step.
  static Future<String> getCookingAdvice({
    required String question,
    required String recipeTitle,
    required List<String> recipeSteps,
    required int currentStepIndex,
    required List<String> ingredients,
    List<Map<String, String>> conversationHistory = const [],
  }) async {
    final systemPrompt = '''
You are a friendly, knowledgeable sous-chef helping someone cook right now.
You know the recipe they're making and which step they're on.
Answer their question briefly and helpfully — like a real kitchen assistant.
Keep answers concise (2-3 sentences max) and encouraging.
If they ask about substitutions, give specific ratios.
If they ask about doneness tests, describe visual/tactile cues.
''';

    String historyText = '';
    for (final msg in conversationHistory) {
      historyText += '${msg["role"]}: ${msg["content"]}\n';
    }

    final currentStep = currentStepIndex < recipeSteps.length
        ? recipeSteps[currentStepIndex]
        : 'Recipe complete!';

    final userPrompt = '''
Currently cooking: $recipeTitle
Ingredients: ${ingredients.join(", ")}
Current step ($currentStepIndex): $currentStep
${historyText.isNotEmpty ? "Conversation so far:\n$historyText" : ""}
User asks: $question
''';

    return _callApi(systemPrompt, userPrompt);
  }

  /// Suggest substitutions for a missing ingredient.
  static Future<String> getSubstitutions(
      String ingredient, String recipeTitle) async {
    final systemPrompt = '''
You are a culinary science expert. Given a missing ingredient and a recipe,
suggest viable substitutions with exact ratio adjustments.
Return a JSON array of objects:
[{"swap": "alternative name", "ratio": "use X instead of Y", "notes": "any preparation tips"}]
Return ONLY the JSON array.
''';

    final userPrompt = '''
Recipe: $recipeTitle
Missing ingredient: $ingredient
Suggest up to 3 substitutions.
''';

    return _callApi(systemPrompt, userPrompt);
  }

  /// Generate a shopping list from recipe ingredients.
  static Future<String> generateShoppingList(
      List<String> allIngredients, List<String> ownedIngredients) async {
    final systemPrompt = '''
You are a meal prep assistant. Given a list of all recipe ingredients
and which ones the user already has, generate a shopping list.
Group items by aisle/category (Produce, Dairy, Meat, Pantry, Spices, etc).
Return a JSON array of objects:
[{"name": "item", "category": "Produce", "amount": "1 cup", "owned": false}]
Return ONLY the JSON array.
''';

    final userPrompt = '''
All ingredients: ${allIngredients.join(", ")}
Already owned: ${ownedIngredients.join(", ")}
Generate the shopping list with only unowned items.
''';

    return _callApi(systemPrompt, userPrompt);
  }

  static Future<String> _callApi(String systemPrompt, String userPrompt) async {
    if (_apiKey.isEmpty) {
      throw Exception(
        'Anthropic API key not set. Pass it with: --dart-define=ANTHROPIC_API_KEY=sk-ant-...',
      );
    }

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': _apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': _model,
        'max_tokens': 2048,
        'system': systemPrompt,
        'messages': [
          {'role': 'user', 'content': userPrompt},
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['content'] as List;
      if (content.isNotEmpty) {
        return content[0]['text'] as String;
      }
      throw Exception('Empty response from Anthropic API');
    } else {
      throw Exception(
        'Anthropic API error ${response.statusCode}: ${response.body}',
      );
    }
  }
}
