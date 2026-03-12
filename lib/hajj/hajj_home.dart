import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:iumrah_project/core/navigation/premium_route.dart';
import 'package:iumrah_project/core/localization/translations_store.dart';
import 'package:iumrah_project/home/profile_page.dart';

class HajjHomePage extends StatefulWidget {
  const HajjHomePage({super.key});

  @override
  State<HajjHomePage> createState() => _HajjHomePageState();
}

class _HajjHomePageState extends State<HajjHomePage> {
  String t(String key) => TranslationsStore.get(key);

  static const String _prefsNameKey = 'profile_name';

  String _name = '—';

  @override
  void initState() {
    super.initState();
    _loadName();
  }

  Future<void> _loadName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_prefsNameKey) ?? '—';

    if (!mounted) return;

    setState(() {
      _name = name;
    });
  }

  String get _firstLetter {
    final s = _name.trim();
    if (s.isEmpty || s == '—') return 'A';
    return s.characters.first.toUpperCase();
  }

  int _daysToHajj() {
    final now = DateTime.now();
    final hajjDate = DateTime(2026, 5, 25);

    return hajjDate.difference(now).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final days = _daysToHajj();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),

                  // HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Image.asset(
                        'assets/images/hajj_logo.png',
                        height: 210,
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            PremiumRoute.push(const ProfilePage()),
                          );
                        },
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFEAEAEA),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _firstLetter,
                            style: const TextStyle(
                              fontFamily: 'Lato',
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(
                    width: double.infinity,
                    height: 311,
                    child: Stack(
                      children: [
                        // IMAGE
                        Positioned.fill(
                          child: Image.asset(
                            'assets/images/hajj_image.png',
                            fit: BoxFit.cover,
                          ),
                        ),

                        // RADIAL GRADIENT EXACT LIKE FIGMA
                        Positioned.fill(
                          child: Transform.scale(
                            scaleX: 1.8,
                            scaleY: 1.0,
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: RadialGradient(
                                  center: Alignment.center,
                                  radius: 0.7,
                                  colors: [
                                    Color(0x00000000),
                                    Color(0xFFFFFFFF),
                                  ],
                                  stops: [0.0, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // TITLE
                  Text(
                    t('hajj_title'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w700,
                      fontSize: 32,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // COUNTDOWN
                  Text(
                    days.toString(),
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w800,
                      fontSize: 90,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // CARD 1
                  _card(
                    text: t('hajj_home_btn1'),
                    onTap: () {},
                  ),

                  const SizedBox(height: 14),

                  // CARD 2
                  _card(
                    text: t('hajj_home_btn2'),
                    onTap: () {},
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _card({
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 110,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F4F4),
          borderRadius: BorderRadius.circular(40),
        ),
        alignment: AlignmentDirectional.centerStart,
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontFamily: 'Lato',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Colors.black,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 22,
              color: Colors.black,
            ),
          ],
        ),
      ),
    );
  }
}
