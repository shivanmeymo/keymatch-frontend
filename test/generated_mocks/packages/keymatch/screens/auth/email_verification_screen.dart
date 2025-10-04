import 'package:flutter/material.dart';
import 'dart:async'; // Import for Timer
import '../../services/auth_service.dart';
import '../../constants/colors.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final String firstName;

  const EmailVerificationScreen({
    Key? key,
    required this.email,
    required this.firstName,
  }) : super(key: key);

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isResending = false;
  bool _isVerifying = false;
  bool _codeExpired = false; // New state variable
  final TextEditingController _tokenController = TextEditingController();
  String _email = '';
  String _firstName = '';

  // Timer for code expiration
  Timer? _timer;
  final int _codeExpiryMinutes = 10; // Matches backend expiry

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    // Prioritize the email passed via widget arguments
    if (widget.email.isNotEmpty) {
      setState(() {
        _email = widget.email;
        _firstName = widget.firstName;
      });
      return;
    }

    // If not provided, try to get it from the current user
    try {
      final user = await AuthService.getCurrentUser();
      if (user != null) {
        setState(() {
          _email = user['email'] ?? '';
          _firstName = user['firstName'] ?? '';
        });
      } else {
        // If no user data, navigate back to sign-in
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/signin');
        }
      }
    } catch (error) {
      print('Error loading user data: $error');
      // If an error occurs, navigate back to sign-in
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/signin');
      }
    }
  }

  @override
  @override
  void dispose() {
    _tokenController.dispose();
    _timer?.cancel(); // Safely cancel the timer
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel(); // Safely cancel any existing timer
    _timer = Timer(Duration(minutes: _codeExpiryMinutes), () {
      if (mounted) {
        setState(() {
          _codeExpired = true;
        });
      }
    });
  }

  Future<void> _resendVerificationEmail() async {
    setState(() {
      _isResending = true;
    });

    try {
      final result = await AuthService.resendVerificationEmail(_email);

      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification email sent successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          // Reset timer and code expired state
          setState(() {
            _codeExpired = false;
          });
          _timer?.cancel();
          _startTimer();
        }
      } else {
        // Use the error message from the result
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to resend email: ${result['message'] ?? 'An unknown error occurred.'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to resend email: ${e.toString()}'), // Fallback for unexpected errors
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  Future<void> _verifyEmail() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the verification code'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      final result = await AuthService.verifyEmail(token);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email verified successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate to root to re-evaluate navigation based on updated user data
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Verify Your Email'),
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
              Icons.mark_email_unread_outlined,
              size: 80,
              color: AppColors.primaryGreen,
            ),
            
            const SizedBox(height: 24),
            
            // Title
            Text(
              'Check Your Email',
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
              'Hi ${_firstName}, we\'ve sent a verification link to:',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            // Email
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryGreenLightest),
              ),
              child: Text(
                _email,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryGreen,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryGreenLightest),
              ),
              child: Column(
                children: [
                  Text(
                    'To complete your registration:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInstructionStep('1', 'Check your email inbox'),
                  _buildInstructionStep('2', 'Click the verification link'),
                  _buildInstructionStep('3', 'Or enter the verification code below'),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Verification Code Input
            Text(
              'Verification Code (Optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryLight,
              ),
            ),
            
            const SizedBox(height: 8),
            
            TextField(
              controller: _tokenController,
              enabled: !_codeExpired, // Disable if code expired
              decoration: InputDecoration(
                hintText: _codeExpired ? 'Code expired. Please resend.' : 'Enter verification code from email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primaryGreen, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Verify Button
            ElevatedButton(
              onPressed: _isVerifying || _codeExpired ? null : _verifyEmail, // Disable if code expired
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isVerifying
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _codeExpired ? 'Code Expired - Resend' : 'Verify Email', // Change text if code expired
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
            
            // Display message if code expired
            if (_codeExpired)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  'Your verification code has expired. Please resend a new one.',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            
            const SizedBox(height: 24),
            
            // Divider
            Row(
              children: [
                Expanded(child: Divider(color: AppColors.primaryGreenLightest)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'OR',
                    style: TextStyle(
                      color: AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: AppColors.primaryGreenLightest)),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Resend Button
            OutlinedButton(
              onPressed: _isResending ? null : _resendVerificationEmail,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryGreen,
                side: BorderSide(color: AppColors.primaryGreen),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isResending
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                      ),
                    )
                  : const Text(
                      'Resend Verification Email',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
            
            const SizedBox(height: 24),
            
            // Back to Login
            TextButton(
              onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
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

  Widget _buildInstructionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 