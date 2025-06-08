import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authBoxProvider = FutureProvider<Box>((ref) async {
  if (!Hive.isBoxOpen('auth')) {
    return await Hive.openBox('auth');
  }
  return Hive.box('auth');
});
