import 'package:flutter/material.dart';
import 'recipe.dart';
import 'recipe_detail_screen.dart';

class RecipesScreen extends StatefulWidget {
  @override
  _RecipesScreenState createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  List<Recipe> _recipes = [
    Recipe(
      title: 'Spaghetti Bolognese',
      description: 'Classic Italian pasta dish with a rich meat sauce.',
      ingredients: ['Spaghetti', 'Ground beef', 'Tomato sauce', 'Onion', 'Garlic', 'Carrots', 'Celery', 'Olive oil', 'Parmesan cheese'],
      instructions: '1. Cook spaghetti according to package directions. 2. Sauté vegetables and meat. 3. Add tomato sauce and simmer. 4. Serve sauce over spaghetti with parmesan cheese.',
      imageUrl: 'https://www.allrecipes.com/thmb/1gENtK3Cu8iT99BVTK_bE7KRxvA=/750x0/image_66818-bolognese-sauce-af7c1b5049c3453ca2056c5261b1b590.jpg',
      cookingTime: 60,
      servings: 4,
      cuisine: 'Italian',
      mealType: 'Dinner',
      nutritionalInfo: 'Calories: 500, Protein: 30g, Carbs: 60g, Fat: 20g',
    ),
    Recipe(
      title: 'Chicken Tikka Masala',
      description: 'Creamy and flavorful Indian curry with tender chicken pieces.',
      ingredients: ['Chicken breast', 'Yogurt', 'Tikka masala spice blend', 'Tomato sauce', 'Cream', 'Onion', 'Garlic', 'Ginger', 'Cilantro'],
      instructions: '1. Marinate chicken in yogurt and spices. 2. Grill or bake chicken. 3. Sauté onions and add tomato sauce and cream. 4. Add chicken and simmer. 5. Garnish with cilantro.',
      imageUrl: 'https://www.indianhealthyrecipes.com/wp-content/uploads/2021/01/chicken-tikka-masala-recipe.jpg',
      cookingTime: 45,
      servings: 4,
      cuisine: 'Indian',
      mealType: 'Dinner',
      nutritionalInfo: 'Calories: 450, Protein: 40g, Carbs: 25g, Fat: 20g',
    ),
    // Add more recipes here
  ];

  String _selectedCuisineFilter = 'All';
  String _selectedMealTypeFilter = 'All';

  List<Recipe> get _filteredRecipes {
    List<Recipe> filtered = _recipes;

    if (_selectedCuisineFilter != 'All') {
      filtered = filtered.where((recipe) => recipe.cuisine == _selectedCuisineFilter).toList();
    }

    if (_selectedMealTypeFilter != 'All') {
      filtered = filtered.where((recipe) => recipe.mealType == _selectedMealTypeFilter).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recipes'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                DropdownButton<String>(
                  value: _selectedCuisineFilter,
                  items: ['All', 'Italian', 'Indian'].map((String cuisine) {
                    return DropdownMenuItem<String>(
                      value: cuisine,
                      child: Text(cuisine),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCuisineFilter = newValue!;
                    });
                  },
                  hint: Text('Cuisine'),
                ),
                SizedBox(width: 16.0),
                DropdownButton<String>(
                  value: _selectedMealTypeFilter,
                  items: ['All', 'Dinner'].map((String mealType) {
                    return DropdownMenuItem<String>(
                      value: mealType,
                      child: Text(mealType),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedMealTypeFilter = newValue!;
                    });
                  },
                  hint: Text('Meal Type'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredRecipes.length,
              itemBuilder: (context, index) {
                final recipe = _filteredRecipes[index];
                return Card(
                  margin: EdgeInsets.all(8.0),
                  child: ListTile(
                    leading: Image.network(
                      recipe.imageUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, object, stackTrace) {
                        return Image.asset(
                          'assets/placeholder_image.png',
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                    title: Text(recipe.title),
                    subtitle: Text(recipe.description),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RecipeDetailScreen(recipe: recipe),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}