import 'package:flutter/material.dart';
import 'package:everypay/domain/entities/category.dart';

/// Maps category icon string names to Material Icons.
IconData categoryIcon(String iconName) {
  return switch (iconName) {
    'play_circle' => Icons.play_circle,
    'bolt' => Icons.bolt,
    'security' => Icons.security,
    'cloud' => Icons.cloud,
    'favorite' => Icons.favorite,
    'account_balance' => Icons.account_balance,
    'shopping_cart' => Icons.shopping_cart,
    'school' => Icons.school,
    'directions_car' => Icons.directions_car,
    'category' => Icons.category,
    _ => Icons.category,
  };
}

/// Parses a hex colour string (#RRGGBB) to a Color.
Color categoryColor(String hex) {
  final hexCode = hex.replaceAll('#', '');
  return Color(int.parse('FF$hexCode', radix: 16));
}

final defaultCategories = <Category>[
  Category(
    id: 'cat-entertainment',
    name: 'Entertainment & Streaming',
    icon: 'play_circle',
    colour: '#E53935',
    isDefault: true,
    sortOrder: 0,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  ),
  Category(
    id: 'cat-utilities',
    name: 'Utilities & Bills',
    icon: 'bolt',
    colour: '#1E88E5',
    isDefault: true,
    sortOrder: 1,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  ),
  Category(
    id: 'cat-insurance',
    name: 'Insurance',
    icon: 'security',
    colour: '#43A047',
    isDefault: true,
    sortOrder: 2,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  ),
  Category(
    id: 'cat-software',
    name: 'Software & Cloud',
    icon: 'cloud',
    colour: '#8E24AA',
    isDefault: true,
    sortOrder: 3,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  ),
  Category(
    id: 'cat-health',
    name: 'Health & Fitness',
    icon: 'favorite',
    colour: '#F4511E',
    isDefault: true,
    sortOrder: 4,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  ),
  Category(
    id: 'cat-finance',
    name: 'Finance & Banking',
    icon: 'account_balance',
    colour: '#00897B',
    isDefault: true,
    sortOrder: 5,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  ),
  Category(
    id: 'cat-food',
    name: 'Food & Groceries',
    icon: 'shopping_cart',
    colour: '#FB8C00',
    isDefault: true,
    sortOrder: 6,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  ),
  Category(
    id: 'cat-education',
    name: 'Education',
    icon: 'school',
    colour: '#3949AB',
    isDefault: true,
    sortOrder: 7,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  ),
  Category(
    id: 'cat-transport',
    name: 'Transportation',
    icon: 'directions_car',
    colour: '#757575',
    isDefault: true,
    sortOrder: 8,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  ),
  Category(
    id: 'cat-other',
    name: 'Other',
    icon: 'category',
    colour: '#546E7A',
    isDefault: true,
    sortOrder: 9,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  ),
];
