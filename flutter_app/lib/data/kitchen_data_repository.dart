import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;


class KitchenDataRepository {
  KitchenDataRepository._({
    required this.rawData,
    required this.ingredients,
    required this.tools,
    required this.actions,
    required this.temperatures,
    required this.times,
    required this.waterLevels,
    required this.cuisineCategories,
  });

  static KitchenDataRepository? _instance;

  final Map<String, dynamic> rawData;
  final List<Map<String, dynamic>> ingredients;
  final List<Map<String, dynamic>> tools;
  final List<Map<String, dynamic>> actions;
  final List<String> temperatures;
  final List<String> times;
  final List<String> waterLevels;
  final List<Map<String, dynamic>> cuisineCategories;

  static Future<KitchenDataRepository> load() async {
    if (_instance != null) return _instance!;

    try {
      final jsonStr =
          await rootBundle.loadString('assets/data/kitchen_data.json');
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      _instance = KitchenDataRepository._(
        rawData: data,
        ingredients: List<Map<String, dynamic>>.from(
            data['ingredients'] as List? ?? const []),
        tools:
            List<Map<String, dynamic>>.from(data['tools'] as List? ?? const []),
        actions: List<Map<String, dynamic>>.from(
            data['actions'] as List? ?? const []),
        temperatures: List<String>.from(
            data['temperatures'] as List? ?? const ['Low', 'Medium', 'High']),
        times: List<String>.from(
            data['times'] as List? ?? const ['1 min', '5 mins', '10 mins']),
        waterLevels: List<String>.from(
            data['waterLevels'] as List? ?? const ['Splash', '1 cup', 'Covered']),
        cuisineCategories: List<Map<String, dynamic>>.from(
          data['cuisineCategories'] as List? ?? const [],
        ),
      );
    } catch (_) {
      _instance = KitchenDataRepository._(
        rawData: const {},
        ingredients: const [],
        tools: const [],
        actions: const [],
        temperatures: const ['Low', 'Medium', 'High'],
        times: const ['1 min', '5 mins', '10 mins'],
        waterLevels: const ['Splash', '1 cup', 'Covered'],
        cuisineCategories: const [],
      );
    }

    return _instance!;
  }
}
