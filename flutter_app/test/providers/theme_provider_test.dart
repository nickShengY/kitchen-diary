import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:kitchen_diary/providers/theme_provider.dart';

void main() {
  late ThemeProvider provider;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_theme_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Future<ThemeProvider> createProvider() async {
    final p = ThemeProvider();
    await Future.delayed(const Duration(milliseconds: 200));
    return p;
  }

  group('ThemeProvider initialization', () {
    test('defaults to light mode', () async {
      provider = await createProvider();
      expect(provider.themeMode, ThemeMode.light);
      expect(provider.isDarkMode, false);
      expect(provider.isInitialized, true);
    });
  });

  group('toggleTheme', () {
    test('switches from light to dark', () async {
      provider = await createProvider();
      await provider.toggleTheme();
      expect(provider.themeMode, ThemeMode.dark);
      expect(provider.isDarkMode, true);
    });

    test('switches from dark back to light', () async {
      provider = await createProvider();
      await provider.toggleTheme(); // light -> dark
      await provider.toggleTheme(); // dark -> light
      expect(provider.themeMode, ThemeMode.light);
      expect(provider.isDarkMode, false);
    });

    test('multiple toggles alternate correctly', () async {
      provider = await createProvider();
      for (int i = 0; i < 5; i++) {
        await provider.toggleTheme();
      }
      // 5 toggles from light: dark, light, dark, light, dark
      expect(provider.themeMode, ThemeMode.dark);
    });
  });

  group('setThemeMode', () {
    test('sets dark mode directly', () async {
      provider = await createProvider();
      await provider.setThemeMode(ThemeMode.dark);
      expect(provider.themeMode, ThemeMode.dark);
    });

    test('sets light mode directly', () async {
      provider = await createProvider();
      await provider.setThemeMode(ThemeMode.dark);
      await provider.setThemeMode(ThemeMode.light);
      expect(provider.themeMode, ThemeMode.light);
    });

    test('sets system mode', () async {
      provider = await createProvider();
      await provider.setThemeMode(ThemeMode.system);
      // Note: internally the provider only saves 'dark'/'light',
      // so system mode would be stored as light
      expect(provider.themeMode, ThemeMode.system);
    });
  });

  group('persistence', () {
    test('dark mode persists across instances', () async {
      provider = await createProvider();
      await provider.toggleTheme(); // switch to dark

      final provider2 = ThemeProvider();
      await Future.delayed(const Duration(milliseconds: 200));
      expect(provider2.themeMode, ThemeMode.dark);
    });

    test('light mode persists across instances', () async {
      provider = await createProvider();
      await provider.toggleTheme(); // dark
      await provider.toggleTheme(); // light

      final provider2 = ThemeProvider();
      await Future.delayed(const Duration(milliseconds: 200));
      expect(provider2.themeMode, ThemeMode.light);
    });
  });
}
