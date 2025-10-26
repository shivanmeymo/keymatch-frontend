import 'package:flutter/material.dart';
import 'package:key_match/screens/auth/signin_screen.dart';
import 'package:key_match/screens/auth/signup_screen.dart';
import 'package:key_match/screens/auth/email_verification_screen.dart';
import 'package:key_match/screens/auth/forgot_password_screen.dart';
import 'package:key_match/screens/auth/reset_password_screen.dart';
import 'package:key_match/screens/tabs/home_tab.dart';
import 'package:key_match/screens/tabs/explore_tab.dart';
import 'package:key_match/screens/tabs/messages_tab.dart';
import 'package:key_match/screens/tabs/profile_tab.dart';
import 'package:key_match/screens/profile_setup_screen.dart';
import 'package:key_match/screens/premium_test_screen.dart';
import 'package:key_match/screens/debug_screen.dart';
import 'package:key_match/constants/colors.dart';
import 'package:key_match/services/notification_service.dart';
import 'package:key_match/services/auth_service.dart';
import 'package:key_match/services/profile_service.dart';
import 'package:key_match/services/billing_service.dart';
import 'package:key_match/services/premium_service.dart';
import 'package:key_match/services/unified_payment_service.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:key_match/constants/api_config.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();
      print('✅ Firebase initialized successfully');
    } catch (e) {
      print('❌ Firebase initialization error: $e');
      // Continue without Firebase if it fails
    }
  }
  
  // Initialize notifications (includes FCM)
  await NotificationService.initialize();
  
  // Initialize unified payment service (handles both Play Store and F-Droid)
  await UnifiedPaymentService.initialize();
  
  // Initialize Stripe only on mobile platforms
  if (!kIsWeb) {
    try {
      Stripe.publishableKey = ApiConfig.stripePublishableKey;
      await Stripe.instance.applySettings();
    } catch (e) {
      print('Stripe initialization error: $e');
      // Continue without Stripe if it fails
    }
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Key Match',
      theme: ThemeData(
        colorScheme: AppColors.getColorScheme(Brightness.light),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primaryGreen),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.accentGreen, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          fillColor: AppColors.surfaceLight,
          filled: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 2,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primaryGreen,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryGreen,
            side: const BorderSide(color: AppColors.primaryGreen),
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.accentGreen,
          foregroundColor: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: AppColors.primaryGreen,
          unselectedItemColor: AppColors.textSecondaryLight,
          backgroundColor: AppColors.surfaceLight,
        ),
        cardTheme: CardThemeData(
          color: AppColors.surfaceLight,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.primaryGreenLightest,
          selectedColor: AppColors.accentGreen,
          labelStyle: const TextStyle(color: AppColors.textPrimaryLight),
        ),
        datePickerTheme: DatePickerThemeData(
          backgroundColor: AppColors.primaryGreen,
          headerBackgroundColor: AppColors.primaryGreen,
          headerForegroundColor: Colors.white,
          dayForegroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return Colors.white;
            }
            return Colors.white;
          }),
          dayBackgroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return Colors.white.withOpacity(0.3);
            }
            return Colors.transparent;
          }),
          todayBackgroundColor: MaterialStateProperty.all(Colors.white.withOpacity(0.2)),
          todayForegroundColor: MaterialStateProperty.all(Colors.white),
          confirmButtonStyle: TextButton.styleFrom(
            foregroundColor: Colors.white,
          ),
          cancelButtonStyle: TextButton.styleFrom(
            foregroundColor: Colors.white,
          ),
        ),
        timePickerTheme: TimePickerThemeData(
          backgroundColor: AppColors.primaryGreen,
          dialBackgroundColor: Colors.white.withOpacity(0.2),
          dialHandColor: Colors.white,
          dialTextColor: MaterialStateColor.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return AppColors.primaryGreen;
            }
            return Colors.white;
          }),
          hourMinuteTextColor: Colors.white,
          dayPeriodTextColor: Colors.white,
          entryModeIconColor: Colors.white,
          confirmButtonStyle: TextButton.styleFrom(
            foregroundColor: Colors.white,
          ),
          cancelButtonStyle: TextButton.styleFrom(
            foregroundColor: Colors.white,
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: AppColors.getColorScheme(Brightness.dark),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primaryGreenLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.accentGreenLight, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          fillColor: AppColors.surfaceDark,
          filled: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreenLight,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 2,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primaryGreenLight,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryGreenLight,
            side: const BorderSide(color: AppColors.primaryGreenLight),
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.accentGreenLight,
          foregroundColor: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primaryGreenLight,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: AppColors.primaryGreenLight,
          unselectedItemColor: AppColors.textSecondaryDark,
          backgroundColor: AppColors.surfaceDark,
        ),
        cardTheme: CardThemeData(
          color: AppColors.surfaceDark,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.primaryGreen,
          selectedColor: AppColors.accentGreenLight,
          labelStyle: const TextStyle(color: AppColors.textPrimaryDark),
        ),
      ),
      home: const SplashScreen(),
      routes: {
        '/signin': (context) => const SignInScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => const MainTabScreen(),
        '/profile-setup': (context) => const ProfileSetupScreen(),
        '/premium-test': (context) => const PremiumTestScreen(),
        '/debug': (context) => const DebugScreen(),
        '/email-verification': (context) => EmailVerificationScreen(
          email: '',
          firstName: '',
        ),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/reset-password': (context) => const ResetPasswordScreen(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      print('=== DEBUG: App initialization started ===');
      
      // Check network connectivity first (disabled - not needed for VPS backend)
      // try {
      //   final result = await http.get(Uri.parse('https://www.google.com'));
      //   if (result.statusCode == 200) {
      //     print('Network connectivity: OK');
      //   }
      // } catch (e) {
      //   print('Network connectivity: FAILED - $e');
      //   // Continue anyway, but this might explain backend issues
      // }
      
      // Initialize authentication system with shorter timeout
      final hasValidSession = await AuthService.initialize()
          .timeout(const Duration(seconds: 10), onTimeout: () {
        print('App initialization timeout, redirecting to sign in');
        throw Exception('Initialization timeout');
      });
      
      if (hasValidSession) {
        print('Valid session found, checking user status...');
        
        // Get current user to check email verification status
        final user = await AuthService.getCurrentUser();
        
        if (user != null) {
          // Check if email is verified
          final isEmailVerified = user['emailVerified'] ?? false;
          
          if (!isEmailVerified) {
            print('Email not verified, redirecting to email verification');
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => EmailVerificationScreen(
                    email: user['email'] ?? '',
                    firstName: user['firstName'] ?? '',
                  ),
                ),
              );
            }
            return;
          }
          
          // Check if user has a complete profile
          try {
            final profile = await ProfileService.getCompleteProfile();
            
            if (profile != null) {
              print('User authenticated and profile complete, redirecting to main app');
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/home');
              }
            } else {
              print('No complete profile found, redirecting to profile setup');
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/profile-setup');
              }
            }
          } catch (e) {
            print('Profile check error: $e');
            
            // Check if this is a profile incompleteness error
            if (e.toString().contains('Profile incomplete')) {
              print('Profile incomplete, redirecting to profile setup');
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/profile-setup');
              }
              return;
            }
            
            // For other errors (network, auth), redirect to sign in
            print('Profile check failed with error, redirecting to sign in');
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/signin');
            }
            return;
          }
        } else {
          print('No user data found, redirecting to sign in');
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/signin');
          }
        }
      } else {
        print('No valid session found, redirecting to sign in');
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/signin');
        }
      }
    } catch (e) {
      print('App initialization error: $e');
      
      // Check if this is a user not found error
      if (e.toString().contains('User not found') || 
          e.toString().contains('USER_NOT_FOUND')) {
        print('User not found in database, clearing invalid tokens');
        await AuthService.handleInvalidToken();
      }
      
      // Always redirect to sign in on any error
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/signin');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo or icon
            Icon(
              Icons.favorite,
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(height: 24),
            
            // App name
            const Text(
              'KeyMatch',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(height: 48),
            
            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            
            const SizedBox(height: 24),
            
            // Loading text
            const Text(
              'Loading...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MainTabScreen extends StatefulWidget {
  const MainTabScreen({Key? key}) : super(key: key);

  @override
  _MainTabScreenState createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  int _currentIndex = 0;

  // Define a type for the callback
  // typedef NavigateToTabCallback = void Function(int index); // Not strictly necessary to define type here

  // Method to change the tab
  void _navigateToTab(int index) {
    if (index >= 0 && index < _tabs.length) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  // Updated list of tabs that will receive the callback
  // Note: The individual tab files (HomeTab, ExploreTab, etc.) will need to be updated
  // to accept this callback in their constructors.
  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();

    print('=== DEBUG: MainTabScreen.initState started ===');
    
    try {
      // Initialize _tabs here where _navigateToTab is available
      _tabs = [
        HomeTab(navigateToTab: _navigateToTab),
        ExploreTab(navigateToTab: _navigateToTab),
        MessagesTab(navigateToTab: _navigateToTab),
        ProfileTab(navigateToTab: _navigateToTab),
      ];
      print('=== DEBUG: MainTabScreen tabs initialized successfully ===');

      // Register FCM token if not already registered (don't await - let it run in background)
      NotificationService.registerFCMTokenAfterLogin().then((_) {
        print('=== DEBUG: FCM token registration attempted ===');
      }).catchError((e) {
        print('=== DEBUG: FCM token registration failed: $e ===');
      });

      // WebSocket removed - using FCM for push notifications instead
      
      // Set up periodic session refresh
      _setupSessionRefresh();
      print('=== DEBUG: Session refresh setup complete ===');
    } catch (e) {
      print('=== DEBUG: MainTabScreen initialization error: $e ===');
      rethrow;
    }
  }

  void _setupSessionRefresh() {
    // Refresh session every 6 hours to keep it alive
    Future.delayed(const Duration(hours: 6), () async {
      if (mounted) {
        await AuthService.refreshSessionIfNeeded();
        _setupSessionRefresh(); // Schedule next refresh
      }
    });
  }

  @override
  void dispose() {
    // WebSocket removed - using FCM for push notifications instead
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: AppColors.activeTabYellow,
        unselectedItemColor: AppColors.textSecondaryLight,
        backgroundColor: AppColors.surfaceLight,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
