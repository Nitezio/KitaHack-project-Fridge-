import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'fridge_item.dart';
import 'dart:convert';
import 'generate_recipe_screen.dart';
import 'settings_screen.dart';
import 'saved_recipes_screen.dart';

class FridgeInventoryScreen extends StatefulWidget {
  @override
  _FridgeInventoryScreenState createState() => _FridgeInventoryScreenState();
}

class _FridgeInventoryScreenState extends State<FridgeInventoryScreen> {
  List<FridgeItem> _fridgeItems = [];
  String? _selectedCategoryFilter;
  int _selectedIndex = 0;

  final List<String> _categoryOptions = [
    '',
    'Dairy',
    'Vegetables',
    'Fruits',
    'Meat',
    'Poultry',
    'Seafood',
    'Grains',
    'Beverages',
    'Other',
  ];

  List<FridgeItem> get _filteredFridgeItems {
    if (_selectedCategoryFilter == null || _selectedCategoryFilter!.isEmpty) {
      return _fridgeItems;
    } else {
      return _fridgeItems
          .where((item) => item.category == _selectedCategoryFilter)
          .toList();
    }
  }

  @override
  void initState() {
    super.initState();
    _loadFridgeItems();
  }

  Future<void> _loadFridgeItems() async {
    final prefs = await SharedPreferences.getInstance();
    final itemsJson = prefs.getStringList('fridgeItems') ?? [];
    setState(() {
      _fridgeItems = itemsJson
          .map((jsonString) => FridgeItem.fromJson(jsonDecode(jsonString)))
          .toList();
    });
  }

  Future<void> _saveFridgeItems() async {
    final prefs = await SharedPreferences.getInstance();
    final itemsJson =
    _fridgeItems.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList('fridgeItems', itemsJson);
  }

  void _addItem(FridgeItem newItem) {
    setState(() {
      _fridgeItems.add(newItem);
      _saveFridgeItems();
    });
  }

  void _removeItem(int index) {
    setState(() {
      _fridgeItems.removeAt(index);
      _saveFridgeItems();
    });
  }

