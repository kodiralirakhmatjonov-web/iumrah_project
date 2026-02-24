import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iumrah_project/features/language/language_page.dart';
import 'package:iumrah_project/splash/welcome_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import 'package:iumrah_project/core/navigation/premium_route.dart';

// твоё
import 'package:iumrah_project/core/localization/translations_store.dart';
import 'package:iumrah_project/home/modal/pay_overlay.dart';
import 'package:iumrah_project/home/modal/rate_modal.dart';
import 'package:iumrah_project/home/modal/policy_modal.dart';

// Если у тебя уже есть PremiumTap в app_ui.dart — используй его.
// Я оставил мягкий премиум-тап на AnimatedScale/Opacity прямо здесь,
// чтобы не ломать сборку, если класс отличается.
import 'package:flutter_svg/flutter_svg.dart';

// Share (если у тебя нет share_plus — добавь в pubspec.yaml)
// share_plus: ^10.0.0
import 'package:share_plus/share_plus.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {
  String t(String key) => TranslationsStore.get(key);

  final PageController _topPager = PageController();
  int _topIndex = 0;

  // ✅ берём из кеша HomePage
  static const String _prefsNameKey = 'profile_name';
  static const String _prefsCountryKey = 'profile_country';

  // prefs
  String _name = '—';
  String _country = '—';

  // flip card
  late final AnimationController _flipCtl;
  late final Animation<double> _flipAnim;
  bool _isCardBack = false;

  // share links placeholders (ты потом подставишь)
  final String _googlePlayUrl =
      'https://play.google.com/store/apps/details?id=YOUR_APP_ID';
  final String _appStoreUrl = 'https://apps.apple.com/app/idYOUR_APP_ID';

  @override
  void initState() {
    super.initState();

    _topPager.addListener(() {
      final p = _topPager.page ?? 0.0;
      final idx = p.round().clamp(0, 1);
      if (idx != _topIndex && mounted) {
        setState(() => _topIndex = idx);
      }
    });

    _flipCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );

    _flipAnim = CurvedAnimation(
      parent: _flipCtl,
      curve: Curves.easeInOutCubic,
    );

    _loadFromHomeCache();
  }

  // ✅ только SharedPreferences, без Supabase
  Future<void> _loadFromHomeCache() async {
    final prefs = await SharedPreferences.getInstance();

    final name = prefs.getString(_prefsNameKey) ?? '—';
    final country = prefs.getString(_prefsCountryKey) ?? '—';

    if (!mounted) return;
    setState(() {
      _name = name.trim().isEmpty ? '—' : name.trim();
      _country = country.trim().isEmpty ? '—' : country.trim();
    });
  }

  @override
  void dispose() {
    _topPager.dispose();
    _flipCtl.dispose();
    super.dispose();
  }

  // ---------------------------
  // UI helpers
  // ---------------------------
  String get _firstLetter {
    final s = _name.trim();
    if (s.isEmpty || s == '—') return 'A';
    return s.characters.first.toUpperCase();
  }

  Color _avatarColor(String name) {
    // Детерминированный “телеграм-стайл” набор
    const colors = <Color>[
      Color(0xFF3B82F6),
      Color(0xFF22C55E),
      Color(0xFFA855F7),
      Color(0xFFF97316),
      Color(0xFF06B6D4),
      Color(0xFFEF4444),
      Color(0xFF84CC16),
      Color(0xFF6366F1),
      Color(0xFFF59E0B),
      Color(0xFF14B8A6),
    ];

    final n = name.trim().isEmpty ? 'A' : name.trim();
    int h = 0;
    for (final code in n.codeUnits) {
      h = (h * 31 + code) & 0x7fffffff;
    }
    return colors[h % colors.length];
  }

  Future<void> _openPayOverlay() async {
    HapticFeedback.lightImpact();
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PayOverlay(),
    );
  }

  Future<void> _openRateModal() async {
    HapticFeedback.lightImpact();
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const RateModal(),
    );
  }

  Future<void> _openPolicyModal() async {
    HapticFeedback.lightImpact();
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PolicyModal(),
    );
  }

  void _flipCard() {
    HapticFeedback.selectionClick();
    if (_isCardBack) {
      _flipCtl.reverse();
    } else {
      _flipCtl.forward();
    }
    setState(() => _isCardBack = !_isCardBack);
  }

  void _onCardVerticalDrag(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0.0;
    // свайп вверх/вниз переворачивает
    if (v.abs() > 120) _flipCard();
  }

  Future<void> _shareApp() async {
    HapticFeedback.lightImpact();

    // грузим asset
    final bytes = await rootBundle.load('assets/images/app_icon.png');
    final data =
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes);

    // создаём temp файл
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/app_icon.png');
    await file.writeAsBytes(data, flush: true);

    final text =
        'iumrah project\n\nGoogle Play:\n$_googlePlayUrl\n\nApp Store:\n$_appStoreUrl';

    await Share.shareXFiles(
      [XFile(file.path)],
      text: text,
    );
  }

  Future<void> _logout() async {
    HapticFeedback.lightImpact();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('is_premium');

    // ✅ чистим именно эти ключи (кеш HomePage)
    await prefs.remove(_prefsNameKey);
    await prefs.remove(_prefsCountryKey);

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      PremiumRoute.push(const WelcomePage()),
      (r) => false,
    );
  }

  // ---------------------------
  // widgets
  // ---------------------------
  Widget _topDots() {
    Widget dot(bool active) => AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: active
                ? Colors.white.withOpacity(0.90)
                : Colors.white.withOpacity(0.25),
            shape: BoxShape.circle,
          ),
        );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        dot(_topIndex == 0),
        const SizedBox(width: 8),
        dot(_topIndex == 1),
      ],
    );
  }

  Widget _premiumTap({
    required VoidCallback onTap,
    required Widget child,
    BorderRadius? radius,
  }) {
    return _PremiumTapInternal(
      onTap: onTap,
      borderRadius: radius ?? BorderRadius.circular(50),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131313), // основной фон из Figma
      body: Stack(
        children: [
          // ЗОЛОТОЙ СВЕТ
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -0.4), // чуть выше центра
                  radius: 0.6,
                  colors: [
                    Color(0xFF07E2FF), // центр
                    Color(0x0007E2FF), // прозрачный край
                  ],
                  stops: [0.0, 1.0],
                ),
              ),
            ),
          ),

          SafeArea(
            // ✅ вся страница со скроллом
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 15),

                    // ===== HEADER =====
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Image.asset(
                          'assets/images/iumrah_id2.png',
                          height: 60,
                          fit: BoxFit.contain,
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).maybePop(),
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            alignment: AlignmentDirectional.center,
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

                    // ===== TOP SWIPE CONTAINER (2 states) =====
                    SizedBox(
                      width: double.infinity,
                      // ✅ фикс overflow (было 210, не хватало ~18px)
                      height: 250,
                      child: Column(
                        children: [
                          Expanded(
                            child: PageView(
                              controller: _topPager,
                              physics: const BouncingScrollPhysics(),
                              children: [
                                // -------------------
                                // STATE 1 (avatar + name)
                                // -------------------
                                Column(
                                  children: [
                                    const SizedBox(height: 12),
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: _avatarColor(_name),
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: AlignmentDirectional.center,
                                      child: Text(
                                        _firstLetter,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontFamily: 'Lato',
                                          fontWeight: FontWeight.w800,
                                          fontSize: 32,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      _name,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontFamily: 'Lato',
                                        fontWeight: FontWeight.w800,
                                        fontSize: 40,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                ),

                                // -------------------
                                // STATE 2 (plastic card + flip)
                                // -------------------
                                Column(
                                  children: [
                                    const SizedBox(height: 14),
                                    GestureDetector(
                                      onVerticalDragEnd: _onCardVerticalDrag,
                                      onTap: _flipCard,
                                      child: AnimatedBuilder(
                                        animation: _flipAnim,
                                        builder: (context, child) {
                                          final v = _flipAnim.value; // 0..1
                                          final angle = v * math.pi;

                                          final isBack = angle > (math.pi / 2);

                                          // ✅ вертикальный флип (rotateX)
                                          return Transform(
                                            alignment: Alignment.center,
                                            transform: Matrix4.identity()
                                              ..setEntry(3, 2, 0.0012)
                                              ..rotateX(angle),
                                            child: isBack
                                                ? Transform(
                                                    alignment: Alignment.center,
                                                    transform:
                                                        Matrix4.identity()
                                                          ..rotateX(math.pi),
                                                    child: const _IdCardBack(),
                                                  )
                                                : _IdCardFront(
                                                    name: _name,
                                                    country: _country,
                                                  ),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          _topDots(),
                          const SizedBox(height: 14),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ===== iumrahID card (opens PayOverlay) =====
                    _premiumTap(
                      onTap: _openPayOverlay,
                      radius: BorderRadius.circular(40),
                      child: Container(
                        width: double.infinity,
                        height: 110,
                        padding:
                            const EdgeInsetsDirectional.fromSTEB(20, 0, 18, 0),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.10),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            /// LEFT CONTENT
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  /// IMAGE
                                  Image.asset(
                                    'assets/images/iumrah_id.png',
                                    height: 35,
                                    fit: BoxFit.contain,
                                  ),

                                  const SizedBox(height: 6),

                                  /// TEXT UNDER IMAGE
                                  Text(
                                    t('profile_id_text'),
                                    textAlign: TextAlign.start,
                                    style: const TextStyle(
                                      fontFamily: 'Lato',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            /// ARROW RIGHT
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 30,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ===== iumrah Plus card (opens PayOverlay) =====
                    _premiumTap(
                      onTap: _openPayOverlay,
                      radius: BorderRadius.circular(50),
                      child: Container(
                        width: double.infinity,
                        height: 74,
                        padding:
                            const EdgeInsetsDirectional.fromSTEB(20, 0, 18, 0),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: AlignmentDirectional.centerStart,
                            end: AlignmentDirectional.centerEnd,
                            colors: [
                              const Color(0xFF7C3AED).withOpacity(0.70),
                              const Color(0xFF22D3EE).withOpacity(0.70),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Row(
                          children: [
                            Image.asset(
                              'assets/icons/magic1.png',
                              height: 35,
                            ),
                            const SizedBox(width: 20),
                            const Expanded(
                              child: Text(
                                'iumrah Plus',
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                  fontFamily: 'Lato',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 26,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 30,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ===== 4 rows container =====
                    Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(18, 14, 18, 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Column(
                        children: [
                          _RowItem(
                            icon: Image.asset(
                              'assets/icons/lang_icon.png',
                              width: 50,
                              height: 50,
                              fit: BoxFit.contain,
                            ),
                            text: t('profile_lang'),
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Navigator.of(context).push(
                                PremiumRoute.push(const LanguagePage()),
                              );
                            },
                          ),
                          const SizedBox(height: 10),
                          _RowItem(
                            icon: Image.asset(
                              'assets/icons/rate.png',
                              width: 50,
                              height: 50,
                              fit: BoxFit.contain,
                            ),
                            text: t('profile_rate'),
                            onTap: _openRateModal,
                          ),
                          const SizedBox(height: 10),
                          _RowItem(
                            icon: Image.asset(
                              'assets/icons/privacy.png',
                              width: 50,
                              height: 50,
                              fit: BoxFit.contain,
                            ),
                            text: t('profile_privacy'),
                            onTap: _openPolicyModal,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ===== LOGOUT =====
                    _premiumTap(
                      onTap: _logout,
                      radius: BorderRadius.circular(50),
                      child: Container(
                        width: double.infinity,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        alignment: AlignmentDirectional.center,
                        child: Text(
                          t('logout_btn'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Lato',
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------
// Plastic card front
// ---------------------------
class _IdCardFront extends StatelessWidget {
  final String name;
  final String country;

  const _IdCardFront({
    required this.name,
    required this.country,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // ✅ размер 324 x 186
      width: 330,
      height: 190,
      padding: const EdgeInsetsDirectional.fromSTEB(18, 16, 18, 16),
      decoration: BoxDecoration(
        // ✅ чёрная карта
        color: Colors.black,
        borderRadius: BorderRadius.circular(25),
        // ✅ border stroke 1.5
        border: Border.all(
          color: Color(0xFF07E2FF),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ iumrah ID - фотка из ассетс
          Image.asset(
            'assets/images/iumrah_id.png',
            height: 40,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 60),
          // ✅ имя и гражданство под фоткой
          Text(
            name,
            style: const TextStyle(
              fontFamily: 'Lato',
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            country,
            style: TextStyle(
              fontFamily: 'Lato',
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------
// Plastic card back
// ---------------------------
class _IdCardBack extends StatelessWidget {
  const _IdCardBack();

  @override
  Widget build(BuildContext context) {
    return Container(
      // ✅ размер 324 x 186
      width: 330,
      height: 190,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Color(0xFF07E2FF),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          'powered by iumrah ID',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Lato',
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ---------------------------
// Row item (icon + text + arrow)
// ---------------------------
class _RowItem extends StatelessWidget {
  final Widget icon;
  final String text;
  final VoidCallback onTap;

  const _RowItem({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(10, 12, 10, 12),
          child: Row(
            children: [
              SizedBox(width: 24, height: 24, child: Center(child: icon)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.black.withOpacity(0.60),
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: Colors.black.withOpacity(0.25),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------
// Premium tap internal (scale + opacity)
// ---------------------------
class _PremiumTapInternal extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final BorderRadius borderRadius;

  const _PremiumTapInternal({
    required this.child,
    required this.onTap,
    required this.borderRadius,
  });

  @override
  State<_PremiumTapInternal> createState() => _PremiumTapInternalState();
}

class _PremiumTapInternalState extends State<_PremiumTapInternal> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        scale: _down ? 0.98 : 1.0,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          opacity: _down ? 0.92 : 1.0,
          child: ClipRRect(
            borderRadius: widget.borderRadius,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
