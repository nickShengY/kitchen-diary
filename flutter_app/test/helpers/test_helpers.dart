import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

/// Initialize Hive with a temporary directory for testing.
Future<void> setupHiveForTesting() async {
  final tempDir = await Directory.systemTemp.createTemp('hive_test_');
  Hive.init(tempDir.path);
}

/// Close all Hive boxes and clean up.
Future<void> teardownHive() async {
  await Hive.close();
}
