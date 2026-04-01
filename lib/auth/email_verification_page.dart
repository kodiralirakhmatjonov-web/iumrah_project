import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:iumrah_project/core/navigation/premium_route.dart';

/// ЗАМЕНИ на свою страницу
import 'package:iumrah_project/home/umrah_start..dart';

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  final supabase = Supabase.instance.client;

  bool _isSending = false;
  bool _checking = false;
  bool _isVerified = false;

  String _email = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final user = supabase.auth.currentUser;

    if (user == null) return;

    _email = user.email ?? '';

    final verified = user.emailConfirmedAt != null;

    setState(() {
      _isVerified = verified;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('email_verified_cached', verified);
  }

  Future<void> _sendVerification() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _isSending = true);

    try {
      await supabase.auth.resend(
        type: OtpType.signup,
        email: user.email!,
        emailRedirectTo: 'iumrah://auth',
      );

      _showSnack('Email sent');
    } catch (e) {
      _showSnack('Error sending email');
    }

    setState(() => _isSending = false);
  }

  Future<void> _checkVerification() async {
    setState(() => _checking = true);

    try {
      final res = await supabase.auth.refreshSession();

      final user = res.user;

      final verified = user?.emailConfirmedAt != null;

      if (verified) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('email_verified_cached', true);

        setState(() {
          _isVerified = true;
        });

        _showSnack('Email verified');

        await Future.delayed(const Duration(milliseconds: 600));

        _goNext();
      } else {
        _showSnack('Not verified yet');
      }
    } catch (e) {
      _showSnack('Error checking status');
    }

    setState(() => _checking = false);
  }

  void _goNext() {
    Navigator.of(context).pushAndRemoveUntil(
      PremiumRoute.push(const UmrahStartPage()),
      (route) => false,
    );
  }

  void _skip() {
    _goNext();
  }

  void _showSnack(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Colors.black87;
    final secondary = Colors.grey;

    return Scaffold(
      backgroundColor: const Color(0xFFE6E6EF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // TITLE
              Text(
                'Verify your email',
                textAlign: TextAlign.start,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                _email,
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontSize: 14,
                  color: secondary,
                ),
              ),

              const SizedBox(height: 40),

              // STATUS
              Container(
                padding: const EdgeInsetsDirectional.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isVerified
                          ? Icons.verified_rounded
                          : Icons.error_outline_rounded,
                      color: _isVerified ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _isVerified ? 'Verified' : 'Not verified',
                      style: TextStyle(
                        fontSize: 14,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // SEND BUTTON
              _PrimaryButton(
                text: _isSending ? 'Sending...' : 'Send verification email',
                onTap: _isSending ? null : _sendVerification,
              ),

              const SizedBox(height: 12),

              // CHECK BUTTON
              _PrimaryButton(
                text: _checking ? 'Checking...' : 'I verified',
                onTap: _checking ? null : _checkVerification,
              ),

              const Spacer(),

              // SKIP
              GestureDetector(
                onTap: _skip,
                child: Center(
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      fontSize: 14,
                      color: secondary,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;

  const _PrimaryButton({
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: onTap == null ? 0.5 : 1,
        child: Container(
          height: 60,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(50),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
