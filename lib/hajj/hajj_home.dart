import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iumrah_project/hajj/next_umra_page.dart';
import 'package:iumrah_project/home/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:iumrah_project/core/navigation/premium_route.dart';
import 'package:iumrah_project/core/localization/translations_store.dart';

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
        backgroundColor: const Color(0xFFE6E6EF),
        body: Stack(
          children: [
            /// ===== MAIN CONTENT =====
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 10),

                    /// ===== HEADER =====
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Image.asset(
                          'assets/images/logo.png',
                          height: 90,
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            height: 60,
                            width: 60,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              size: 30,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    /// ===== IMAGE + SHADER =====
                    SizedBox(
                      width: double.infinity,
                      height: 300,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(40),
                              child: Image.asset(
                                'assets/images/hajj_image.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),

                          /// 🔥 НОРМАЛЬНЫЙ SHADER (не белый шум)
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// ===== TITLE =====
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

                    /// ===== COUNTDOWN =====
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

                    _card(
                      text: t('hajj_home_btn1'),
                      onTap: () {
                        Navigator.of(context).push(
                          PremiumRoute.push(const HomePage()),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    _card(
                      text: t('hajj_home_btn2'),
                      onTap: () {},
                    ),

                    const SizedBox(height: 120), // 👈 место под navbar
                  ],
                ),
              ),
            ),
          ],
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
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F4F4),
          borderRadius: BorderRadius.circular(40),
        ),
        alignment: Alignment.centerLeft,
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
