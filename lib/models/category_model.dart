import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String name;
  final String icon;
  final String description;
  final Color color;
  final int jobCount;
  final bool isActive;

  CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.color,
    this.jobCount = 0,
    this.isActive = true,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      description: json['description'] as String,
      color: Color(json['color'] as int),
      jobCount: json['jobCount'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'description': description,
      'color': color.value,
      'jobCount': jobCount,
      'isActive': isActive,
    };
  }

  // Predefined categories
  static List<CategoryModel> getPredefinedCategories() {
    return [
      CategoryModel(
        id: '1',
        name: 'Plumbing',
        icon: '🔧',
        description: 'Pipe fixing, leak repairs, installations',
        color: Colors.blue,
      ),
      CategoryModel(
        id: '2',
        name: 'Electrical',
        icon: '⚡',
        description: 'Wiring, installations, repairs',
        color: Colors.amber,
      ),
      CategoryModel(
        id: '3',
        name: 'Painting',
        icon: '🎨',
        description: 'Interior and exterior painting',
        color: Colors.purple,
      ),
      CategoryModel(
        id: '4',
        name: 'Carpentry',
        icon: '🪵',
        description: 'Furniture, cabinets, repairs',
        color: Colors.brown,
      ),
      CategoryModel(
        id: '5',
        name: 'Welding',
        icon: '🔥',
        description: 'Metal work, gates, frames',
        color: Colors.grey,
      ),
      CategoryModel(
        id: '6',
        name: 'Landscaping',
        icon: '🌿',
        description: 'Gardening, lawn care, trees',
        color: Colors.green,
      ),
      CategoryModel(
        id: '7',
        name: 'Cleaning',
        icon: '🧹',
        description: 'House, office, deep cleaning',
        color: Colors.cyan,
      ),
      CategoryModel(
        id: '8',
        name: 'Appliance',
        icon: '📺',
        description: 'TV, fridge, washing machine repair',
        color: Colors.red,
      ),
    ];
  }
}