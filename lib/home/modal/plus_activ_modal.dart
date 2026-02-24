import 'package:flutter/material.dart';
import 'package:iumrah_project/core/localization/translations_store.dart';
import 'package:iumrah_project/widgets/green_wave.dart'; // твоя анимация

class PlusActivModal extends StatelessWidget {
  const PlusActivModal({super.key});

  String t(String key) => TranslationsStore.get(key);

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.9;

    return GestureDetector(
      onVerticalDragUpdate: (details) {
        if (details.primaryDelta != null && details.primaryDelta! > 10) {
          Navigator.pop(context);
        }
      },
      child: Container(
        height: height,
        decoration: const BoxDecoration(
          color: Color(0xFF000000),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(40),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 29),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // ---------- Drag indicator
                  Container(
                    width: 60,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ---------- Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Image.asset(
                      'assets/images/plus_image.png',
                      fit: BoxFit.cover,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ---------- Title
                  Text(
                    t('plus_activ_title'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Lato',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ---------- Green Wave Animation
                  const SizedBox(
                    height: 200,
                    child: GreenWave(
                      expanded: true,
                    ), // твоя анимация
                  ),

                  const SizedBox(height: 40),

                  // ---------- Static Advisor Text
                  const Text(
                    'Advisor',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Lato',
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 5),
                  const Text(
                    'Powered by iumrah project AI advisor',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Lato',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color.fromARGB(255, 118, 118, 118),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
