import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'fridge_item.dart';
import 'recipe.dart';
import 'recipe_detail_screen.dart';
import 'dart:convert';

class GenerateRecipeScreen extends StatefulWidget {
  @override
  _GenerateRecipeScreenState createState() => _GenerateRecipeScreenState();
}

class _GenerateRecipeScreenState extends State<GenerateRecipeScreen> {
  String? _selectedCuisine;
  String? _selectedMealType;
  final _servingsController = TextEditingController(text: '2');
  bool _isVegan = false;
  bool _isVegetarian = false;
  bool _isGlutenFree = false;
  bool _isLoading = false;
  List<Recipe> _generatedRecipes = [];
  final List<String> _cuisineOptions = [
    'Italian', 'Asian', 'Mexican', 'Indian', 'American', 'Other'
  ];
  final List<String> _mealTypeOptions = [
    'Breakfast', 'Lunch', 'Dinner', 'Snack', 'Dessert'
  ];

  Future<List<String>> _getFridgeIngredients() async {
    final prefs = await SharedPreferences.getInstance();
    final itemsJson = prefs.getStringList('fridgeItems') ?? [];
    return itemsJson.map((jsonString) {
      try {
        final item = FridgeItem.fromJson(jsonDecode(jsonString));
        return '${item.name} (${item.quantity ?? 'some'} ${item.unit ?? ''})';
      } catch (e) {
        print('Error decoding fridge item: $e');
        return '';
      }
    }).where((item) => item.isNotEmpty).toList();
  }

  Future<void> _generateRecipes() async {
    if (_selectedCuisine == null || _selectedMealType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select Cuisine and Meal Type.')),
      );
      return;
    }

