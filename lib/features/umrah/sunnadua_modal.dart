import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iumrah_project/core/localization/translations_store.dart';

class SunnahDuaModal {
  static Future<void> open(BuildContext context) {
    HapticFeedback.lightImpact();

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (_) => const _SunnahDuaSheet(),
    );
  }
}

class _SunnahDuaSheet extends StatelessWidget {
  const _SunnahDuaSheet();

  String t(String key) => TranslationsStore.get(key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: FractionallySizedBox(
        heightFactor: 0.90,
        alignment: AlignmentDirectional.bottomCenter,
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadiusDirectional.only(
              topStart: Radius.circular(40),
              topEnd: Radius.circular(40),
            ),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(24, 24, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ===== BLACK CONTAINER =====
                Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Text(
                    t('tawaf_common_text3'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Lato',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // ===== ARABIC DUA =====
                const Text(
                  'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً، وَفِي الآخِرَةِ حَسَنَةً، وَقِنَا عَذَابَ النَّارِ',
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: 'lato', // если есть Quran font
                    fontSize: 32,
                    height: 1.8,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 28),

                // ===== TRANSLITERATION PLACE =====
                const Text(
                  'Rabbana atina fid-dunya hasanatan, wa fil-akhirati hasanatan, wa qina adhaban-nar',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Lato',
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                    color: Colors.black54,
                  ),
                ),

                const SizedBox(height: 40),

                // ===== GREEN CONTAINER =====
                Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7BFF00),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Text(
                    t('tawaf_common_text2'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Lato',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Colors.black,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // ===== BIG TEXT =====
                Text(
                  t('tawaf_common_text1'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.w800,
                    fontSize: 28,
                    height: 1.2,
                    color: Colors.black87,
                  ),
                ),

                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
