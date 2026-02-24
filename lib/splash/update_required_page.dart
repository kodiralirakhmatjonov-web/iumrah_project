import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:iumrah_project/core/localization/translations_store.dart';
// Если у тебя есть PremiumTap в app_ui.dart — раскомментируй 2 строки ниже
// import 'package:iumrah_project/core/ui/app_ui.dart';

class UpdateRequiredPage extends StatefulWidget {
  const UpdateRequiredPage({super.key});

  @override
  State<UpdateRequiredPage> createState() => _UpdateRequiredPageState();
}

class _UpdateRequiredPageState extends State<UpdateRequiredPage>
    with SingleTickerProviderStateMixin {
  String t(String key) => TranslationsStore.get(key);

  // TODO: вставь свои ссылки
  static const String kAppStoreUrl =
      ''; // например: https://apps.apple.com/app/idXXXXXXXXXX
  static const String kPlayStoreUrl =
      ''; // например: https://play.google.com/store/apps/details?id=your.package

  late final AnimationController _ctrl;
  late final Animation<double> _anim;
  double _dragDy = 0.0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onDragStart(DragStartDetails d) {
    HapticFeedback.selectionClick();
    _ctrl.stop();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    // лёгкий отклик: двигаем карточку, но не закрываем
    final next = (_dragDy + d.delta.dy).clamp(-18.0, 18.0);
    setState(() => _dragDy = next.toDouble());
  }

  void _onDragEnd(DragEndDetails d) {
    final start = _dragDy;
    _ctrl.reset();
    _ctrl.forward();
    _ctrl.addListener(() {
      if (!mounted) return;
      setState(() {
        // плавно возвращаем в 0
        _dragDy = start * (1.0 - _anim.value);
      });
    });
    _ctrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        _ctrl.removeListener(() {});
      }
    });
  }

  Future<void> _openStore() async {
    HapticFeedback.lightImpact();

    final url = Platform.isIOS ? kAppStoreUrl : kPlayStoreUrl;

    if (url.trim().isEmpty) {
      _toast('Set store URL in UpdateRequiredPage');
      return;
    }

    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!ok) _toast('Could not open store');
  }

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // ❌ запрет Back
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: const Color(0xFFE6E6EF),
        body: SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragStart: _onDragStart,
            onVerticalDragUpdate: _onDragUpdate,
            onVerticalDragEnd: _onDragEnd,
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(24, 20, 24, 20),
                  child: Transform.translate(
                    offset: Offset(0, _dragDy),
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 520),
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(20, 22, 20, 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 30,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // app_icon.png
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2F2F8),
                              borderRadius: BorderRadius.circular(34),
                            ),
                            alignment: AlignmentDirectional.center,
                            child: Image.asset(
                              'assets/images/app_icon2.png',
                              width: 72,
                              height: 72,
                              fit: BoxFit.contain,
                            ),
                          ),

                          const SizedBox(height: 26),

                          // update_title
                          Text(
                            t('update_title'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Lato',
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                              color: Color(0xFF14141A),
                            ),
                          ),

                          const SizedBox(height: 18),

                          // 4 строки update_box...
                          _Line(t('update_box')),
                          const SizedBox(height: 6),
                          _Line(t('update_box1')),
                          const SizedBox(height: 6),
                          _Line(t('update_box2')),
                          const SizedBox(height: 6),
                          _Line(t('update_box3')),

                          const SizedBox(height: 22),

                          // button (premium tap логика)
                          // Если у тебя есть PremiumTap — замени GestureDetector на PremiumTap(...)
                          GestureDetector(
                            onTap: _openStore,
                            child: Container(
                              height: 60,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0E0E13),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              alignment: AlignmentDirectional.center,
                              child: Text(
                                t('update_btn'),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: 'Lato',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          Text(
                            t('update_btn_sub'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Lato',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              height: 1.25,
                              color: const Color(0xFF14141A).withOpacity(0.55),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final String text;
  const _Line(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'Lato',
        fontSize: 15,
        fontWeight: FontWeight.w700,
        height: 1.25,
        color: const Color(0xFF14141A).withOpacity(0.72),
      ),
    );
  }
}
