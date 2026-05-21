import 'package:flutter/material.dart';

class CategoryProvider extends ChangeNotifier {
  static const List<Map<String, dynamic>> all = [
    {'name': 'All', 'icon': Icons.apps},
    {'name': 'Plumbing', 'icon': Icons.plumbing},
    {'name': 'Electrical', 'icon': Icons.electrical_services},
    {'name': 'Painting', 'icon': Icons.format_paint},
    {'name': 'Cleaning', 'icon': Icons.cleaning_services},
    {'name': 'Carpentry', 'icon': Icons.carpenter},
    {'name': 'Gardening', 'icon': Icons.grass},
    {'name': 'Roofing', 'icon': Icons.roofing},
    {'name': 'Masonry', 'icon': Icons.construction},
  ];

  String? _selected;
  String? get selected => _selected;

  void select(String? category) {
    _selected = category == 'All' ? null : category;
    notifyListeners();
  }

  void clear() {
    _selected = null;
    notifyListeners();
  }
}
