import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:iumrah_project/core/navigation/premium_route.dart';
import 'package:iumrah_project/core/localization/local_strings.dart';
import 'package:iumrah_project/auth/login_page.dart';
import 'package:iumrah_project/auth/register_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  late VideoPlayerController _controller;

  String get _deviceLang {
    final locale = Platform.localeName; // ru_RU
    return locale.split('_').first; // ru
  }

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.asset(
      'assets/video/reg_video.mp4',
    )
      ..setLooping(true)
      ..setVolume(0.0)
      ..initialize().then((_) {
        _controller.play();
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = _deviceLang;

    return Scaffold(
      body: Stack(
        children: [
          /// VIDEO BACKGROUND
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

          /// DARK OVERLAY
          Container(
            color: Colors.black.withOpacity(0.45),
          ),

          /// CONTENT
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),

                /// TITLE (STATIC)
                const Text(
                  'Welcome\nto iumrah',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Montserrat',
                    color: Colors.white,
                    height: 0.85,
                    letterSpacing: -6,
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'No Stress. Emotional Umrah',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'Montserrat',
                    color: Colors.white70,
                  ),
                ),

                const SizedBox(height: 60),

                /// LOGIN BUTTON (WHITE)
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        PremiumRoute.push(
                          const LoginPage(),
                        ),
                      );
                    },
                    child: Text(
                      LocalStrings.t('login_title', lang),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                /// REGISTER BUTTON (BLACK)
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        PremiumRoute.push(
                          const RegisterPage(),
                        ),
                      );
                    },
                    child: Text(
                      LocalStrings.t('register_title', lang),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
