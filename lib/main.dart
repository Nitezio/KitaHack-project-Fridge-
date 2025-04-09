import 'package:flutter/material.dart';
import 'auth_screen.dart';
import 'main_navigation.dart'; // Use main_navigation instead of individual screens

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Fridge Recipe Generator',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: AuthScreen(), // Start with the authentication screen
      //  routes: {
      //   '/fridge': (context) => FridgeInventoryScreen(),
      //   '/recipes': (context) => RecipeGenerationScreen(),
      // },
      //  Instead of routes, use main_navigation
    );
  }
}