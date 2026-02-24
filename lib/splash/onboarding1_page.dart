import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:iumrah_project/core/localization/translations_store.dart';
import 'package:iumrah_project/core/navigation/premium_route.dart';
import 'package:iumrah_project/home/home_page.dart';

class Onbording1Page extends StatefulWidget {
  const Onbording1Page({super.key});

  @override
  State<Onbording1Page> createState() => _Onbording1PageState();
}

class _Onbording1PageState extends State<Onbording1Page>
    with TickerProviderStateMixin {
  late VideoPlayerController _controller;

  late AnimationController _textController;
  late AnimationController _buttonController;

  late Animation<double> _textOpacity;
  late Animation<double> _buttonOpacity;
  late Animation<double> _logoOpacity;
  late AnimationController _logoController;

  String t(String key) => TranslationsStore.get(key);

  @override
  void initState() {
    super.initState();

    // VIDEO
    _controller = VideoPlayerController.asset(
      'assets/video/advisor_video.mp4',
    );

    _controller.initialize().then((_) {
      _controller.setLooping(true);
      _controller.setVolume(0);
      _controller.play();
      setState(() {});
    });

    // TEXT
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _textOpacity = CurvedAnimation(
      parent: _textController,
      curve: Curves.easeInOut,
    );

    // LOGO
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(_logoController);

    // BUTTON
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _buttonOpacity = CurvedAnimation(
      parent: _buttonController,
      curve: Curves.easeIn,
    );

    _startSequence();
  }

  Future<void> _startSequence() async {
    await _textController.forward();
    await Future.delayed(const Duration(seconds: 1));
    await _logoController.forward();
    await Future.delayed(const Duration(seconds: 1));
    _buttonController.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _textController.dispose();
    _logoController.dispose();
    _buttonController.dispose();
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
      body: Stack(
        children: [
          // ================= VIDEO =================
          if (_controller.value.isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            ),

          // ================= DARK OVERLAY =================
          Container(
            color: Colors.black.withOpacity(0.45),
          ),

          // ================= CONTENT =================
          SafeArea(
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Spacer(),
                  FadeTransition(
                    opacity: _logoOpacity,
                    child: Image.asset(
                      'assets/icons/airpods.png',
                      height: 90,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ===== TEXT FADE IN =====
                  FadeTransition(
                    opacity: _textOpacity,
                    child: Text(
                      t('onbording2_title'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Lato',
                        fontWeight: FontWeight.w800,
                        fontSize: 36,
                        height: 1.3,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 50),

                  // ===== BUTTON FADE IN =====
                  FadeTransition(
                    opacity: _buttonOpacity,
                    child: SizedBox(
                      height: 60,
                      width: double.infinity,
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(50),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(50),
                          onTap: _goNext,
                          child: Center(
                            child: Text(
                              t('continue_btn'),
                              style: const TextStyle(
                                fontFamily: 'Lato',
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
