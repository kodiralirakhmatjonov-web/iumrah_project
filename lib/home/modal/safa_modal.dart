import 'package:flutter/material.dart';
import 'package:iumrah_project/core/localization/translations_store.dart';

class SafaModal {
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      builder: (_) => const _SafaModalBody(),
    );
  }

  static void open(BuildContext context) {}
}

class _SafaModalBody extends StatelessWidget {
  const _SafaModalBody();

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.9, // 90% экрана
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            /// HANDLE
            const SizedBox(height: 12),
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            const SizedBox(height: 24),

            /// SCROLL CONTENT
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    /// LOGO
                    Image.asset(
                      'assets/images/iumrah_logo.png', // замени если нужно
                      height: 42,
                    ),

                    const SizedBox(height: 28),

                    /// TITLE
                    Text(
                      TranslationsStore.get('overlay_safa_title'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 28),

                    /// ARABIC DUA
                    const Text(
                      '''
اللّٰهُ أَكْبَرُ، اللّٰهُ أَكْبَرُ، اللّٰهُ أَكْبَرُ
لَا إِلٰهَ إِلَّا اللّٰهُ وَحْدَهُ لَا شَرِيكَ لَهُ
لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَىٰ كُلِّ شَيْءٍ قَدِيرٌ
لَا إِلٰهَ إِلَّا اللّٰهُ وَحْدَهُ
أَنْجَزَ وَعْدَهُ، وَنَصَرَ عَبْدَهُ،
وَهَزَمَ الْأَحْزَابَ وَحْدَهُ
''',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.7,
                      ),
                    ),

                    const SizedBox(height: 32),

                    /// TRANSLITERATION
                    const Text(
                      '''
Allāhu akbar, Allāhu akbar, Allāhu akbar.
Lā ilāha illallāhu waḥdahu lā sharīka lah,
lahul-mulku wa lahul-ḥamd,
wa huwa ‘alā kulli shay’in qadīr.
Lā ilāha illallāhu waḥdah,
anjaza wa‘dah, wa naṣara ‘abdah,
wa hazamal-aḥzāba waḥdah.
''',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        height: 1.6,
                      ),
                    ),

                    const SizedBox(height: 28),

                    /// FOOTER TEXT
                    Text(
                      TranslationsStore.get('overlay_safa_text1'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: Colors.black54,
                      ),
                    ),

                    const SizedBox(height: 36),

                    /// CLOSE BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          TranslationsStore.get('complete_btn'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
