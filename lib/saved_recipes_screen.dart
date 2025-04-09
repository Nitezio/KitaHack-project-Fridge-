import 'package:flutter/material.dart';
import 'recipe.dart';
import 'recipe_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SavedRecipesScreen extends StatefulWidget {
  @override
  _SavedRecipesScreenState createState() => _SavedRecipesScreenState();
}

class _SavedRecipesScreenState extends State<SavedRecipesScreen> {
  List<Recipe> _savedRecipes = [];

  @override
  void initState() {
    super.initState();
    _loadSavedRecipes();
  }

  Future<void> _loadSavedRecipes() async {
    final prefs = await SharedPreferences.getInstance();
    final savedRecipesJson = prefs.getStringList('savedRecipes') ?? [];
    setState(() {
      _savedRecipes = savedRecipesJson.map((jsonString) => Recipe.fromJson(jsonDecode(jsonString))).toList();
    });
  }

  Future<void> _saveRecipes() async {
    final prefs = await SharedPreferences.getInstance();
    final savedRecipesJson = _savedRecipes.map((recipe) => jsonEncode(recipe.toJson())).toList();
    await prefs.setStringList('savedRecipes', savedRecipesJson);
  }

  void _removeRecipe(Recipe recipe) {
    setState(() {
      _savedRecipes.removeWhere((savedRecipe) => savedRecipe.title == recipe.title);
      _saveRecipes();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${recipe.title} removed from saved recipes')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Saved Recipes'),
      ),
      body: _savedRecipes.isEmpty
          ? Center(child: Text('You have no saved recipes yet.'))
          : ListView.builder(
        itemCount: _savedRecipes.length,
        itemBuilder: (context, index) {
          final recipe = _savedRecipes[index];
          return Card(
            margin: EdgeInsets.all(8.0),
            child: ListTile(
              title: Text(recipe.title, style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                recipe.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RecipeDetailScreen(recipe: recipe)),
                );
              },
              trailing: IconButton(
                icon: Icon(Icons.delete),
                onPressed: () => _removeRecipe(recipe),
              ),
            ),
          );
        },
      ),
    );
  }
}