import 'package:flutter/material.dart';
import 'package:key_match/screens/auth/signin_screen.dart';
import 'package:key_match/screens/auth/signup_screen.dart';
import 'package:key_match/screens/auth/email_verification_screen.dart';
import 'package:key_match/screens/tabs/home_tab.dart';
import 'package:key_match/screens/tabs/explore_tab.dart';
import 'package:key_match/screens/tabs/messages_tab.dart';
import 'package:key_match/screens/tabs/profile_tab.dart';
import 'package:key_match/screens/profile_setup_screen.dart';
import 'package:key_match/screens/premium_test_screen.dart';
import 'package:key_match/constants/colors.dart';
import 'package:key_match/services/notification_service.dart';
import 'package:key_match/services/auth_service.dart';
import 'package:key_match/services/profile_service.dart';
import 'package:key_match/services/billing_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize notifications
  await NotificationService.initialize();
  
  // Initialize billing service
  await BillingService.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KeyMatch',
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
        '/email-verification': (context) => const EmailVerificationScreen(email: '', firstName: ''),
        '/home': (context) => const MainTabScreen(),
        '/profile-setup': (context) => const ProfileSetupScreen(),
        '/premium-test': (context) => const PremiumTestScreen(),
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
      
      // Initialize authentication system
      final hasValidSession = await AuthService.initialize();
      
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
              Navigator.pushReplacementNamed(context, '/email-verification');
            }
            return;
          }
          
          // Check if user has a complete profile
          try {
            final profile = await ProfileService.getCompleteProfile();
            print('Complete profile found: ${profile != null}');
            
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/home');
            }
          } catch (e) {
            print('Profile not found or incomplete, redirecting to profile setup');
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/profile-setup');
            }
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

  final List<Widget> _tabs = [
    const HomeTab(),
    const ExploreTab(),
    const MessagesTab(),
    const ProfileTab(),
  ];

  @override
  void initState() {
    super.initState();
    // Initialize WebSocket connection for notifications
    NotificationService.initializeWebSocket();
    
    // Set up periodic session refresh
    _setupSessionRefresh();
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
    // Disconnect WebSocket when leaving the app
    NotificationService.disconnect();
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
