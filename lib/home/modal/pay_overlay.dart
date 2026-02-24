import 'package:flutter/material.dart';

import 'package:iumrah_project/core/localization/translations_store.dart';
import 'package:iumrah_project/widgets/green_wave.dart';
import 'package:iumrah_project/home/plus_page.dart';
import 'package:iumrah_project/core/navigation/premium_route.dart';
// путь проверь
// если используешь токены

class PayOverlay extends StatelessWidget {
  const PayOverlay({super.key});

  String t(String key) => TranslationsStore.get(key);

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const PayOverlay(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 0, 0, 0),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(40),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(28, 24, 28, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              /// =============================
              /// YELLOW SERVER WORKS ALERT
              /// =============================

              const SizedBox(height: 40),

              /// =============================
              /// ADVISOR TITLE
              /// =============================
              const Text(
                'Advisor',
                style: TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 24),

              /// =============================
              /// PAY TITLE
              /// =============================
              Text(
                t('pay_title'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Lato',
                  fontWeight: FontWeight.w700,
                  fontSize: 36,
                  color: Colors.white.withOpacity(0.9),
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 20),

              /// =============================
              /// PAY TEXT
              /// =============================
              Text(
                t('pay_text'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Colors.white70,
                ),
              ),

              const SizedBox(height: 40),

              /// =============================
              /// GREEN WAVE ANIMATION
              /// =============================
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: const SizedBox(
                  height: 190,
                  width: double.infinity,
                  child: GreenWave(
                    expanded: true,
                  ),
                ),
              ),

              const Spacer(),

              /// =============================
              /// BUY BUTTON (STUB)
              /// =============================
              Column(
                children: [
                  SizedBox(
                    height: 60,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          PremiumRoute.push(
                            const PlusPage(),
                          ),
                        );
                      },
                      // 🔒 пока заглушка
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6BFF00),
                        disabledBackgroundColor: const Color(0xFF6BFF00),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      child: Text(
                        t('buy_btn'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    t('buy_btn_sub'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
