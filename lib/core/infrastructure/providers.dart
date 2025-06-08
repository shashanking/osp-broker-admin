// External Packages
import 'package:hive_flutter/hive_flutter.dart';

// Core Providers
export 'dio_provider.dart';
export 'hive_provider.dart';
export 'base_api_service.dart';

// Feature Providers
export '../../features/auth/application/auth_notifier.dart';

// Models
export '../../features/auth/domain/auth_state.dart';

// Router
export '../../router/app_router.dart' show AppRoute, routerProvider;

// Initialize all providers
/// Initialize all required services and dependencies
Future<void> initializeProviders() async {
  // Initialize Hive
  await Hive.initFlutter();
  
  // Open required Hive boxes
  await Hive.openBox('auth');
}
