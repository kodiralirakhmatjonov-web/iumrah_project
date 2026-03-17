import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_app_review/in_app_review.dart';

import 'package:iumrah_project/core/localization/translations_store.dart';
import 'package:iumrah_project/core/navigation/premium_route.dart';
import 'package:iumrah_project/home/after_umrah_page.dart';

class RatePage extends StatefulWidget {
  const RatePage({
    super.key,
    this.nextPage = const AfterUmrahPage(),
  });

  final Widget nextPage;

  @override
  State<RatePage> createState() => _RatePageState();
}

class _RatePageState extends State<RatePage> with TickerProviderStateMixin {
  String t(String key) => TranslationsStore.get(key);

  int _rating = 0;
  bool _submitting = false;

  late final AnimationController _entryController;
  late final AnimationController _glowController;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _fade = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.045),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Curves.easeOutCubic,
      ),
    );

    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _setRating(int value) {
    HapticFeedback.lightImpact();
    setState(() => _rating = value);
  }

  Future<void> _submit() async {
    if (_rating == 0 || _submitting) return;

    setState(() => _submitting = true);
    HapticFeedback.mediumImpact();

    try {
      if (_rating >= 4) {
        final inAppReview = InAppReview.instance;
        final available = await inAppReview.isAvailable();

        if (available) {
          await inAppReview.requestReview();
        }
      }

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        PremiumRoute.push(widget.nextPage),
      );
    } catch (_) {
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        PremiumRoute.push(widget.nextPage),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bottomInset = media.padding.bottom;
    final glowValue = 0.82 + (_glowController.value * 0.18);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(color: Colors.black),
              ),
              PositionedDirectional(
                top: media.size.height * 0.21,
                start: -40,
                end: -40,
                child: AnimatedBuilder(
                  animation: _glowController,
                  builder: (context, _) {
                    return IgnorePointer(
                      child: Container(
                        height: 430,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: const Alignment(0, 0.02),
                            radius: 0.86,
                            colors: [
                              const Color(0xCCFFAC07)
                                  .withOpacity(0.34 * glowValue),
                              const Color(0x99FFAC07)
                                  .withOpacity(0.16 * glowValue),
                              const Color(0x33FFAC07)
                                  .withOpacity(0.06 * glowValue),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.34, 0.62, 1.0],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.10,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: AlignmentDirectional(-0.9, -1),
                          end: AlignmentDirectional(0.9, 1),
                          colors: [
                            Colors.transparent,
                            Colors.white24,
                            Colors.transparent,
                            Colors.white12,
                            Colors.transparent,
                          ],
                          stops: [0.0, 0.26, 0.44, 0.62, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(24, 8, 24, 0),
                    child: Column(
                      children: [
                        const SizedBox(height: 6),
                        Image.asset(
                          'assets/images/iumrah_logo1.png',
                          height: 92,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 26),
                        Padding(
                          padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: 8),
                          child: Text(
                            t('rate_title'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Lato',
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              height: 1.22,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        AnimatedBuilder(
                          animation: _glowController,
                          builder: (context, _) {
                            final shadowOpacity = _rating == 0
                                ? 0.34
                                : 0.46 + (_glowController.value * 0.10);

                            return Container(
                              width: 1000,
                              constraints: const BoxConstraints(maxWidth: 320),
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  22, 24, 22, 26),
                              decoration: BoxDecoration(
                                color: const Color(0xFF090909),
                                borderRadius: BorderRadius.circular(38),
                                border: Border.all(
                                  color: const Color(0xFFFFAC07),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFFAC07)
                                        .withOpacity(shadowOpacity),
                                    blurRadius: 44,
                                    spreadRadius: 4,
                                  ),
                                  BoxShadow(
                                    color: const Color(0xFFFFAC07)
                                        .withOpacity(0.16),
                                    blurRadius: 16,
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: List.generate(5, (index) {
                                      final star = index + 1;
                                      final active = _rating >= star;

                                      return _RateStar(
                                        active: active,
                                        onTap: () => _setRating(star),
                                      );
                                    }),
                                  ),
                                  const SizedBox(height: 28),
                                  Text(
                                    t('rate_text'),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontFamily: 'Lato',
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      height: 1.28,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 34),
                        Padding(
                          padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: 10),
                          child: Text(
                            t('rate_title1'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Lato',
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              height: 1.22,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: _rating == 0 || _submitting ? null : _submit,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            width: double.infinity,
                            height: 58,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color:
                                  _rating == 0 ? const Color(0xFFE8E8E8) : null,
                              gradient: _rating == 0
                                  ? null
                                  : const RadialGradient(
                                      center: AlignmentDirectional(0, 0),
                                      radius: 1.15,
                                      colors: [
                                        Color(0xFFFFC640),
                                        Color(0xFFFFAC07),
                                      ],
                                    ),
                              boxShadow: _rating == 0
                                  ? null
                                  : [
                                      BoxShadow(
                                        color: const Color(0xFFFFAC07)
                                            .withOpacity(0.45),
                                        blurRadius: 26,
                                        spreadRadius: 0,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                            ),
                            alignment: AlignmentDirectional.center,
                            child: Text(
                              t('rate_button'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Lato',
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                                color: _rating == 0
                                    ? const Color(0xFFB6B6B6)
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: 8),
                          child: Text(
                            t('rate_button_sub'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Lato',
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              height: 1.2,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(height: bottomInset + 18),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RateStar extends StatelessWidget {
  const _RateStar({
    required this.active,
    required this.onTap,
  });

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        scale: active ? 1.04 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsetsDirectional.all(2),
          child: Icon(
            Icons.star_rounded,
            size: 44,
            color: active ? Color(0xFFFFAC07) : Color(0x33FFAC07),
            shadows: active
                ? [
                    Shadow(
                      color: const Color(0xFFFFAC07).withOpacity(0.45),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }
}