    final servings = int.tryParse(_servingsController.text);
    if (servings == null || servings <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid number of servings.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _generatedRecipes = [];
    });

    final apiKey = "AIzaSyCiivzAON1_evdchLTtAG9xDdxwzULw-Ks"; // Replace with your actual Gemini API key
    final model = GenerativeModel(model: 'gemini-2.0-flash', apiKey: apiKey);

    final ingredients = await _getFridgeIngredients();
    String dietaryConstraints = '';
    if (_isVegan) {
      dietaryConstraints += 'Recipes MUST be strictly vegan (no animal products, including dairy, eggs, or honey). ';
    } else if (_isVegetarian) {
      dietaryConstraints += 'Recipes MUST be strictly vegetarian (no meat, poultry, fish, or gelatin, but dairy and eggs are allowed). ';
    }
    if (_isGlutenFree) {
      dietaryConstraints += 'Recipes MUST be strictly gluten-free (no wheat, barley, rye, or derivatives). ';
    }
    if (dietaryConstraints.isEmpty) {
      dietaryConstraints = 'No specific dietary restrictions. ';
    }

    final prompt = '''
Generate exactly 3 cost-saving and healthy recipes for a $_selectedCuisine $_selectedMealType dish for $servings people using these ingredients: ${ingredients.join(', ')}. 
$dietaryConstraints
Each recipe must follow this exact format with detailed instructions:
Title: [Recipe Name]
Description: [2-3 sentence description]
Ingredients:

[Item 1 with quantity]
[Item 2 with quantity] Instructions:
[Detailed step 1, including preparation or cooking method]
[Detailed step 2, including timing or technique]
[Detailed step 3, etc., minimum 4 steps]
[Detailed step 4] Cooking Time: [Number] minutes Nutritional Info: [e.g., Calories: 300, Protein: 10g, Carbs: 20g, Fat: 15g]
Separate each recipe with "---". Ensure all ingredients are prefixed with "-" and listed with quantities, and instructions are detailed with at least 4 steps. Do not violate dietary constraints.
''';

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      final recipesText = response.text ?? '';
      print('Raw API Response: $recipesText');
      setState(() {
        _generatedRecipes = _parseRecipes(recipesText);
        _generatedRecipes = _validateRecipes(_generatedRecipes, servings);
        print('Final Recipes: ${_generatedRecipes.map((r) => r.title).toList()}');
        _isLoading = false;
      });
    } catch (e) {
      print('Gemini API Error: $e');
      setState(() {
        _generatedRecipes = _getDefaultRecipes(servings);
        print('Fallback Recipes: ${_generatedRecipes.map((r) => r.title).toList()}');
        _isLoading = false;
      });
    }
  }

  List<Recipe> _parseRecipes(String recipesText) {
    final List<Recipe> recipes = [];
    final recipeSections = recipesText.split('---').map((s) => s.trim()).toList();

    for (var section in recipeSections) {
      if (section.isEmpty) continue;
      try {
        final lines = section.split('\n').map((l) => l.trim()).toList();
        String title = '';
        String description = '';
        List<String> ingredients = [];
        String instructions = '';
        int cookingTime = 0;
        String nutritionalInfo = '';

        int currentSection = 0;
        for (var line in lines) {
          if (line.isEmpty) continue;
          if (line.startsWith('Title:')) {
            title = line.replaceFirst('Title:', '').trim();
            currentSection = 0;
          } else if (line.startsWith('Description:')) {
            description = line.replaceFirst('Description:', '').trim();
            currentSection = 1;
          } else if (line.startsWith('Ingredients:')) {
            ingredients = [];
            currentSection = 2;
          } else if (line.startsWith('Instructions:')) {
            instructions = '';
            currentSection = 3;
          } else if (line.startsWith('Cooking Time:')) {
            cookingTime = int.tryParse(line.replaceFirst('Cooking Time:', '').replaceAll('minutes', '').trim()) ?? 0;
            currentSection = 4;
          } else if (line.startsWith('Nutritional Info:')) {
            nutritionalInfo = line.replaceFirst('Nutritional Info:', '').trim();
            currentSection = 5;
          } else if (currentSection == 1) {
            description += ' $line';
          } else if (currentSection == 2 && line.isNotEmpty) { // Capture all non-empty lines after Ingredients:
            if (line.startsWith('-')) {
              ingredients.add(line.replaceFirst('-', '').trim());
            } else {
              ingredients.add(line.trim()); // Fallback for non-prefixed ingredients
            }
          } else if (currentSection == 3 && RegExp(r'^\d+\.').hasMatch(line)) {
            instructions += '$line\n';
          }
        }

        if (title.isNotEmpty) {
          recipes.add(Recipe(
            title: title,
            description: description.trim(),
            ingredients: ingredients,
            instructions: instructions.trim(),
            imageUrl: '',
            cookingTime: cookingTime,
            servings: int.parse(_servingsController.text),
            cuisine: _selectedCuisine!,
            mealType: _selectedMealType!,
            nutritionalInfo: nutritionalInfo,
          ));
        }
      } catch (e) {
        print('Error parsing recipe: $e');
      }
    }
    return recipes;
  }

  List<Recipe> _validateRecipes(List<Recipe> recipes, int servings) {
    final List<Recipe> validatedRecipes = [];
    final List<String> nonVegan = ['meat', 'beef', 'chicken', 'pork', 'fish', 'gelatin', 'honey', 'egg', 'dairy', 'milk', 'cheese', 'butter'];
    final List<String> nonVegetarian = ['meat', 'beef', 'chicken', 'pork', 'fish', 'gelatin'];
    final List<String> gluten = ['wheat', 'barley', 'rye', 'flour', 'bread', 'pasta'];

    for (var recipe in recipes) {
      bool isValid = true;
      String invalidReason = '';
      if (_isVegan) {
        for (var ingredient in recipe.ingredients) {
          if (nonVegan.any((item) => ingredient.toLowerCase().contains(item))) {
            isValid = false;
            invalidReason = 'Contains non-vegan ingredients';
            break;
          }
        }
      } else if (_isVegetarian) {
        for (var ingredient in recipe.ingredients) {
          if (nonVegetarian.any((item) => ingredient.toLowerCase().contains(item))) {
            isValid = false;
            invalidReason = 'Contains non-vegetarian ingredients';
            break;
          }
        }
      }
      if (_isGlutenFree) {
        for (var ingredient in recipe.ingredients) {
          if (gluten.any((item) => ingredient.toLowerCase().contains(item))) {
            isValid = false;
            invalidReason = 'Contains gluten';
            break;
          }
        }
      }
      if (isValid) validatedRecipes.add(recipe);
      else print('Recipe "${recipe.title}" invalidated: $invalidReason');
    }

    while (validatedRecipes.length < 3) {
      final defaults = _getDefaultRecipes(servings);
      for (var defaultRecipe in defaults) {
        if (validatedRecipes.length >= 3) break;
        if ((!_isVegan || defaultRecipe.ingredients.every((i) => !nonVegan.any((nv) => i.toLowerCase().contains(nv)))) &&
            (!_isVegetarian || defaultRecipe.ingredients.every((i) => !nonVegetarian.any((nv) => i.toLowerCase().contains(nv)))) &&
            (!_isGlutenFree || defaultRecipe.ingredients.every((i) => !gluten.any((g) => i.toLowerCase().contains(g))))) {
          validatedRecipes.add(defaultRecipe);
        }
      }
      break;
    }

    if (validatedRecipes.length < recipes.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Some recipes adjusted to match filters.')),
      );
    }
    return validatedRecipes.take(3).toList();
  }

  List<Recipe> _getDefaultRecipes(int servings) {
    return [
      Recipe(
        title: 'Simple Tomato Pasta',
        description: 'A quick and healthy pasta dish using basic pantry staples. Perfect for a budget-friendly meal.',
        ingredients: ['200g gluten-free pasta', '400g canned tomatoes', '2 cloves garlic', '2 tbsp olive oil', 'Salt to taste', 'Pepper to taste'],
        instructions: '1. Bring a pot of salted water to a boil and cook 200g gluten-free pasta for 8-10 minutes until al dente, then drain.\n2. Heat 2 tbsp olive oil in a skillet over medium heat and sauté 2 cloves minced garlic for 1-2 minutes until golden.\n3. Add 400g canned tomatoes, season with salt and pepper, and simmer for 10 minutes, stirring occasionally.\n4. Toss the cooked pasta with the sauce and serve hot.',
        imageUrl: '',
        cookingTime: 20,
        servings: servings,
        cuisine: 'Italian',
        mealType: 'Dinner',
        nutritionalInfo: 'Calories: 400, Protein: 10g, Carbs: 60g, Fat: 15g',
      ),
      Recipe(
        title: 'Vegetable Stir-Fry',
        description: 'A cost-effective stir-fry using fridge veggies. Quick to make and packed with nutrients.',
        ingredients: ['2 cups mixed vegetables', '2 tbsp soy sauce', '1 tbsp olive oil', '1 cup cooked rice'],
        instructions: '1. Cook 1 cup rice in a pot with 2 cups water, bringing it to a boil then simmering for 15 minutes until fluffy.\n2. Heat 1 tbsp olive oil in a large pan over medium-high heat.\n3. Add 2 cups mixed vegetables and stir-fry for 5-7 minutes until tender-crisp.\n4. Pour in 2 tbsp soy sauce, stir well for 1 minute, and serve over the cooked rice.',
        imageUrl: '',
        cookingTime: 15,
        servings: servings,
        cuisine: 'Asian',
        mealType: 'Dinner',
        nutritionalInfo: 'Calories: 300, Protein: 8g, Carbs: 50g, Fat: 10g',
      ),
      Recipe(
        title: 'Bean Salad',
        description: 'A refreshing and cheap salad with canned beans. Ideal for a light, healthy meal.',
        ingredients: ['1 can (15oz) beans', '1 medium onion', '2 tbsp vinegar', '1 tbsp olive oil'],
        instructions: '1. Drain and rinse 1 can of beans under cold water, then set aside in a mixing bowl.\n2. Finely chop 1 medium onion and add it to the beans.\n3. In a small bowl, whisk together 2 tbsp vinegar and 1 tbsp olive oil to make a dressing.\n4. Pour the dressing over the beans and onion, toss well, and let sit for 10 minutes before serving.',
        imageUrl: '',
        cookingTime: 10,
        servings: servings,
        cuisine: 'American',
        mealType: 'Lunch',
        nutritionalInfo: 'Calories: 250, Protein: 12g, Carbs: 35g, Fat: 8g',
      ),
    ];
  }

  void _clearRecipes() => setState(() => _generatedRecipes = []);

  void _saveRecipe(Recipe recipe) async {
    final prefs = await SharedPreferences.getInstance();
    final savedRecipesJson = prefs.getStringList('savedRecipes') ?? [];
    final recipeJson = jsonEncode(recipe.toJson());
    if (!savedRecipesJson.contains(recipeJson)) {
      savedRecipesJson.add(recipeJson);
      await prefs.setStringList('savedRecipes', savedRecipesJson);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${recipe.title} saved!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade100, Colors.blue.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Your Recipes',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade900,
                  ),
                ),
                SizedBox(height: 20),
                _buildDropdown('Cuisine', _cuisineOptions, _selectedCuisine, (val) => _selectedCuisine = val),
                SizedBox(height: 15),
                _buildDropdown('Meal Type', _mealTypeOptions, _selectedMealType, (val) => _selectedMealType = val),
                SizedBox(height: 15),
                _buildTextField('Servings', _servingsController),
                SizedBox(height: 20),
                _buildFilterTile('Vegan', _isVegan, (val) {
                  _isVegan = val!;
                  if (_isVegan) _isVegetarian = false;
                }),
                _buildFilterTile('Vegetarian', _isVegetarian, (val) {
                  _isVegetarian = val!;
                  if (_isVegetarian && _isVegan) _isVegan = false;
                }),
                _buildFilterTile('Gluten-Free', _isGlutenFree, (val) => _isGlutenFree = val!),
                SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _isLoading ? null : _generateRecipes,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 5,
                    minimumSize: Size(double.infinity, 60),
                  ),
                  child: _isLoading
                      ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(width: 10),
                      Text('Generating...', style: TextStyle(fontSize: 18, color: Colors.white)),
                    ],
                  )
                      : Text('Generate Recipes', style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
                if (_generatedRecipes.isNotEmpty) ...[
                  SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Your Recipes',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green.shade900),
                      ),
                      IconButton(
                        icon: Icon(Icons.clear, color: Colors.red),
                        onPressed: _clearRecipes,
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  ..._generatedRecipes.map((recipe) => _buildRecipeCard(recipe)),
                ] else if (_isLoading)
                  Padding(
                    padding: EdgeInsets.only(top: 30),
                    child: Center(child: Text('Cooking up something delicious...', style: TextStyle(fontSize: 16, color: Colors.grey.shade700))),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> options, String? value, Function(String?) onChanged) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 5, spreadRadius: 2)],
      ),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        ),
        value: value,
        items: options.map((option) => DropdownMenuItem(value: option, child: Text(option))).toList(),
        onChanged: _isLoading ? null : (val) => setState(() => onChanged(val)),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 5, spreadRadius: 2)],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        ),
        enabled: !_isLoading,
        validator: (value) => (value == null || value.isEmpty || int.tryParse(value)! <= 0) ? 'Enter a positive number' : null,
      ),
    );
  }

  Widget _buildFilterTile(String title, bool value, Function(bool?) onChanged) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 5, spreadRadius: 2)],
      ),
      child: CheckboxListTile(
        title: Text(title, style: TextStyle(fontSize: 16, color: Colors.green.shade900)),
        value: value,
        onChanged: _isLoading ? null : (val) => setState(() => onChanged(val)),
        activeColor: Colors.green.shade600,
        contentPadding: EdgeInsets.symmetric(horizontal: 15),
      ),
    );
  }

  Widget _buildRecipeCard(Recipe recipe) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RecipeDetailScreen(recipe: recipe)),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 10),
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 8, spreadRadius: 3)],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recipe.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green.shade900)),
                  SizedBox(height: 5),
                  Text(recipe.description, style: TextStyle(fontSize: 14, color: Colors.grey.shade700), maxLines: 2, overflow: TextOverflow.ellipsis),
                  SizedBox(height: 5),
                  Text('Time: ${recipe.cookingTime} min | Servings: ${recipe.servings}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.bookmark_border, color: Colors.green.shade600),
              onPressed: () => _saveRecipe(recipe),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _servingsController.dispose();
    super.dispose();
  }
}