import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iumrah_project/core/profiles/iumrah_id_start_page.dart';
import 'package:iumrah_project/core/profiles/profile_identity_card.dart';
import 'package:iumrah_project/core/profiles/profile_store.dart';
import 'package:iumrah_project/core/ui/app_ui.dart';
import 'package:iumrah_project/features/language/language_modal.dart';
import 'package:iumrah_project/home/rate_page.dart';
import 'package:iumrah_project/home/widgets/app_header.dart';
import 'package:iumrah_project/home/widgets/mekka_time_page.dart';
import 'package:iumrah_project/home/widgets/prayer_hero_section.dart';
import 'package:iumrah_project/splash/welcome_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // ← ДОБАВЛЕНО

import 'package:iumrah_project/core/navigation/premium_route.dart';

// твоё
import 'package:iumrah_project/core/localization/translations_store.dart';
import 'package:iumrah_project/home/modal/pay_overlay.dart';
import 'package:iumrah_project/home/modal/rate_modal.dart';
import 'package:iumrah_project/home/modal/policy_modal.dart';

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
  final String _name = '—';
  final String _country = '—';

  // flip card
  late final AnimationController _flipCtl;
  late final Animation<double> _flipAnim;
  final bool _isCardBack = false;

  // share links placeholders (ты потом подставишь)
  final String _googlePlayUrl =
      'https://play.google.com/store/apps/details?id=YOUR_APP_ID';
  final String _appStoreUrl = 'https://apps.apple.com/app/idYOUR_APP_ID';

  @override
  void initState() {
    super.initState();
    _loadProfileFromServer();

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
  }

  Future<void> _loadProfileFromServer() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    final uid = user.id;

    // ✅ ВОТ СЮДА СТАВИМ ПРОВЕРКУ
    final alreadyLoaded = prefs.getBool('profile_loaded_$uid') ?? false;

    if (alreadyLoaded) {
      // 👉 если уже загружали — просто грузим из cache в UI
      await ProfileStore.load();
      return;
    }

    try {
      final data = await supabase
          .from('profiles')
          .select()
          .eq('user_id', uid)
          .maybeSingle();

      if (data == null) return;

      final name = (data['name'] ?? '').toString();
      final email = user.email ?? '';
      final avatar = (data['avatar_key'] ?? 'male_01').toString();

      // ✅ сохраняем в cache
      await prefs.setString('profile_name_$uid', name);
      await prefs.setString('profile_email_$uid', email);
      await prefs.setString('profile_avatar_key_$uid', avatar);

      // ✅ помечаем что уже загрузили
      await prefs.setBool('profile_loaded_$uid', true);

      // ✅ обновляем UI
      await ProfileStore.update(
        ProfileData(
          name: name,
          email: email,
          avatarKey: avatar,
        ),
      );
    } catch (e) {
      debugPrint('PROFILE LOAD ERROR: $e');
    }
  }

  // ✅ только SharedPreferences, без Supabase

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

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    final prefs = await SharedPreferences.getInstance();

    if (user != null) {
      final uid = user.id;

      // ✅ УДАЛЯЕМ ВСЕ КЭШ ДАННЫЕ ЭТОГО ПОЛЬЗОВАТЕЛЯ
      await prefs.remove('profile_name_$uid');
      await prefs.remove('profile_email_$uid');
      await prefs.remove('profile_avatar_key_$uid');
      await prefs.remove('profile_loaded_$uid');
    }

    // ❗ старые ключи тоже убиваем (на всякий)
    await prefs.remove(_prefsNameKey);
    await prefs.remove(_prefsCountryKey);

    // ✅ чистим UI state
    await ProfileStore.clear();

    // ✅ logout из Supabase (ПОСЛЕ удаления uid!)
    await supabase.auth.signOut();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      PremiumRoute.push(const WelcomePage()),
      (r) => false,
    );
  }

  // ===========================
  // ДОБАВЛЕНО: УДАЛЕНИЕ АККАУНТА
  // ===========================

  Future<void> _deleteAccount() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      // удаляем профиль
      await Supabase.instance.client
          .from('profiles')
          .delete()
          .eq('user_id', user.id);

      // выходим
      await Supabase.instance.client.auth.signOut();

      // чистим локальные данные
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        PremiumRoute.push(const WelcomePage()),
        (r) => false,
      );
    } catch (e) {
      debugPrint('Delete error: $e');
    }
  }

  String _avatarAsset(String key) {
    if (key.startsWith('male_')) {
      return 'assets/profile/avatars/male/$key.png';
    }
    if (key.startsWith('female_')) {
      return 'assets/profile/avatars/female/$key.png';
    }
    return 'assets/profile/avatars/male/male_01.png';
  }

  Future<void> _confirmDeleteAccount() async {
    HapticFeedback.lightImpact();

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) {
        return Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.86,
            padding: const EdgeInsetsDirectional.fromSTEB(20, 24, 20, 20),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F2E9),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: 70,
                ),
                const SizedBox(height: 25),
                Text(
                  t('delete_text'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 22),

                // удалить
                _premiumTap(
                  onTap: () {
                    Navigator.pop(context);
                    _deleteAccount();
                  },
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 229, 8, 8),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      t('delete_btn'),
                      style: const TextStyle(
                        fontFamily: 'Lato',
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // отменить
                _premiumTap(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 208, 206, 200),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      t('cancel_btn'),
                      style: TextStyle(
                        fontFamily: 'Lato',
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
      backgroundColor: const Color(0xFFe6e6ef), // основной фон из Figma
      body: Stack(
        children: [
          SafeArea(
            bottom: false,

            // ✅ вся страница со скроллом
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 15),

                    // ===== HEADER =====
                    const AppHeader(),

                    const SizedBox(height: 20),

                    const SizedBox(height: 16),

                    ProfileIdentityCard(),

                    const SizedBox(height: 15),
                    // ===== iumrahID card (opens PayOverlay) =====
                    // ===== iumrahID card (opens IumrahIdStartPage) =====
                    PremiumTap(
                      onTap: _openPayOverlay,
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
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Image.asset(
                                    'assets/images/iumrah_id2.png',
                                    height: 35,
                                    fit: BoxFit.contain,
                                  ),
                                  const SizedBox(height: 6),
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
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 30,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ===== iumrah Plus card (opens PayOverlay) =====
                    _premiumTap(
                      onTap: _openPayOverlay,
                      radius: BorderRadius.circular(40),
                      child: Container(
                        width: double.infinity,
                        height: 74,
                        padding:
                            const EdgeInsetsDirectional.fromSTEB(15, 0, 18, 0),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: AlignmentDirectional.centerStart,
                            end: AlignmentDirectional.centerEnd,
                            colors: [
                              const Color.fromARGB(255, 247, 106, 6),
                              const Color.fromARGB(255, 65, 26, 2),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Row(
                          children: [
                            Image.asset(
                              'assets/icons/right_icon.png',
                              height: 55,
                            ),
                            const SizedBox(width: 5),
                            const Expanded(
                              child: Text(
                                'Premium Umrah',
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                  fontFamily: 'Lato',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 24,
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

                    const SizedBox(height: 10),

                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        Navigator.of(context).push(
                          PremiumRoute.push(const MekkaTimePage()),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsetsDirectional.fromSTEB(
                            20, 20, 20, 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF08111B),
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.05),
                            width: 1,
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: Colors.black.withOpacity(0.22),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const PrayerHeroSection(
                          city: PrayerCity.makkah,
                        ),
                      ),
                    ),
                    // дальше твой остальной profile UI
                    const SizedBox(height: 10),
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

                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                isDismissible: false,
                                enableDrag: false,
                                backgroundColor: Colors.transparent,
                                builder: (_) => LanguageModal(),
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
                            onTap: () {
                              Navigator.of(context).push(
                                PremiumRoute.push(const RatePage()),
                              );
                            },
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

                    const SizedBox(height: 50),

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

                    const SizedBox(height: 7),

                    // ===== DELETE ACCOUNT (ДОБАВЛЕНО) =====
                    _premiumTap(
                      onTap: _confirmDeleteAccount,
                      radius: BorderRadius.circular(50),
                      child: Container(
                        width: double.infinity,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        alignment: AlignmentDirectional.center,
                        child: Text(
                          t('delete_btn'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
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
