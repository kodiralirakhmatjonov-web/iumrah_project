import 'dart:async';
import 'package:flutter/material.dart';
import 'package:iumrah_project/core/navigation/premium_route.dart';
import 'package:iumrah_project/core/localization/translations_store.dart';
import 'package:iumrah_project/home/home_page.dart';
import 'package:iumrah_project/core/ui/app_ui.dart';

class Onboarding2Page extends StatefulWidget {
  const Onboarding2Page({super.key});

  @override
  State<Onboarding2Page> createState() => _Onboarding2PageState();
}

class _Onboarding2PageState extends State<Onboarding2Page>
    with TickerProviderStateMixin {
  String t(String key) => TranslationsStore.get(key);

  String _visibleText = '';
  String _fullText = '';

  Timer? _typingTimer;
  Timer? _cursorTimer;

  bool _showCursor = true;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);

    _fullText = t('onbording2_title');

    _startTyping();
    _startCursor();
  }

  void _startTyping() {
    int i = 0;

    _fadeController.forward();

    _typingTimer = Timer.periodic(const Duration(milliseconds: 40), (timer) {
      if (i >= _fullText.length) {
        timer.cancel();
        return;
      }

      if (!mounted) return;

      setState(() {
        _visibleText = _fullText.substring(0, i + 1);
      });

      i++;
    });
  }

  void _startCursor() {
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted) return;

      setState(() {
        _showCursor = !_showCursor;
      });
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _cursorTimer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  void _goNext() {
    Navigator.of(context).pushReplacement(
      PremiumRoute.push(const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // ===== HEADER LOGO =====
            Image.asset(
              'assets/images/iumrah_logo1.png',
              height: 90,
              fit: BoxFit.contain,
            ),

            const SizedBox(height: 30),

            // ===== IMAGE FULL WIDTH =====
            SizedBox(
              width: double.infinity,
              child: Image.asset(
                'assets/images/plus_image1.png',
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(height: 40),

            // ===== TYPEWRITER TEXT =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: _visibleText,
                        style: const TextStyle(
                          fontFamily: 'Lato',
                          fontWeight: FontWeight.w800,
                          fontSize: 26,
                          height: 1.3,
                          color: Colors.white,
                        ),
                      ),
                      TextSpan(
                        text: _showCursor ? '|' : ' ',
                        style: const TextStyle(
                          fontSize: 26,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const Spacer(),

            // ===== BUTTON =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: PremiumTap(
                onTap: _goNext,
                child: Container(
                  height: 60,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF06D13),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    t('complete_btn'),
                    style: const TextStyle(
                      fontFamily: 'Lato',
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
