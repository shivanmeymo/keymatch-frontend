import 'package:flutter/material.dart';
import 'package:key_match/services/auth_service.dart';
import 'package:key_match/constants/colors.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _requestPasswordReset() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showErrorDialog('Please enter your email address.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AuthService.requestPasswordReset(email);

      if (result['success'] == true) {
        setState(() {
          _emailSent = true;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Password reset email sent successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          _showErrorDialog(result['message'] ?? 'Failed to send password reset email.');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Network error. Please check your internet connection and try again.');
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
        title: const Text('Error'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
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
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Forgot Password'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            
            // Icon
            Icon(
              Icons.lock_reset,
              size: 80,
              color: AppColors.primaryGreen,
            ),
            
            const SizedBox(height: 24),
            
            // Title
            Text(
              'Reset Your Password',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            // Message
            Text(
              'Enter your email address and we\'ll send you a link to reset your password.',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            // Email field
            TextFormField(
              controller: _emailController,
              enabled: !_isLoading && !_emailSent,
              decoration: InputDecoration(
                labelText: 'Email Address',
                hintText: 'Enter your email address',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primaryGreenLightest),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primaryGreenLightest),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primaryGreen, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                prefixIcon: Icon(Icons.email, color: AppColors.primaryGreen),
                labelStyle: TextStyle(color: AppColors.textSecondaryLight),
                hintStyle: TextStyle(color: AppColors.textSecondaryLight.withOpacity(0.7)),
              ),
              style: TextStyle(
                color: AppColors.textPrimaryLight,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            
            const SizedBox(height: 24),
            
            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading || _emailSent ? null : _requestPasswordReset,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        _emailSent ? 'Email Sent!' : 'Send Reset Link',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            
            if (_emailSent) ...[
              const SizedBox(height: 24),
              
              // Success message
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Check Your Email',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We\'ve sent a password reset link to your email address. Please check your inbox and spam folder.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Back to login
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Back to Login',
                style: TextStyle(
                  color: AppColors.primaryGreen,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 