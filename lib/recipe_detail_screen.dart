import 'package:flutter/material.dart';
import 'recipe.dart';

class RecipeDetailScreen extends StatelessWidget {
  final Recipe recipe;

  RecipeDetailScreen({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(recipe.title),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (recipe.imageUrl.isNotEmpty)
              Image.network(
                recipe.imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, object, stackTrace) => Container(
                  height: 200,
                  color: Colors.grey[300],
                  child: Center(child: Text('Image not available')),
                ),
              )
            else
              Container(
                height: 200,
                color: Colors.grey[300],
                child: Center(child: Text('No image available')),
              ),
            SizedBox(height: 16.0),
            Text(recipe.title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 8.0),
            Text(recipe.description, style: TextStyle(fontSize: 16)),
            SizedBox(height: 16.0),
            Text('Ingredients:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ...recipe.ingredients.map((ingredient) => Padding(
              padding: EdgeInsets.only(left: 16.0, top: 4.0),
              child: Text('• $ingredient'),
            )),
            SizedBox(height: 16.0),
            Text('Instructions:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(recipe.instructions, style: TextStyle(fontSize: 16)),
            SizedBox(height: 16.0),
            Row(children: [
              Icon(Icons.timer),
              SizedBox(width: 4),
              Text('Cooking Time: ${recipe.cookingTime} minutes'),
            ]),
            SizedBox(height: 8.0),
            Row(children: [
              Icon(Icons.restaurant),
              SizedBox(width: 4),
              Text('Servings: ${recipe.servings}'),
            ]),
            SizedBox(height: 8.0),
            Text('Cuisine: ${recipe.cuisine}'),
            SizedBox(height: 8.0),
            Text('Meal Type: ${recipe.mealType}'),
            SizedBox(height: 16.0),
            Text('Nutritional Information:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(recipe.nutritionalInfo),
          ],
        ),
      ),
    );
  }
}