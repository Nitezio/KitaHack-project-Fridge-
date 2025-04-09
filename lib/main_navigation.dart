import 'package:flutter/material.dart';
import 'fridge_inventory_screen.dart';
import 'recipes_screen.dart';
import 'saved_recipes_screen.dart';
import 'settings_screen.dart';
import 'generate_recipe_screen.dart';

class MainNavigation extends StatefulWidget {
  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    FridgeInventoryScreen(),
    RecipesScreen(),
    GenerateRecipeScreen(),
    SavedRecipesScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
          child: _pages[_selectedIndex],
        ),
        bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
        icon: Icon(Icons.kitchen),
    label: 'Fridge',
    ),
    BottomNavigationBarItem(
    icon: Icon(Icons.search),
    label: 'Recipes',
    ),
    BottomNavigationBarItem(
    icon: Icon(Icons.add_circle_outline),
    label: 'Generate',
    ),
    BottomNavigationBarItem(
    icon: Icon(Icons.bookmark),
    label: 'Saved',
    ),
    BottomNavigationBarItem(
    icon: Icon(Icons.settings),
    label: 'Settings',
    ),],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.green,
          unselectedItemColor: Colors.grey,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
        ),
    );
  }
}