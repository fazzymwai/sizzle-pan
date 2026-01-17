import 'package:sizzle_pan/models/recipe.dart';

class AIService {
  // Template-based recipe generation for free AI functionality
  
  static List<Recipe> generateRecipesFromIngredients(List<String> ingredients) {
    final recipes = <Recipe>[];
    final ingredientSet = ingredients.map((e) => e.toLowerCase()).toSet();
    
    // Pasta recipes
    if (ingredientSet.contains('pasta') || ingredientSet.contains('spaghetti')) {
      if (ingredientSet.contains('tomato') || ingredientSet.contains('tomatoes')) {
        recipes.add(_createPastaRecipe('Simple Tomato Pasta', ingredients));
      }
      if (ingredientSet.contains('garlic')) {
        recipes.add(_createPastaRecipe('Garlic Pasta', ingredients));
      }
      if (ingredientSet.contains('cheese')) {
        recipes.add(_createPastaRecipe('Cheesy Pasta', ingredients));
      }
    }
    
    // Egg recipes
    if (ingredientSet.contains('eggs') || ingredientSet.contains('egg')) {
      if (ingredientSet.contains('bread')) {
        recipes.add(_createEggRecipe('French Toast', ingredients));
      }
      if (ingredientSet.contains('rice')) {
        recipes.add(_createEggRecipe('Fried Rice', ingredients));
      }
      recipes.add(_createEggRecipe('Scrambled Eggs', ingredients));
    }
    
    // Rice recipes
    if (ingredientSet.contains('rice')) {
      if (ingredientSet.contains('beans')) {
        recipes.add(_createRiceRecipe('Rice and Beans', ingredients));
      }
      if (ingredientSet.contains('vegetables') || _hasVegetables(ingredientSet)) {
        recipes.add(_createRiceRecipe('Vegetable Rice', ingredients));
      }
    }
    
    // Vegetable stir-fry
    if (_hasVegetables(ingredientSet)) {
      recipes.add(_createStirFryRecipe('Vegetable Stir-Fry', ingredients));
    }
    
    // Soup recipes
    if (ingredientSet.contains('water') || ingredientSet.contains('broth')) {
      if (_hasVegetables(ingredientSet)) {
        recipes.add(_createSoupRecipe('Vegetable Soup', ingredients));
      }
    }
    
    return recipes;
  }
  
  static List<Recipe> generateRecipesFromMood(String mood, String occasion) {
    final recipes = <Recipe>[];
    
    switch (mood.toLowerCase()) {
      case 'tired':
      case 'lazy':
        recipes.addAll(_getEasyRecipes(occasion));
        break;
      case 'excited':
      case 'energetic':
        recipes.addAll(_getAdventurousRecipes(occasion));
        break;
      case 'romantic':
        recipes.addAll(_getRomanticRecipes(occasion));
        break;
      default:
        recipes.addAll(_getComfortRecipes(occasion));
    }
    
    return recipes;
  }
  
  static List<Recipe> searchAndRemixRecipes(String query, String remixType) {
    final baseRecipes = _getCommonRecipes(query);
    final remixedRecipes = <Recipe>[];
    
    for (final recipe in baseRecipes) {
      switch (remixType.toLowerCase()) {
        case 'healthier':
          remixedRecipes.add(_makeHealthier(recipe));
          break;
        case 'faster':
          remixedRecipes.add(_makeFaster(recipe));
          break;
        case 'creative':
          remixedRecipes.add(_makeCreative(recipe));
          break;
        default:
          remixedRecipes.add(recipe);
      }
    }
    
    return remixedRecipes;
  }
  
  static String getCookingAdvice(String question, Recipe recipe, int currentStep) {
    final questionLower = question.toLowerCase();
    
    if (questionLower.contains('next') || questionLower.contains('what next')) {
      if (currentStep < recipe.steps.length - 1) {
        return 'Next step: ${recipe.steps[currentStep + 1]}';
      } else {
        return 'You\'re all done! Enjoy your meal!';
      }
    }
    
    if (questionLower.contains('substitute') || questionLower.contains('replace')) {
      return _getSubstitutionAdvice(questionLower, recipe);
    }
    
    if (questionLower.contains('how long') || questionLower.contains('time')) {
      return 'This recipe takes about ${recipe.cookingTime} minutes total. You\'re currently on step ${currentStep + 1} of ${recipe.steps.length}.';
    }
    
    if (questionLower.contains('temperature') || questionLower.contains('heat')) {
      return 'Use medium heat for best results. Adjust as needed based on your stove.';
    }
    
    return 'Take your time and follow the recipe carefully. Cooking should be enjoyable!';
  }
  
