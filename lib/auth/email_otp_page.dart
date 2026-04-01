import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iumrah_project/features/language/reg_name.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:iumrah_project/core/localization/local_strings.dart';
import 'package:iumrah_project/core/navigation/premium_route.dart';

class EmailOtpPage extends StatefulWidget {
  final String email;

  const EmailOtpPage({
    super.key,
    required this.email,
  });

  @override
  State<EmailOtpPage> createState() => _EmailOtpPageState();
}

class _EmailOtpPageState extends State<EmailOtpPage> {
  static const int _length = 8;
  static const int _resendSeconds = 30;

  final supabase = Supabase.instance.client;

  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  late String lang;

  Timer? _timer;

  bool _isError = false;
  bool _isSuccess = false;
  bool _submitted = false;
  bool _isSending = false;
  bool _isVerifying = false;
  bool _showSentBanner = false;

  int _secondsLeft = _resendSeconds;

  String t(String key) => LocalStrings.t(key, lang);

  @override
  void initState() {
    super.initState();

    lang = WidgetsBinding.instance.platformDispatcher.locale.languageCode;

    _controllers = List.generate(_length, (_) => TextEditingController());
    _focusNodes = List.generate(_length, (_) => FocusNode());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendCode();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((e) => e.text).join().trim();

  bool get _canResend => !_isSending && _secondsLeft == 0;

  Future<void> _sendCode() async {
    if (_isSending) return;
    if (_secondsLeft > 0 && _secondsLeft != _resendSeconds) return;

    setState(() {
      _isSending = true;
      _isError = false;
      _isSuccess = false;
    });

    try {
      await supabase.auth.signInWithOtp(
        email: widget.email,
        shouldCreateUser: false,
      );

      if (!mounted) return;

      _showSuccessBanner();
      _startResendTimer();
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _verifyCode() async {
    if (_isVerifying) return;
    if (_code.length != _length) return;

    setState(() {
      _isVerifying = true;
      _isError = false;
    });

    try {
      await supabase.auth.verifyOTP(
        email: widget.email,
        token: _code,
        type: OtpType.email,
      );

      if (!mounted) return;

      setState(() {
        _isSuccess = true;
        _isError = false;
      });

      await Future.delayed(const Duration(milliseconds: 250));

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        PremiumRoute.push(const RegNamePage()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isError = true;
        _isSuccess = false;
        _submitted = false;
      });

      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes.first.requestFocus();
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  void _showSuccessBanner() {
    setState(() {
      _showSentBanner = true;
    });

    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      setState(() {
        _showSentBanner = false;
      });
    });
  }

  void _startResendTimer() {
    _timer?.cancel();

    setState(() {
      _secondsLeft = _resendSeconds;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() {
          _secondsLeft = 0;
        });
      } else {
        setState(() {
          _secondsLeft -= 1;
        });
      }
    });
  }

  void _showError(String message) {
    final text = message.isEmpty ? 'Error' : message;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onChanged(int index, String value) {
    // Вставка полного кода
    if (value.length > 1) {
      final cleaned = value.replaceAll(RegExp(r'\s+'), '');
      final chars = cleaned.split('');

      for (int i = 0; i < _length; i++) {
        _controllers[i].text = i < chars.length ? chars[i] : '';
      }

      if (chars.length >= _length) {
        _focusNodes[_length - 1].unfocus();
      } else {
        _focusNodes[chars.length].requestFocus();
      }

      setState(() {
        _isError = false;
        _isSuccess = false;
      });

      if (_code.length == _length && !_submitted) {
        _submitted = true;
        _verifyCode();
      } else {
        _submitted = false;
      }
      return;
    }

    // Обычный ввод по 1 символу
    if (value.isNotEmpty && index < _length - 1) {
      _focusNodes[index + 1].requestFocus();
    }

    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    setState(() {
      _isError = false;
      _isSuccess = false;
    });

    if (_code.length == _length && !_submitted) {
      _submitted = true;
      _verifyCode();
    }

    if (_code.length < _length) {
      _submitted = false;
    }
  }

  Color _borderColor() {
    if (_isError) return const Color(0xFFE17676);
    if (_isSuccess) return const Color(0xFF6FCB59);
    return const Color(0xFFE7A1A1);
  }

  void _handleContinue() {
    if (_code.length == _length) {
      _verifyCode();
    } else {
      setState(() {
        _isError = true;
        _isSuccess = false;
        _submitted = false;
      });
    }
  }

  void _handleSkip() {
    Navigator.pushAndRemoveUntil(
      context,
      PremiumRoute.push(const RegNamePage()),
      (_) => false,
    );
  }

  Widget _buildSentBanner() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: _showSentBanner
          ? Container(
              key: const ValueKey('otp_sent_banner'),
              height: 56,
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: const Color(0xFF83CC46),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 18,
                      color: Color(0xFF83CC46),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    t('otp_sent'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(key: ValueKey('otp_sent_empty')),
    );
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 38,
      height: 58,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(8), // 🔥 вместо maxLength
        ],
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: _borderColor(),
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: _borderColor(),
              width: 2,
            ),
          ),
        ),
        onChanged: (v) => _onChanged(index, v),
      ),
    );
  }

  String _resendText() {
    if (_secondsLeft == 0) {
      return t('otp_resend');
    }
    return '${t('otp_resend')} ${_secondsLeft}s';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFe6e6ef),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsetsDirectional.fromSTEB(
                24,
                24,
                24,
                190 + bottomInset,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Image.asset(
                        'assets/images/iumrah_logo.png',
                        height: 85,
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 58,
                          height: 58,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            size: 28,
                            color: Color(0xFF878C99),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _buildSentBanner(),
                  const SizedBox(height: 34),
                  Text(
                    t('otp_title'),
                    style: const TextStyle(
                      fontSize: 35,
                      fontWeight: FontWeight.w700,
                      color: Color.fromARGB(255, 5, 5, 5),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    t('otp_subtitle'),
                    style: const TextStyle(
                      fontSize: 18,
                      height: 1.35,
                      color: Color.fromARGB(255, 97, 97, 97),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(_length, _buildOtpBox),
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: _canResend ? _sendCode : null,
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _resendText(),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF727784),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      18,
                      18,
                      18,
                      18,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsetsDirectional.only(top: 2),
                          child: Icon(
                            Icons.verified,
                            size: 25,
                            color: Color.fromARGB(255, 0, 0, 0),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Text(
                            t('otp_info'),
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color.fromARGB(255, 5, 5, 5),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 24 + bottomInset,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _isVerifying ? null : _handleContinue,
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        color: const Color.fromARGB(255, 0, 0, 0),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        t('continue_btn'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _handleSkip,
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        color: Colors.white.withOpacity(0.75),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        t('skip_btn'),
                        style: const TextStyle(
                          color: Color.fromARGB(255, 120, 121, 122),
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
