import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iumrah_project/core/ui/app_ui.dart';
import 'package:iumrah_project/home/safa_page.dart';
import 'package:iumrah_project/home/modal/pay_overlay.dart';
import 'package:iumrah_project/home/widgets/umrah_header.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';

import 'package:iumrah_project/core/localization/translations_store.dart';
import 'package:iumrah_project/core/navigation/premium_route.dart';
import 'package:iumrah_project/widgets/green_wave.dart';
import 'package:iumrah_project/core/localization/audio_cache_service.dart';

class UmrahPage extends StatefulWidget {
  const UmrahPage({super.key});

  @override
  State<UmrahPage> createState() => _UmrahPageState();
}

class _UmrahPageState extends State<UmrahPage> with TickerProviderStateMixin {
  String t(String key) => TranslationsStore.get(key);

  int _stateIndex = 0;

  bool _advisorExpanded = false;
  bool _isPlaying = false;
  bool _isLoadingAudio = false;

  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerState>? _playerSub;

  final double _advisorW = 340;
  final double _collapsedHeight = 150;
  final double _expandedHeight = 240;

  final double _progressW = 280;
  final double _progressH = 35;

  final double _waveCollapsedWidth = 200;
  final double _waveCollapsedHeight = 70;
  final double _waveCollapsedStart = 122;
  final double _waveCollapsedTop = 70;

  final double _waveExpandedWidth = 310;
  final double _waveExpandedHeight = 120;
  final double _waveExpandedStart = 16;
  final double _waveExpandedTop = 110;

  String get _audioKey {
    switch (_stateIndex) {
      case 0:
        return 'pray';
      case 1:
        return 'zam_zam';
      case 2:
        return 'safa_go';
      case 3:
        return 'safa_dua';
      default:
        return 'pray';
    }
  }

