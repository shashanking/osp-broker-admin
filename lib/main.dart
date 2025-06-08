import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Added for Hive.initFlutter
import 'package:osp_broker_admin/core/infrastructure/providers.dart';

Future<void> main() async {
  print('main(): Starting app initialization');
  WidgetsFlutterBinding.ensureInitialized();

  ProviderContainer? container;
  
  try {
    print('main(): Initializing Hive...');
    await Hive.initFlutter();
    print('main(): Hive initialized');

    // Create a ProviderContainer to manage provider lifecycles during initialization
    print('main(): Creating ProviderContainer');
    container = ProviderContainer();

    // Ensure the auth box is open and ready before BaseApiService tries to use it
    print('main(): Opening auth box...');
    final authBox = await container.read(authBoxProvider.future);
    print('main(): Auth box opened: ${authBox.isOpen}');

    // Initialize BaseApiService
    print('main(): Initializing BaseApiService...');
    final apiService = container.read(baseApiServiceProvider);
    print('main(): BaseApiService initialized. Has token: ${apiService.authToken != null}');

    // Eagerly initialize AuthNotifier to trigger _checkAuthStatus
    print('main(): Initializing AuthNotifier...');
    container.read(authNotifierProvider.notifier);
    print('main(): AuthNotifier initialized');

    runApp(
      UncontrolledProviderScope(
        container: container,
        child: const MyApp(),
      ),
    );
  } catch (e, stackTrace) {
    print('main(): Error during initialization: $e');
    print('Stack trace: $stackTrace');
    rethrow;
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone 13 dimensions
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return MaterialApp.router(
          title: 'OSP Broker Admin',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            textTheme: GoogleFonts.montserratTextTheme(
              Theme.of(context).textTheme,
            ),
            primaryTextTheme: GoogleFonts.montserratTextTheme(
              Theme.of(context).primaryTextTheme,
            ),
            iconTheme: IconThemeData(
              color: Colors.grey[800],
            ),
            appBarTheme: AppBarTheme(
              elevation: 0,
              centerTitle: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              iconTheme: const IconThemeData(color: Colors.black87),
              titleTextStyle: GoogleFonts.montserrat(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            cardTheme: CardTheme(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0A6BFF),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            textTheme: GoogleFonts.montserratTextTheme(
              Theme.of(context).textTheme.apply(
                    bodyColor: Colors.white,
                    displayColor: Colors.white,
                  ),
            ),
            appBarTheme: AppBarTheme(
              elevation: 0,
              centerTitle: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              iconTheme: const IconThemeData(color: Colors.white70),
              titleTextStyle: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            cardTheme: CardTheme(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Colors.grey.shade800,
                  width: 1,
                ),
              ),
            ),
          ),
          themeMode: ThemeMode.system,
          routerConfig: router,
        );
      },
    );
  }
}