  // Helper methods
  static bool _hasVegetables(Set<String> ingredients) {
    final vegetables = ['carrot', 'carrots', 'onion', 'onions', 'pepper', 'peppers', 
                       'tomato', 'tomatoes', 'broccoli', 'spinach', 'mushroom', 'mushrooms',
                       'garlic', 'potato', 'potatoes', 'celery', 'cabbage'];
    return ingredients.any((ing) => vegetables.contains(ing));
  }
  
  static Recipe _createPastaRecipe(String title, List<String> ingredients) {
    return Recipe(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      ingredients: ingredients,
      steps: [
        'Boil water in a large pot',
        'Add pasta and cook according to package directions',
        'Heat oil in a pan and add ingredients',
        'Combine pasta with sauce',
        'Serve hot'
      ],
      cookingTime: 20,
      servings: 2,
      difficulty: 'Easy',
      category: 'Pasta',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  
  static Recipe _createEggRecipe(String title, List<String> ingredients) {
    return Recipe(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      ingredients: ingredients,
      steps: [
        'Crack eggs into a bowl',
        'Beat eggs with a fork',
        'Heat pan with oil or butter',
        'Cook eggs to desired doneness',
        'Season and serve'
      ],
      cookingTime: 10,
      servings: 1,
      difficulty: 'Easy',
      category: 'Breakfast',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  
  static Recipe _createRiceRecipe(String title, List<String> ingredients) {
    return Recipe(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      ingredients: ingredients,
      steps: [
        'Rinse rice if needed',
        'Add rice and water to pot',
        'Bring to boil, then simmer',
        'Cook until water is absorbed',
        'Let rest before serving'
      ],
      cookingTime: 25,
      servings: 2,
      difficulty: 'Easy',
      category: 'Rice',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  
  static Recipe _createStirFryRecipe(String title, List<String> ingredients) {
    return Recipe(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      ingredients: ingredients,
      steps: [
        'Heat oil in a wok or large pan',
        'Add harder vegetables first',
        'Stir-fry for 2-3 minutes',
        'Add softer vegetables',
        'Season and serve hot'
      ],
      cookingTime: 15,
      servings: 2,
      difficulty: 'Easy',
      category: 'Stir-fry',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  
  static Recipe _createSoupRecipe(String title, List<String> ingredients) {
    return Recipe(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      ingredients: ingredients,
      steps: [
        'Heat oil in a large pot',
        'Add vegetables and cook until soft',
        'Add broth or water',
        'Bring to boil, then simmer',
        'Cook until vegetables are tender',
        'Season and serve hot'
      ],
      cookingTime: 30,
      servings: 4,
      difficulty: 'Easy',
      category: 'Soup',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  
  static List<Recipe> _getEasyRecipes(String occasion) {
    return [
      Recipe(
        id: 'easy1',
        title: 'Quick Scrambled Eggs',
        ingredients: ['eggs', 'butter', 'salt', 'pepper'],
        steps: ['Crack eggs', 'Beat them', 'Cook in pan', 'Season and serve'],
        cookingTime: 5,
        servings: 1,
        difficulty: 'Easy',
        category: 'Breakfast',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Recipe(
        id: 'easy2',
        title: 'Simple Toast',
        ingredients: ['bread', 'butter'],
        steps: ['Toast bread', 'Add butter', 'Serve'],
        cookingTime: 3,
        servings: 1,
        difficulty: 'Easy',
        category: 'Breakfast',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }
  
  static List<Recipe> _getAdventurousRecipes(String occasion) {
    return [
      Recipe(
        id: 'adv1',
        title: 'Fusion Stir-Fry',
        ingredients: ['rice', 'vegetables', 'soy sauce', 'garlic', 'ginger'],
        steps: ['Cook rice', 'Stir-fry vegetables', 'Add sauce', 'Combine and serve'],
        cookingTime: 25,
        servings: 2,
        difficulty: 'Medium',
        category: 'Fusion',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }
  
  static List<Recipe> _getRomanticRecipes(String occasion) {
    return [
      Recipe(
        id: 'rom1',
        title: 'Heart-Shaped Pancakes',
        ingredients: ['flour', 'milk', 'eggs', 'sugar', 'butter'],
        steps: ['Mix batter', 'Pour heart shapes', 'Cook until golden', 'Serve with love'],
        cookingTime: 20,
        servings: 2,
        difficulty: 'Easy',
        category: 'Romantic',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }
  
  static List<Recipe> _getComfortRecipes(String occasion) {
    return [
      Recipe(
        id: 'comf1',
        title: 'Comfort Oatmeal',
        ingredients: ['oats', 'milk', 'honey', 'cinnamon'],
        steps: ['Cook oats', 'Add milk', 'Sweeten with honey', 'Sprinkle cinnamon'],
        cookingTime: 10,
        servings: 1,
        difficulty: 'Easy',
        category: 'Comfort',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }
  
  static List<Recipe> _getCommonRecipes(String query) {
    final queryLower = query.toLowerCase();
    
    if (queryLower.contains('pancake')) {
      return [_getPancakeRecipe()];
    } else if (queryLower.contains('pasta')) {
      return [_getPastaRecipe()];
    } else if (queryLower.contains('rice')) {
      return [_getRiceRecipe()];
    }
    
    return [];
  }
  
  static Recipe _getPancakeRecipe() {
    return Recipe(
      id: 'pancake',
      title: 'Classic Pancakes',
      ingredients: ['flour', 'milk', 'eggs', 'sugar', 'butter', 'baking powder'],
      steps: [
        'Mix dry ingredients',
        'Add wet ingredients',
        'Cook on griddle',
        'Flip when bubbles form',
        'Serve hot'
      ],
      cookingTime: 20,
      servings: 4,
      difficulty: 'Easy',
      category: 'Breakfast',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  
  static Recipe _getPastaRecipe() {
    return Recipe(
      id: 'pasta',
      title: 'Basic Pasta',
      ingredients: ['pasta', 'tomato sauce', 'garlic', 'olive oil', 'basil'],
      steps: [
        'Boil pasta water',
        'Cook pasta al dente',
        'Heat sauce with garlic',
        'Toss pasta with sauce',
        'Garnish with basil'
      ],
      cookingTime: 25,
      servings: 2,
      difficulty: 'Easy',
      category: 'Pasta',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  
  static Recipe _getRiceRecipe() {
    return Recipe(
      id: 'rice',
      title: 'Steamed Rice',
      ingredients: ['rice', 'water', 'salt'],
      steps: [
        'Rinse rice',
        'Add water and salt',
        'Bring to boil',
        'Simmer covered',
        'Let rest before serving'
      ],
      cookingTime: 20,
      servings: 2,
      difficulty: 'Easy',
      category: 'Rice',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  
  static Recipe _makeHealthier(Recipe recipe) {
    final healthierIngredients = recipe.ingredients.map((ing) {
      if (ing.contains('butter')) return ing.replaceFirst('butter', 'olive oil');
      if (ing.contains('cream')) return ing.replaceFirst('cream', 'Greek yogurt');
      if (ing.contains('sugar')) return ing.replaceFirst('sugar', 'honey');
      return ing;
    }).toList();
    
    return recipe.copyWith(
      title: '${recipe.title} (Healthier)',
      ingredients: healthierIngredients,
      notes: 'Healthier version with reduced fat and natural sweeteners.',
    );
  }
  
  static Recipe _makeFaster(Recipe recipe) {
    final fasterSteps = recipe.steps.map((step) {
      if (step.contains('simmer')) return step.replaceFirst('simmer', 'quick boil');
      if (step.contains('bake')) return step.replaceFirst('bake', 'microwave');
      return step;
    }).toList();
    
    return recipe.copyWith(
      title: '${recipe.title} (Quick)',
      steps: fasterSteps,
      cookingTime: (recipe.cookingTime * 0.6).round(),
      notes: 'Quick version using time-saving techniques.',
    );
  }
  
  static Recipe _makeCreative(Recipe recipe) {
    final creativeIngredients = List<String>.from(recipe.ingredients);
    if (!creativeIngredients.contains('herbs')) creativeIngredients.add('fresh herbs');
    if (!creativeIngredients.contains('spices')) creativeIngredients.add('exotic spices');
    
    return recipe.copyWith(
      title: '${recipe.title} (Creative)',
      ingredients: creativeIngredients,
      notes: 'Creative version with additional flavors and garnishes.',
    );
  }
  
  static String _getSubstitutionAdvice(String question, Recipe recipe) {
    if (question.contains('milk')) {
      return 'You can substitute milk with water, plant-based milk, or cream for richer results.';
    }
    if (question.contains('egg')) {
      return 'For eggs, try flax eggs (1 tbsp flax + 3 tbsp water), mashed banana, or commercial egg replacer.';
    }
    if (question.contains('butter')) {
      return 'Butter can be replaced with oil, coconut oil, or plant-based butter depending on use.';
    }
    if (question.contains('flour')) {
      return 'All-purpose flour works for most recipes. For gluten-free, try almond flour or gluten-free blends.';
    }
    
    return 'Consider the function of the ingredient - binding, moisture, or flavor - when finding substitutes.';
  }
}