  @override
  void initState() {
    super.initState();

    _playerSub = _player.playerStateStream.listen((state) async {
      if (state.processingState == ProcessingState.completed) {
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) {
          _collapseAdvisor();
        }
      }
    });
  }

  @override
  void dispose() {
    _playerSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<bool> _isPremiumUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_premium') ?? false;
  }

  double get _topFillWidth => _progressW * 0.5;

  Future<void> _handleAdvisorTap() async {
    if (_isPlaying || _isLoadingAudio) return;

    final isPremium = await _isPremiumUser();

    if (!isPremium) {
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const PayOverlay(),
      );
      return;
    }

    setState(() {
      _advisorExpanded = true;
      _isLoadingAudio = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final lang = prefs.getString('app_language') ?? 'ru';

      await AudioCacheService.loadAndCacheAudio(lang);

      final prefKey = 'audio_${_audioKey}_$lang';
      final localPath = prefs.getString(prefKey);

      if (localPath == null) {
        _collapseAdvisor();
        return;
      }

      await _player.setFilePath(localPath);

      setState(() {
        _isLoadingAudio = false;
        _isPlaying = true;
      });

      await _player.play();
    } catch (_) {
      _collapseAdvisor();
    }
  }

  void _collapseAdvisor() {
    if (!mounted) return;
    setState(() {
      _advisorExpanded = false;
      _isPlaying = false;
      _isLoadingAudio = false;
    });
  }

  Future<void> _handleContinue() async {
    HapticFeedback.lightImpact();
    await _player.stop();
    _collapseAdvisor();

    if (!mounted) return;

    if (_stateIndex < 3) {
      setState(() {
        _stateIndex++;
      });
    } else {
      Navigator.of(context).push(
        PremiumRoute.push(const SafaPage()),
      );
    }
  }

  Future<void> _handleBack() async {
    if (_stateIndex == 0) return;

    HapticFeedback.lightImpact();
    await _player.stop();
    _collapseAdvisor();

    if (!mounted) return;

    setState(() {
      _stateIndex--;
    });
  }

  Widget _buildContent() {
    switch (_stateIndex) {
      case 0:
        return Column(
          children: [
            Image.asset('assets/icons/pray_icons.png', width: 70),
            const SizedBox(height: 24),
            Text(
              t('tawafpray_title1'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w800,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              t('tawafpray_text1'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Lato',
                fontWeight: FontWeight.w600,
                fontSize: 20,
                height: 1.4,
                color: Colors.black.withOpacity(0.75),
              ),
            ),
          ],
        );

      case 1:
        return Column(
          children: [
            Image.asset('assets/icons/zamzam.png', width: 80),
            const SizedBox(height: 24),
            Text(
              t('zamzam_title1'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Lato',
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t('zamzam_title'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Lato',
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'ZAM ZAM',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w800,
                fontSize: 32,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              t('zamzam_text'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Lato',
                fontWeight: FontWeight.w600,
                fontSize: 18,
                height: 1.4,
                color: Colors.black.withOpacity(0.75),
              ),
            ),
          ],
        );

      case 2:
        return Column(
          children: [
            Image.asset('assets/icons/safa.png', width: 80),
            const SizedBox(height: 20),
            Text(
              t('safago_title'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t('safago_title1'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Lato',
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              t('safago_text'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Lato',
                fontWeight: FontWeight.w600,
                fontSize: 18,
                height: 1.4,
                color: Colors.black.withOpacity(0.75),
              ),
            ),
          ],
        );

      case 3:
        return Column(
          children: [
            Image.asset('assets/icons/dua.png', width: 80),
            const SizedBox(height: 20),
            Text(
              t('safadua_title'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'إِنَّ الصَّفَا وَالْمَرْوَةَ مِن شَعَائِرِ اللَّهِ ۖ فَمَنْ حَجَّ الْبَيْتَ أَوِ اعْتَمَرَ فَلَا جُنَاحَ عَلَيْهِ أَن يَطَّوَّفَ بِهِمَا ۚ وَمَن تَطَوَّعَ خَيْرًا فَإِنَّ اللَّهَ شَاكِرٌ عَلِيمٌ\n\n'
              'أَبْدَأُ بِمَا بَدَأَ اللَّهُ بِهِ\n\n'
              'اللَّهُ أَكْبَرُ، اللَّهُ أَكْبَرُ، اللَّهُ أَكْبَرُ\n\n'
              'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، يُحْيِي وَيُمِيتُ، وَهُوَ عَلَىٰ كُلِّ شَيْءٍ قَدِيرٌ\n\n'
              'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ، أَنْجَزَ وَعْدَهُ، وَنَصَرَ عَبْدَهُ، وَهَزَمَ الْأَحْزَابَ وَحْدَهُ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Lato',
                fontSize: 26,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Inna as-Safa wal-Marwata min sha\'a\'irillah. '
              'Faman hajja al-bayta awi\'tamar fala junaha \'alayhi an yattawwafa bihima. '
              'Wa man tatawwa\'a khayran fa inna Allaha shakirun \'alim.\n\n'
              'Abda\'u bima bada\'a Allahu bih.\n\n'
              'Allahu Akbar, Allahu Akbar, Allahu Akbar.\n\n'
              'La ilaha illa Allah wahdahu la sharika lah, '
              'lahu al-mulku wa lahu al-hamd, yuhyi wa yumit, '
              'wa huwa \'ala kulli shay\'in qadir.\n\n'
              'La ilaha illa Allah wahdah, '
              'anjaza wa\'dah, '
              'wa nasara \'abdah, '
              'wa hazama al-ahzaba wahdah.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Lato',
                fontSize: 26,
                color: Colors.black,
                height: 1.3,
              ),
            ),
          ],
        );

      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool showBack = _stateIndex > 0;

    return Scaffold(
      backgroundColor: const Color(0xFFE6E6EF),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: UmrahHeader(currentStep: 2),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: _advisorW,
              height: 240,
              child: Stack(
                children: [
                  AnimatedContainer(
                    duration: const Duration(seconds: 1),
                    curve: Curves.easeInOutCubic,
                    width: _advisorW,
                    height:
                        _advisorExpanded ? _expandedHeight : _collapsedHeight,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  Positioned(
                    top: 20,
                    left: 30,
                    child: Container(
                      width: _progressW,
                      height: _progressH,
                      decoration: BoxDecoration(
                        color: const Color(0x33F06D13),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: _topFillWidth,
                          height: _progressH,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF06D13),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 40,
                    top: 80,
                    child: Text(
                      'Advisor Premuim Guide',
                      style: TextStyle(
                        fontFamily: 'Lato',
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Positioned(
                    left: _advisorExpanded
                        ? _waveExpandedStart
                        : _waveCollapsedStart,
                    top:
                        _advisorExpanded ? _waveExpandedTop : _waveCollapsedTop,
                    child: GestureDetector(
                      onTap: _handleAdvisorTap,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 900),
                        width: _advisorExpanded
                            ? _waveExpandedWidth
                            : _waveCollapsedWidth,
                        height: _advisorExpanded
                            ? _waveExpandedHeight
                            : _waveCollapsedHeight,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: GreenWave(expanded: _advisorExpanded),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 45),
                      child: Column(
                        children: [
                          _buildContent(),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeInOutCubic,
                    width: showBack ? 110 : 0,
                    child: showBack
                        ? Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: SizedBox(
                              height: 60,
                              child: PremiumTap(
                                onTap: _handleBack,
                                child: Container(
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: Text(
                                    t('back_btn'),
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  Expanded(
                    child: SizedBox(
                      height: 60,
                      child: PremiumTap(
                        onTap: _handleContinue,
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF06D13),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Text(
                            _stateIndex < 3
                                ? t('complete_btn')
                                : t('continue_btn'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
