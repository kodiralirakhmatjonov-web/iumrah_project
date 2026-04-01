import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:iumrah_project/core/profiles/profile_store.dart';
import 'package:iumrah_project/core/ui/app_ui.dart';
import 'package:iumrah_project/hajj/hajj_home.dart';
import 'package:iumrah_project/hajj/next_umra_page.dart';
import 'package:iumrah_project/home/aboutproject_page.dart';
import 'package:iumrah_project/home/home_page.dart';
import 'package:iumrah_project/home/widgets/main_nav_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:iumrah_project/core/navigation/premium_route.dart';
import 'package:iumrah_project/core/localization/translations_store.dart';
import 'package:iumrah_project/home/profile_page.dart';

class MainHomePage extends StatefulWidget {
  const MainHomePage({super.key});

  @override
  State<MainHomePage> createState() => _MainHomePageState();
}

class _MainHomePageState extends State<MainHomePage> {
  String t(String key) => TranslationsStore.get(key);

  static const String _prefsNameKey = 'profile_name';
  static const String _prefsNextUmrahDateKey = 'next_umrah_date';

  String _name = '—';
  DateTime? _nextUmrahDate;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final name = prefs.getString(_prefsNameKey) ?? '—';
    final savedDate = prefs.getString(_prefsNextUmrahDateKey);

    DateTime? parsedDate;

    if (savedDate != null && savedDate.isNotEmpty) {
      final raw = DateTime.tryParse(savedDate);
      if (raw != null) {
        parsedDate = DateTime(raw.year, raw.month, raw.day);
      }
    }

    if (!mounted) return;

    setState(() {
      _name = name;
      _nextUmrahDate = parsedDate;
    });
  }

  Future<void> _handleRefresh() async {
    await _loadData();
    await Future.delayed(const Duration(milliseconds: 400));
  }

  Future<void> _openNextUmrahPage() async {
    final result = await Navigator.of(context).push(
      PremiumRoute.push(const NextUmrahPage()),
    );

    if (result == true) {
      await _loadData();
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

  String get _firstLetter {
    final s = _name.trim();
    if (s.isEmpty || s == '—') return 'A';
    return s.characters.first.toUpperCase();
  }

  int _daysToNextUmrah() {
    if (_nextUmrahDate == null) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final target = DateTime(
      _nextUmrahDate!.year,
      _nextUmrahDate!.month,
      _nextUmrahDate!.day,
    );

    final diff = target.difference(today).inDays;

    if (diff < 0) return 0;

    return diff;
  }

  @override
  Widget build(BuildContext context) {
    final days = _daysToNextUmrah();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFE6E6EF),
        body: Stack(
          children: [
            SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  /// 🔥 iOS REFRESH
                  CupertinoSliverRefreshControl(
                    onRefresh: _handleRefresh,
                  ),

                  /// ===== MAIN CONTENT =====
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 10),

                          /// HEADER
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Image.asset(
                                'assets/images/logo.png',
                                height: 90,
                              ),
                              const Spacer(),
                              SizedBox(
                                height: 90,
                                child: Align(
                                  alignment: AlignmentDirectional.centerEnd,
                                  child: PremiumTap(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        PremiumRoute.push(const ProfilePage()),
                                      );
                                    },
                                    child: ValueListenableBuilder<ProfileData>(
                                      valueListenable: ProfileStore.notifier,
                                      builder: (context, profile, _) {
                                        return AnimatedSwitcher(
                                          duration:
                                              const Duration(milliseconds: 250),
                                          child: Container(
                                            key: ValueKey(profile.avatarKey),
                                            width: 60,
                                            height: 60,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                            ),
                                            child: ClipOval(
                                              child: Image.asset(
                                                _avatarAsset(profile.avatarKey),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          /// IMAGE
                          SizedBox(
                            width: double.infinity,
                            height: 300,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(40),
                              child: Image.asset(
                                'assets/images/homemain.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          /// COUNTDOWN
                          Text(
                            days.toString(),
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w800,
                              fontSize: 90,
                              color: Colors.black,
                            ),
                          ),

                          const SizedBox(height: 10),

                          /// TITLE
                          Text(
                            t('main_title'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w700,
                              fontSize: 32,
                              color: Colors.black,
                            ),
                          ),

                          const SizedBox(height: 30),

                          _card(
                            text: t('main_home_btn'),
                            onTap: () {
                              Navigator.of(context).push(
                                PremiumRoute.push(const HomePage()),
                              );
                            },
                          ),

                          const SizedBox(height: 14),
                          _card(
                            text: t('main_home_btn1'),
                            onTap: () {
                              Navigator.of(context).push(
                                PremiumRoute.push(const HajjHomePage()),
                              );
                            },
                          ),
                          const SizedBox(height: 14),
                          _card(
                            text: t('next_umrah_title'),
                            onTap: _openNextUmrahPage,
                          ),
                          const SizedBox(height: 20),

                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ),
                ],
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
    return PremiumTap(
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
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
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
