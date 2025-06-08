import 'package:hive_flutter/hive_flutter.dart';

Future<Box> openAuthBox() async {
  await Hive.initFlutter();
  return await Hive.openBox('auth_box');
}
