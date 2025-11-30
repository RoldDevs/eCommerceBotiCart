import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:boticart/core/theme/app_theme.dart';
import 'package:boticart/features/splash/presentation/screens/splash_screen.dart';
import 'package:boticart/firebase_options.dart';
import 'package:boticart/features/helpchat/data/repositories/help_chat_repository_impl.dart';
import 'package:boticart/features/auth/data/services/persistent_auth_service.dart';
import 'package:boticart/features/pharmacy/presentation/screens/orders_screen.dart';
import 'package:boticart/features/pharmacy/presentation/providers/order_status_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Check if user is already logged in
  final isLoggedIn = await PersistentAuthService.getLoginState();
  if (isLoggedIn && FirebaseAuth.instance.currentUser == null) {
    await PersistentAuthService.clearLoginState();
  }

  WidgetsBinding.instance.addObserver(AppLifecycleObserver());

  runApp(const ProviderScope(child: MyApp()));
}

class AppLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      // App is being terminated
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Clear chat history
        final repository = HelpChatRepositoryImpl();
        repository.clearChatHistory(currentUser.uid);
      }
      // We no longer sign out the user when the app is closed
    }
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize the order status listener
    ref.watch(orderStatusInitializerProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: MaterialApp(
        title: 'BotiCart',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme.copyWith(
          snackBarTheme: SnackBarThemeData(
            backgroundColor: AppTheme.primaryColor,
            contentTextStyle: TextStyle(
              fontFamily: AppTheme.lightTheme.textTheme.bodyMedium?.fontFamily,
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            actionTextColor: Colors.white,
          ),
        ),
        home: const SplashScreen(),
        routes: {'/orders': (context) => const OrdersScreen()},
        onGenerateRoute: (settings) {
          if (settings.name == '/orders') {
            return MaterialPageRoute(
              builder: (context) => const OrdersScreen(),
            );
          }
          return null;
        },
      ),
    );
  }
}
