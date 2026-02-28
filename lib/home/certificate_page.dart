import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:iumrah_project/core/navigation/premium_route.dart';
import 'package:iumrah_project/core/localization/translations_store.dart';
import 'package:iumrah_project/home/after_umrah_page.dart';

class CertificatePage extends StatefulWidget {
  const CertificatePage({super.key});

  @override
  State<CertificatePage> createState() => _CertificatePageState();
}

class _CertificatePageState extends State<CertificatePage> {
  String t(String key) => TranslationsStore.get(key);

  String _userName = '—';

  final GlobalKey _screenKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final n = (prefs.getString('profile_name') ?? '—').trim();
    if (!mounted) return;
    setState(() => _userName = n.isEmpty ? '—' : n);
  }

  /// ---------- SCREENSHOT WHOLE SCREEN (EXCEPT BUTTONS) ----------
  Future<Uint8List> _captureScreenPng() async {
    await Future.delayed(const Duration(milliseconds: 20));

    final boundary =
        _screenKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

    if (boundary.debugNeedsPaint) {
      await Future.delayed(const Duration(milliseconds: 20));
      return _captureScreenPng();
    }

    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  Future<void> _shareCertificate() async {
    try {
      HapticFeedback.lightImpact();

      final png = await _captureScreenPng();

      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/iumrah_certificate_${DateTime.now().millisecondsSinceEpoch}.png';

      final file = File(path);
      await file.writeAsBytes(png, flush: true);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'My Umrah Certificate - iumrah project',
      );
    } catch (e) {
      debugPrint('Share error: $e');
    }
  }

  void _goNext() {
    Navigator.of(context)
        .pushReplacement(PremiumRoute.push(const AfterUmrahPage()));
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          /// ---------- BACKGROUND ----------
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, 0.15),
                  radius: 0.85,
                  colors: [
                    Color(0xFF04D718),
                    Color(0xFF000000),
                  ],
                  stops: [0.0, 1.0],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26),
            child: Column(
              children: [
                const SizedBox(height: 50),

                /// ---------- SCREEN CONTENT (WILL BE CAPTURED) ----------
                RepaintBoundary(
                  key: _screenKey,
                  child: Column(
                    children: [
                      /// HEADER
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Image.asset(
                            'assets/images/iumrah_logo1.png',
                            height: 85,
                          ),
                          Container(
                            height: 50,
                            width: 50,
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
                        ],
                      ),

                      const SizedBox(height: 28),

                      /// GREEN PILL
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        height: 65,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(40),
                          color: const Color(0xFF04D718),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          t('end_text'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Lato',
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                      ),

                      const SizedBox(height: 35),

                      /// CERTIFICATE CARD
                      SizedBox(
                        width: 320,
                        height: 420,
                        child: _CertificateCard(
                          userName: _userName,
                          t: t,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                /// ---------- BUTTONS (NOT IN SCREENSHOT) ----------
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    MediaQuery.of(context).padding.bottom + 20,
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _shareCertificate,
                        child: Container(
                          height: 54,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(26),
                            color: const Color(0xFF04D718),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            t('sertificate_btn2'),
                            style: const TextStyle(
                              fontFamily: 'Lato',
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: _goNext,
                        child: Container(
                          height: 54,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(26),
                            color: Colors.white,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            t('complete_btn'),
                            style: const TextStyle(
                              fontFamily: 'Lato',
                              fontWeight: FontWeight.w900,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------------- CERTIFICATE CARD ----------------

class _CertificateCard extends StatelessWidget {
  final String userName;
  final String Function(String) t;

  const _CertificateCard({
    required this.userName,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xffe6e6ef),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        children: [
          Image.asset(
            'assets/images/iumrah_logo.png',
            height: 50,
          ),
          const SizedBox(height: 18),
          const Text(
            'CERTIFICATE',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w700,
              fontSize: 26,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'FOR HAJJ AND UMRAH',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'DEAR AR-RAHMAN’S GUEST',
            style: TextStyle(
              fontFamily: 'Lato',
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: Colors.black45,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            t('sertificate_text1'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Lato',
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            userName,
            style: const TextStyle(
              fontFamily: 'Lato',
              fontWeight: FontWeight.w900,
              fontSize: 20,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Container(height: 1, color: Colors.black26),
          const SizedBox(height: 10),
          Text(
            t('sertificate_text2'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Lato',
              fontWeight: FontWeight.w600,
              fontSize: 11,
              color: Colors.black45,
            ),
          ),
          const SizedBox(height: 40),
          Image.asset(
            'assets/images/sertificate.png',
            height: 50,
          ),
        ],
      ),
    );
  }
}
