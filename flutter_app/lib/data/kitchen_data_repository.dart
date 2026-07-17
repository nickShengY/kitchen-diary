import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'kitchen_data.dart';
import 'visual_catalog.dart';

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
      final ingredients = _mergeById(
        List<Map<String, dynamic>>.from(
            data['ingredients'] as List? ?? const []),
        _mergeById(List<Map<String, dynamic>>.from(VisualCatalog.ingredients), KitchenData.ingredients),
      );
      final tools = _mergeById(
        List<Map<String, dynamic>>.from(data['tools'] as List? ?? const []),
        _mergeById(List<Map<String, dynamic>>.from(VisualCatalog.tools), KitchenData.tools),
      );
      final actions = _mergeById(
        List<Map<String, dynamic>>.from(data['actions'] as List? ?? const []),
        _mergeById(List<Map<String, dynamic>>.from(VisualCatalog.actions), KitchenData.actions),
      );
      final cuisines = _mergeById(
        List<Map<String, dynamic>>.from(
          data['cuisineCategories'] as List? ?? const [],
        ),
        KitchenData.cuisineCategories,
      );

      _instance = KitchenDataRepository._(
        rawData: {
          ...KitchenData.fallbackRawData,
          ...data,
          'ingredients': ingredients,
          'tools': tools,
          'actions': actions,
          'cuisineCategories': cuisines,
        },
        ingredients: ingredients,
        tools: tools,
        actions: actions,
        temperatures: List<String>.from(
          data['temperatures'] as List? ?? KitchenData.temperatures,
        ),
        times: List<String>.from(
          data['times'] as List? ?? KitchenData.times,
        ),
        waterLevels: List<String>.from(
          data['waterLevels'] as List? ?? KitchenData.waterLevels,
        ),
        cuisineCategories: cuisines,
      );
    } catch (_) {
      _instance = KitchenDataRepository._(
        rawData: KitchenData.fallbackRawData,
        ingredients: _mergeById(List<Map<String, dynamic>>.from(VisualCatalog.ingredients), KitchenData.ingredients),
        tools: _mergeById(List<Map<String, dynamic>>.from(VisualCatalog.tools), KitchenData.tools),
        actions: _mergeById(List<Map<String, dynamic>>.from(VisualCatalog.actions), KitchenData.actions),
        temperatures: KitchenData.temperatures,
        times: KitchenData.times,
        waterLevels: KitchenData.waterLevels,
        cuisineCategories: KitchenData.cuisineCategories,
      );
    }

    return _instance!;
  }

  static List<Map<String, dynamic>> _mergeById(
    List<Map<String, dynamic>> primary,
    List<Map<String, dynamic>> fallback,
  ) {
    final merged = <String, Map<String, dynamic>>{};

    for (final item in primary) {
      final id = item['id'];
      if (id is String && id.isNotEmpty) {
        merged[id] = Map<String, dynamic>.from(item);
      }
    }

    for (final item in fallback) {
      final id = item['id'];
      if (id is String && id.isNotEmpty) {
        merged.putIfAbsent(id, () => Map<String, dynamic>.from(item));
      }
    }

    return merged.values.toList(growable: false);
  }
}
