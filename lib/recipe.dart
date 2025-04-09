class Recipe {
  final String title;
  final String description;
  final List<String> ingredients;
  final String instructions;
  final String imageUrl;
  final int cookingTime;
  final int servings;
  final String cuisine;
  final String mealType;
  final String nutritionalInfo;

  Recipe({
    required this.title,
    required this.description,
    required this.ingredients,
    required this.instructions,
    required this.imageUrl,
    required this.cookingTime,
    required this.servings,
    required this.cuisine,
    required this.mealType,
    required this.nutritionalInfo,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      title: json['title'] ?? 'Default Title',
      description: json['description'] ?? 'Default Description',
      ingredients: List<String>.from(json['ingredients'] ?? []),
      instructions: json['instructions'] ?? 'Default Instructions',
      imageUrl: json['imageUrl'] ?? '',
      cookingTime: json['cookingTime'] ?? 0,
      servings: json['servings'] ?? 0,
      cuisine: json['cuisine'] ?? 'Any',
      mealType: json['mealType'] ?? 'Any',
      nutritionalInfo: json['nutritionalInfo'] ?? 'No Nutritional Info',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'ingredients': ingredients,
      'instructions': instructions,
      'imageUrl': imageUrl,
      'cookingTime': cookingTime,
      'servings': servings,
      'cuisine': cuisine,
      'mealType': mealType,
      'nutritionalInfo': nutritionalInfo,
    };
  }
}