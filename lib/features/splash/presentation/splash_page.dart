import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:osp_broker_admin/features/auth/application/auth_notifier.dart';
import 'package:osp_broker_admin/features/auth/domain/auth_state.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  bool _minSplashTimePassed = false;
  static const _minSplashDuration = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSplashTimer();
    });
  }

  void _startSplashTimer() {
    Timer(_minSplashDuration, () {
      if (mounted) {
        setState(() {
          _minSplashTimePassed = true;
        });
      }
    });
  }

  void _checkAuthState() {
    if (!mounted) return;

    final authState = ref.read(authNotifierProvider);
    authState.maybeWhen(
      authenticated: (token, user) => _navigateToDashboard(),
      unauthenticated: () => _navigateToLogin(),
      error: (message) {
        debugPrint('Auth error: $message');
        _navigateToLogin();
      },
      orElse: () {},
    );
  }

  void _navigateToDashboard() {
    if (!mounted) return;

    final context = this.context;
    final currentPath = GoRouterState.of(context).uri.path;
    if (currentPath != '/dashboard') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/dashboard');
        }
      });
    }
  }

  void _navigateToLogin() {
    if (!mounted) return;

    final context = this.context;
    final currentPath = GoRouterState.of(context).uri.path;
    if (currentPath != '/login') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/login');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth state changes
    ref.listen<AuthState>(
      authNotifierProvider,
      (_, next) {
        next.maybeWhen(
          authenticated: (token, user) => _navigateToDashboard(),
          unauthenticated: () => _navigateToLogin(),
          error: (message) {
            debugPrint('Auth error: $message');
            _navigateToLogin();
          },
          orElse: () {},
        );
      },
    );

    // Check auth state if we haven't navigated yet
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthState();
    });

    final authState = ref.watch(authNotifierProvider);
    Widget content;

    final isInitialLoading = authState.maybeWhen(
      loading: () => true,
      initial: () => true,
      orElse: () => false,
    );

    // Only show loading state if we're still within min splash time or still loading
    if (isInitialLoading || !_minSplashTimePassed) {
      // Show loading indicator and animated text
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/osp-logo.png',
            width: 200,
            height: 200,
          ),
          const SizedBox(height: 32),
          const CircularProgressIndicator(color: Colors.white),
          const SizedBox(height: 16),
          DefaultTextStyle(
            style: const TextStyle(
              fontSize: 18.0,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
            child: AnimatedTextKit(
              animatedTexts: [
                TypewriterAnimatedText(
                  'Initializing...',
                  speed: const Duration(milliseconds: 100),
                ),
                TypewriterAnimatedText(
                  'Loading your dashboard...',
                  speed: const Duration(milliseconds: 100),
                ),
              ],
              repeatForever: true,
              pause: const Duration(seconds: 2),
              displayFullTextOnTap: true,
            ),
          ),
        ],
      );
    } else if (authState.maybeWhen(error: (msg) => true, orElse: () => false)) {
      // Show error message
      final message =
          authState.maybeWhen(error: (msg) => msg, orElse: () => '');
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/osp-logo.png',
            width: 200,
            height: 200,
          ),
          const SizedBox(height: 32),
          Icon(Icons.error, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: Colors.white, fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ],
      );
    } else {
      // Default splash
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/osp-logo.png',
            width: 200,
            height: 200,
          ),
          const SizedBox(height: 32),
          const Text(
            'Welcome to OSP Broker Admin',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(child: content),
    );
  }
}
