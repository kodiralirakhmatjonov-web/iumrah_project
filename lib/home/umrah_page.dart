// ====== ПОЛНЫЙ ФАЙЛ ======

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iumrah_project/home/safa_page.dart';
import 'package:iumrah_project/home/modal/pay_overlay.dart';
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

  // =======================
  // AUDIO KEY
  // =======================

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
        _collapseAdvisor();
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

  // =======================
  // ADVISOR TAP
  // =======================

  Future<void> _handleAdvisorTap() async {
    if (_isPlaying || _isLoadingAudio) return;

    final isPremium = await _isPremiumUser();

    if (!isPremium) {
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

      // гарантируем кеш
      await AudioCacheService.loadAndCacheAudio(lang);

      // получаем путь к локальному файлу
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
    setState(() {
      _advisorExpanded = false;
      _isPlaying = false;
      _isLoadingAudio = false;
    });
  }

  Future<void> _handleContinue() async {
    await _player.stop();
    _collapseAdvisor();

    if (_stateIndex < 3) {
      setState(() => _stateIndex++);
    } else {
      Navigator.of(context).push(
        PremiumRoute.push(const SafaPage()),
      );
    }
  }

  // =======================
  // CONTENT
  // =======================

  Widget _buildContent() {
    switch (_stateIndex) {
      case 0:
        return Column(
          children: [
            SvgPicture.asset(
              'assets/icons/pray_icons.png',
              width: 70,
            ),
            const SizedBox(height: 24),
            Text(
              t('tawafpray_title1'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Lato',
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              t('tawafpray_text1'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Lato',
                fontWeight: FontWeight.w600,
                fontSize: 16,
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
            Text(t('zamzam_title'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.w800,
                    fontSize: 22)),
            const SizedBox(height: 8),
            Text(t('zamzam_title1'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.w700,
                    fontSize: 18)),
            const SizedBox(height: 18),
            const Text('ZAM ZAM',
                style: TextStyle(
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.w800,
                    fontSize: 32)),
            const SizedBox(height: 16),
            Text(t('zamzam_text'),
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    height: 1.4,
                    color: Colors.black.withOpacity(0.75))),
          ],
        );

      case 2:
        return Column(
          children: [
            Image.asset('assets/icons/safa.png', width: 80),
            const SizedBox(height: 24),
            Text(t('safago_title'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.w800,
                    fontSize: 22)),
            const SizedBox(height: 8),
            Text(t('safago_title1'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.w700,
                    fontSize: 18)),
            const SizedBox(height: 16),
            Text(t('safago_text'),
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    height: 1.4,
                    color: Colors.black.withOpacity(0.75))),
          ],
        );

      case 3:
        return Column(
          children: [
            Image.asset('assets/icons/dua.png', width: 80),
            const SizedBox(height: 24),
            Text(t('safadua_title'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.w800,
                    fontSize: 22)),
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

  // =======================
  // BUILD
  // =======================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6E6EF),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),

            // HEADER
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset('assets/images/iumrah_logo.png', height: 86),
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: const SizedBox(
                      width: 50,
                      height: 50,
                      child: Icon(
                        CupertinoIcons.chevron_back,
                        size: 28,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ADVISOR
            SizedBox(
              width: _advisorW,
              height: 240, // фиксируем максимальную высоту
              child: Stack(
                children: [
                  // =======================
                  // BLACK CONTAINER
                  // =======================

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

                  // =======================
                  // PROGRESS BAR (Umrah top progress: Tawaf fills to 50%)
                  // =======================

                  PositionedDirectional(
                    top: 20,
                    start: 30,
                    child: Container(
                      width: _progressW,
                      height: _progressH,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E4F3B),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeInOut,
                          width: _topFillWidth,
                          height: _progressH,
                          decoration: BoxDecoration(
                            color: const Color(0xFF9DFF3C),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // =======================
                  // ADVISOR TEXT
                  // =======================

                  const PositionedDirectional(
                    start: 40,
                    top: 80,
                    child: Text(
                      'Advisor Umrah Assistant',
                      style: TextStyle(
                        fontFamily: 'Lato',
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  // =======================
                  // GREEN WAVE (ТАЧ ЗДЕСЬ)
                  // =======================

                  PositionedDirectional(
                    start: _advisorExpanded
                        ? _waveExpandedStart
                        : _waveCollapsedStart,
                    top:
                        _advisorExpanded ? _waveExpandedTop : _waveCollapsedTop,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeInOutCubic,
                      width: _advisorExpanded
                          ? _waveExpandedWidth
                          : _waveCollapsedWidth,
                      height: _advisorExpanded
                          ? _waveExpandedHeight
                          : _waveCollapsedHeight,
                      child: GestureDetector(
                        onTap: _handleAdvisorTap,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: GreenWave(
                            expanded: _advisorExpanded,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // =======================
                  // POWERED BY AI
                  // =======================

                  PositionedDirectional(
                    end: 20,
                    bottom: 18,
                    child: AnimatedOpacity(
                      opacity: _advisorExpanded ? 1 : 0,
                      duration: const Duration(milliseconds: 500),
                      child: const Text(
                        'powered by AI',
                        style: TextStyle(
                          fontFamily: 'Lato',
                          fontSize: 11,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
//white container
            Expanded(
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: SingleChildScrollView(
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(24, 32, 24, 45),
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
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 24),
              child: SizedBox(
                height: 65,
                width: double.infinity,
                child: Material(
                  color: const Color(0xFF7ED957),
                  borderRadius: BorderRadius.circular(50),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(50),
                    onTap: _handleContinue,
                    child: Center(
                      child: Text(
                        t('complete_btn'),
                        style: const TextStyle(
                          fontFamily: 'Lato',
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