  void _editItem(int index, FridgeItem updatedItem) {
    setState(() {
      _fridgeItems[index] = updatedItem;
      _saveFridgeItems();
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _getBodyWidget() {
    switch (_selectedIndex) {
      case 0:
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Filter by Category (optional)',
                  border: OutlineInputBorder(),
                ),
                value: _selectedCategoryFilter,
                items: [
                  'All',
                  ..._categoryOptions.where((option) => option.isNotEmpty)
                ].map((String category) {
                  return DropdownMenuItem<String>(
                    value: category == 'All' ? null : category,
                    child:
                    Text(category == 'All' ? 'All Categories' : category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategoryFilter = newValue;
                  });
                },
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredFridgeItems.length,
                itemBuilder: (context, index) {
                  final item = _filteredFridgeItems[index];
                  return Card(
                    margin: EdgeInsets.all(8.0),
                    child: ListTile(
                      title: Text(item.name),
                      subtitle: Text(
                        'Expires: ${item.expiryDate.toLocal().toString().split(' ')[0]}' +
                            (item.quantity != null
                                ? ', ${item.quantity} ${item.unit ?? ""}'
                                : '') +
                            (item.category != null && item.category!.isNotEmpty
                                ? ', Category: ${item.category}'
                                : ''),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () =>
                                _showEditItemDialog(context, index, item),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () => _removeItem(index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      case 1:
        return GenerateRecipeScreen();
      case 2:
        return SettingsScreen();
      case 3:
        return SavedRecipesScreen();
      default:
        return Text('Unknown Page');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fridge Inventory'),
      ),
      body: _getBodyWidget(),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (BuildContext context) {
              return AddItemForm(
                onAddItem: _addItem,
                onCancel: () => Navigator.pop(context),
              );
            },
          );
        },
        child: Icon(Icons.add),
      )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.kitchen),
            label: 'Inventory',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Recipe',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark),
            label: 'Saved',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  Future<void> _showEditItemDialog(
      BuildContext context, int index, FridgeItem item) async {
    return showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return EditItemForm(
          initialItem: item,
          onEditItem: (updatedItem) => _editItem(index, updatedItem),
          onCancel: () => Navigator.pop(context),
        );
      },
    );
  }
}

class AddItemForm extends StatefulWidget {
  final Function(FridgeItem) onAddItem;
  final VoidCallback onCancel;

  AddItemForm({required this.onAddItem, required this.onCancel});

  @override
  _AddItemFormState createState() => _AddItemFormState();
}

class _AddItemFormState extends State<AddItemForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  String? _selectedUnit;
  String? _selectedCategory;
  DateTime? _selectedExpiryDate;

  final List<String> _unitOptions = [
    '',
    'kg',
    'g',
    'L',
    'ml',
    'count',
    'unit',
    'pack',
    'bunch',
    'piece',
  ];

  final List<String> _categoryOptions = [
    '',
    'Dairy',
    'Vegetables',
    'Fruits',
    'Meat',
    'Poultry',
    'Seafood',
    'Grains',
    'Beverages',
    'Other',
  ];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedExpiryDate) {
      setState(() {
        _selectedExpiryDate = picked;
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_selectedExpiryDate != null) {
        final newItem = FridgeItem(
          name: _nameController.text,
          expiryDate: _selectedExpiryDate!,
          quantity: _quantityController.text.isNotEmpty
              ? double.tryParse(_quantityController.text)
              : null,
          unit: _selectedUnit?.isNotEmpty == true ? _selectedUnit : null,
          category: _selectedCategory?.isNotEmpty == true ? _selectedCategory : null,
        );
        widget.onAddItem(newItem);
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select an expiry date.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Item Name'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the item name';
                }
                return null;
              },
            ),
            SizedBox(height: 16.0),
            TextFormField(
              controller: _quantityController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: 'Quantity (optional)'),
            ),
            SizedBox(height: 8.0),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Unit (optional)',
                border: OutlineInputBorder(),
              ),
              value: _selectedUnit,
              items: _unitOptions.map((String unit) {
                return DropdownMenuItem<String>(
                  value: unit.isNotEmpty ? unit : null,
                  child: Text(unit.isNotEmpty ? unit : 'No Unit'),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedUnit = newValue;
                });
              },
            ),
            SizedBox(height: 8.0),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Category (optional)',
                border: OutlineInputBorder(),
              ),
              value: _selectedCategory,
              items: _categoryOptions.map((String category) {
                return DropdownMenuItem<String>(
                  value: category.isNotEmpty ? category : null,
                  child: Text(category.isNotEmpty ? category : 'No Category'),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCategory = newValue;
                });
              },
            ),
            SizedBox(height: 16.0),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    _selectedExpiryDate == null
                        ? 'Select Expiry Date'
                        : 'Expiry Date: ${_selectedExpiryDate!.toLocal().toString().split(' ')[0]}',
                  ),
                ),
                TextButton(
                  onPressed: () => _selectDate(context),
                  child: Text('Select Date'),
                ),
              ],
            ),
            SizedBox(height: 24.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: widget.onCancel, child: Text('Cancel')),
                SizedBox(width: 16.0),
                ElevatedButton(onPressed: _submitForm, child: Text('Add Item')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class EditItemForm extends StatefulWidget {
  final FridgeItem initialItem;
  final Function(FridgeItem) onEditItem;
  final VoidCallback onCancel;

  EditItemForm(
      {required this.initialItem,
        required this.onEditItem,
        required this.onCancel});

  @override
  _EditItemFormState createState() => _EditItemFormState();
}

class _EditItemFormState extends State<EditItemForm> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.initialItem.name);
  late final _quantityController =
  TextEditingController(text: widget.initialItem.quantity?.toString() ?? '');
  String? _selectedUnit;
  String? _selectedCategory;
  DateTime? _selectedExpiryDate;

  final List<String> _unitOptions = [
    '',
    'kg',
    'g',
    'L',
    'ml',
    'count',
    'unit',
    'pack',
    'bunch',
    'piece',
  ];

  final List<String> _categoryOptions = [
    '',
    'Dairy',
    'Vegetables',
    'Fruits',
    'Meat',
    'Poultry',
    'Seafood',
    'Grains',
    'Beverages',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _selectedUnit = widget.initialItem.unit;
    _selectedCategory = widget.initialItem.category;
    _selectedExpiryDate = widget.initialItem.expiryDate;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedExpiryDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedExpiryDate) {
      setState(() {
        _selectedExpiryDate = picked;
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_selectedExpiryDate != null) {
        final updatedItem = FridgeItem(
          name: _nameController.text,
          expiryDate: _selectedExpiryDate!,
          quantity: _quantityController.text.isNotEmpty
              ? double.tryParse(_quantityController.text)
              : null,
          unit: _selectedUnit,
          category: _selectedCategory,
        );
        widget.onEditItem(updatedItem);
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select an expiry date.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Item Name'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the item name';
                }
                return null;
              },
            ),
            SizedBox(height: 16.0),
            TextFormField(
              controller: _quantityController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: 'Quantity (optional)'),
            ),
            SizedBox(height: 8.0),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Unit (optional)',
                border: OutlineInputBorder(),
              ),
              value: _selectedUnit,
              items: _unitOptions.map((String unit) {
                return DropdownMenuItem<String>(
                  value: unit.isNotEmpty ? unit : null,
                  child: Text(unit.isNotEmpty ? unit : 'No Unit'),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedUnit = newValue;
                });
              },
            ),
            SizedBox(height: 8.0),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Category (optional)',
                border: OutlineInputBorder(),
              ),
              value: _selectedCategory,
              items: _categoryOptions.map((String category) {
                return DropdownMenuItem<String>(
                  value: category.isNotEmpty ? category : null,
                  child: Text(category.isNotEmpty ? category : 'No Category'),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCategory = newValue;
                });
              },
            ),
            SizedBox(height: 16.0),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    _selectedExpiryDate == null
                        ? 'Select Expiry Date'
                        : 'Expiry Date: ${_selectedExpiryDate!.toLocal().toString().split(' ')[0]}',
                  ),
                ),
                TextButton(
                  onPressed: () => _selectDate(context),
                  child: Text('Select Date'),
                ),
              ],
            ),
            SizedBox(height: 24.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: widget.onCancel, child: Text('Cancel')),
                SizedBox(width: 16.0),
                ElevatedButton(onPressed: _submitForm, child: Text('Update')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}