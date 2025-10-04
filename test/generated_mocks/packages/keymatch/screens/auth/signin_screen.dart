import 'package:flutter/material.dart';
import 'package:key_match/widgets/themed_view.dart';
import 'package:key_match/widgets/themed_text.dart';
import 'package:key_match/services/auth_service.dart';
import 'package:key_match/services/profile_service.dart';
import 'package:key_match/constants/colors.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({Key? key}) : super(key: key);

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showErrorDialog('Please fill in all fields');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('Attempting to sign in...');
      final signInResult = await AuthService.signIn(email, password);
      print('Sign in successful, checking user status...');
      
      // Get user data from the sign in result
      final user = signInResult['user'];
      final isEmailVerified = user['emailVerified'] ?? false;
      
      if (!isEmailVerified) {
        print('Email not verified, redirecting to email verification');
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/email-verification');
        }
        return;
      }
      
      // Email is verified, check if user has a complete profile
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
    } catch (error) {
      print('Sign in error: $error');
      if (mounted) {
        _showErrorDialog(error.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const ThemedText('Sign In Error', type: ThemedTextType.subtitle),
        content: ThemedText(message),
        actions: <Widget>[
          TextButton(
            child: const ThemedText('Okay', type: ThemedTextType.link),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = AppColors.colors[isDark ? 'dark' : 'light']!;

    return Scaffold(
      backgroundColor: colors['background'],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              ThemedText(
                'Welcome Back',
                type: ThemedTextType.title,
                style: TextStyle(
                  color: colors['text'],
                ),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _emailController,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter your email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colors['icon']!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colors['tint']!),
                  ),
                  labelStyle: TextStyle(color: colors['text']),
                  hintStyle: TextStyle(color: colors['icon']),
                ),
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: colors['text']),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _passwordController,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter your password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colors['icon']!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colors['tint']!),
                  ),
                  labelStyle: TextStyle(color: colors['text']),
                  hintStyle: TextStyle(color: colors['icon']),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      color: colors['icon'],
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword,
                style: TextStyle(color: colors['text']),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSignIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors['tint'],
                  foregroundColor: isDark && colors['tint'] == AppColors.tintColorDark 
                      ? colors['background'] 
                      : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3, 
                          color: Colors.white,
                        ),
                      )
                    : const ThemedText(
                        'Sign In', 
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: _isLoading ? null : () {
                  Navigator.pushNamed(context, '/signup');
                },
                child: ThemedText(
                  "Don't have an account? Sign Up",
                  type: ThemedTextType.link,
                  style: TextStyle(color: colors['tint']),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
