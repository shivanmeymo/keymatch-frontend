import 'package:flutter/material.dart';
import 'package:key_match/widgets/themed_view.dart';
import 'package:key_match/widgets/themed_text.dart';
import 'package:key_match/services/auth_service.dart';
import 'package:key_match/services/profile_service.dart';
import 'package:key_match/constants/colors.dart';
import 'email_verification_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text;
    final String confirmPassword = _confirmPasswordController.text;
    final String firstName = _firstNameController.text.trim();
    final String lastName = _lastNameController.text.trim();

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty || 
        firstName.isEmpty || lastName.isEmpty) {
      _showErrorDialog('Please fill in all fields');
      return;
    }

    if (password != confirmPassword) {
      _showErrorDialog('Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('Starting signup process...');
      final result = await AuthService.signUp(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );
      
      print('Signup successful, navigating to email verification...');
      
      // Navigate to email verification screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => EmailVerificationScreen(
              email: email,
              firstName: firstName,
            ),
          ),
        );
      }
    } catch (error) {
      print('Sign up error: $error');
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
        title: const ThemedText('Sign Up Error', type: ThemedTextType.subtitle),
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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: 50),
                ThemedText(
                  'Create Account',
                  type: ThemedTextType.title,
                  style: TextStyle(
                    color: colors['text'],
                  ),
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: _firstNameController,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: 'First Name',
                    hintText: 'Enter your first name',
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
                  style: TextStyle(color: colors['text']),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _lastNameController,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: 'Last Name',
                    hintText: 'Enter your last name',
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
                  style: TextStyle(color: colors['text']),
                ),
                const SizedBox(height: 15),
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
                const SizedBox(height: 15),
                TextField(
                  controller: _confirmPasswordController,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    hintText: 'Confirm your password',
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
                        _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                        color: colors['icon'],
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscureConfirmPassword,
                  style: TextStyle(color: colors['text']),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignUp,
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
                          'Sign Up', 
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: _isLoading ? null : () {
                    Navigator.pushReplacementNamed(context, '/signin');
                  },
                  child: ThemedText(
                    "Already have an account? Sign In",
                    type: ThemedTextType.link,
                    style: TextStyle(color: colors['tint']),
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
