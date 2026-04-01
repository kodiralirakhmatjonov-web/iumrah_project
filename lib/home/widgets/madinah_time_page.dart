import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:iumrah_project/home/widgets/app_header.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:iumrah_project/core/navigation/premium_route.dart';
import 'package:iumrah_project/home/widgets/mekka_time_page.dart';
import 'package:iumrah_project/home/widgets/prayer_countdown_hero.dart';

class MadinahTimePage extends StatefulWidget {
  const MadinahTimePage({super.key});

  @override
  State<MadinahTimePage> createState() => _MadinahTimePageState();
}

class _MadinahTimePageState extends State<MadinahTimePage> {
  static const String _cityKey = 'madinah';
  static const String _cityName = 'Madinah';

  static const List<String> _order = <String>[
    'Fajr',
    'Sunrise',
    'Dhuhr',
    'Asr',
    'Maghrib',
    'Isha',
  ];

  final Map<String, DateTime> _prayerTimes = <String, DateTime>{};

  Timer? _ticker;

  bool _isLoading = true;
  bool _isReloadingDay = false;
  String? _errorText;
  String _loadedSaudiDateKey = '';

  String _currentPrayerName = '';
  String _nextPrayerName = '';
  String _statusText = 'Ближайшая молитва';

  Duration _remaining = Duration.zero;
  double _reverseProgress = 0.0;
  DateTime? _lastThirdStart;

  @override
  void initState() {
    super.initState();
    _initPage();
    _startTicker();
  }

  DateTime _nowSaudi() {
    return DateTime.now().toUtc().add(const Duration(hours: 3));
  }

  String _saudiDateKey(DateTime dt) {
    final String y = dt.year.toString().padLeft(4, '0');
    final String m = dt.month.toString().padLeft(2, '0');
    final String d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _dayKey(DateTime dt) {
    return dt.day.toString().padLeft(2, '0');
  }

  String _monthCacheKey(int year, int month) {
    return 'prayer_month_${_cityKey}_${year}_${month.toString().padLeft(2, '0')}';
  }

  Future<void> _initPage() async {
    final bool hasCache = await _loadTodayFromCache();

    if (mounted && hasCache) {
      setState(() {
        _isLoading = false;
        _errorText = null;
      });
    }

    await _refreshOnline(silentIfCache: hasCache);
  }

  Future<bool> _loadTodayFromCache() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final DateTime nowSaudi = _nowSaudi();

      final String? raw = prefs.getString(
        _monthCacheKey(nowSaudi.year, nowSaudi.month),
      );

      if (raw == null) return false;

      final Map<String, dynamic> monthMap =
          jsonDecode(raw) as Map<String, dynamic>;

      final dynamic timingsDynamic = monthMap[_dayKey(nowSaudi)];
      if (timingsDynamic is! Map) return false;

      _applyTimingsRaw(
        Map<String, dynamic>.from(timingsDynamic),
        nowSaudi,
      );

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _saveMonthCache(
    int year,
    int month,
    Map<String, dynamic> monthMap,
  ) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _monthCacheKey(year, month),
      jsonEncode(monthMap),
    );
  }

  Future<Map<String, dynamic>> _fetchMonthMap(int year, int month) async {
    final Uri uri = Uri.https(
      'api.aladhan.com',
      '/v1/calendarByCity/$year/$month',
      <String, String>{
        'city': _cityName,
        'country': 'Saudi Arabia',
        'method': '4',
      },
    );

    final http.Response response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final Map<String, dynamic> json =
        jsonDecode(response.body) as Map<String, dynamic>;

    final dynamic data = json['data'];
    if (data is! List) {
      throw Exception('Invalid calendar data');
    }

    final Map<String, dynamic> monthMap = <String, dynamic>{};

    for (final dynamic item in data) {
      if (item is! Map) continue;

      final dynamic dateRaw = item['date'];
      final dynamic gregorianRaw = dateRaw is Map ? dateRaw['gregorian'] : null;
      final String day =
          gregorianRaw is Map ? (gregorianRaw['day'] ?? '').toString() : '';

      final dynamic timingsRaw = item['timings'];

      if (day.isEmpty || timingsRaw is! Map) continue;

      monthMap[day.padLeft(2, '0')] = Map<String, dynamic>.from(timingsRaw);
    }

    return monthMap;
  }

  Future<void> _refreshOnline({required bool silentIfCache}) async {
    try {
      final DateTime nowSaudi = _nowSaudi();
      final DateTime nextMonthDate =
          DateTime(nowSaudi.year, nowSaudi.month + 1, 1);

      final List<Map<String, dynamic>> results =
          await Future.wait(<Future<Map<String, dynamic>>>[
        _fetchMonthMap(nowSaudi.year, nowSaudi.month),
        _fetchMonthMap(nextMonthDate.year, nextMonthDate.month),
      ]);

      final Map<String, dynamic> currentMonthMap = results[0];
      final Map<String, dynamic> nextMonthMap = results[1];

      await _saveMonthCache(nowSaudi.year, nowSaudi.month, currentMonthMap);
      await _saveMonthCache(
        nextMonthDate.year,
        nextMonthDate.month,
        nextMonthMap,
      );

      final String todayKey = _dayKey(nowSaudi);
      final dynamic timingsDynamic = currentMonthMap[todayKey];

      if (timingsDynamic is! Map) {
        throw Exception('Today timings not found');
      }

      _applyTimingsRaw(
        Map<String, dynamic>.from(timingsDynamic),
        nowSaudi,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorText = null;
      });
    } catch (_) {
      if (!mounted) return;

      if (silentIfCache && _prayerTimes.isNotEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _isLoading = false;
        _errorText = 'Не удалось загрузить времена молитв';
      });
    }
  }

  void _applyTimingsRaw(
    Map<String, dynamic> timingsRaw,
    DateTime nowSaudi,
  ) {
    DateTime parsePrayerTime(String key) {
      final String raw = (timingsRaw[key] ?? '').toString();
      final RegExpMatch? match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(raw);

      if (match == null) {
        throw Exception('Cannot parse $key from "$raw"');
      }

      final int hour = int.parse(match.group(1)!);
      final int minute = int.parse(match.group(2)!);

      return DateTime(
        nowSaudi.year,
        nowSaudi.month,
        nowSaudi.day,
        hour,
        minute,
      );
    }

    _prayerTimes
      ..clear()
      ..addAll(<String, DateTime>{
        'Fajr': parsePrayerTime('Fajr'),
        'Sunrise': parsePrayerTime('Sunrise'),
        'Dhuhr': parsePrayerTime('Dhuhr'),
        'Asr': parsePrayerTime('Asr'),
        'Maghrib': parsePrayerTime('Maghrib'),
        'Isha': parsePrayerTime('Isha'),
      });

    _loadedSaudiDateKey = _saudiDateKey(nowSaudi);
    _deriveUiState(nowSaudi);
  }

  void _startTicker() {
    _ticker?.cancel();

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) async {
      final DateTime nowSaudi = _nowSaudi();
      final String currentDateKey = _saudiDateKey(nowSaudi);

      if (currentDateKey != _loadedSaudiDateKey) {
        if (_isReloadingDay) return;

        _isReloadingDay = true;

        final bool hasCache = await _loadTodayFromCache();

        if (mounted && hasCache) {
          setState(() {
            _isLoading = false;
            _errorText = null;
          });
        }

        await _refreshOnline(silentIfCache: hasCache);
        _isReloadingDay = false;
        return;
      }

      if (_prayerTimes.isEmpty || !mounted) return;

      setState(() {
        _deriveUiState(nowSaudi);
      });
    });
  }

  void _deriveUiState(DateTime nowSaudi) {
    if (_prayerTimes.isEmpty) return;

    final DateTime fajr = _prayerTimes['Fajr']!;
    final DateTime sunrise = _prayerTimes['Sunrise']!;
    final DateTime dhuhr = _prayerTimes['Dhuhr']!;
    final DateTime asr = _prayerTimes['Asr']!;
    final DateTime maghrib = _prayerTimes['Maghrib']!;
    final DateTime isha = _prayerTimes['Isha']!;

    late String currentPrayer;
    late DateTime currentStart;
    late String nextPrayer;
    late DateTime nextTime;

    if (nowSaudi.isBefore(fajr)) {
      currentPrayer = 'Isha';
      currentStart = isha.subtract(const Duration(days: 1));
      nextPrayer = 'Fajr';
      nextTime = fajr;
    } else if (nowSaudi.isBefore(sunrise)) {
      currentPrayer = 'Fajr';
      currentStart = fajr;
      nextPrayer = 'Sunrise';
      nextTime = sunrise;
    } else if (nowSaudi.isBefore(dhuhr)) {
      currentPrayer = 'Sunrise';
      currentStart = sunrise;
      nextPrayer = 'Dhuhr';
      nextTime = dhuhr;
    } else if (nowSaudi.isBefore(asr)) {
      currentPrayer = 'Dhuhr';
      currentStart = dhuhr;
      nextPrayer = 'Asr';
      nextTime = asr;
    } else if (nowSaudi.isBefore(maghrib)) {
      currentPrayer = 'Asr';
      currentStart = asr;
      nextPrayer = 'Maghrib';
      nextTime = maghrib;
    } else if (nowSaudi.isBefore(isha)) {
      currentPrayer = 'Maghrib';
      currentStart = maghrib;
      nextPrayer = 'Isha';
      nextTime = isha;
    } else {
      currentPrayer = 'Isha';
      currentStart = isha;
      nextPrayer = 'Fajr';
      nextTime = fajr.add(const Duration(days: 1));
    }

    final Duration totalSegment = nextTime.difference(currentStart);
    final Duration remaining = nextTime.difference(nowSaudi);

    double reverseProgress = 0.0;
    if (totalSegment.inMilliseconds > 0) {
      reverseProgress = remaining.inMilliseconds / totalSegment.inMilliseconds;
      reverseProgress = reverseProgress.clamp(0.0, 1.0);
    }

    final Duration sinceCurrentPrayer = nowSaudi.difference(currentStart);
    final bool showInPrayerText = currentPrayer != 'Sunrise' &&
        sinceCurrentPrayer >= Duration.zero &&
        sinceCurrentPrayer <= const Duration(minutes: 25);

    _currentPrayerName = currentPrayer;
    _nextPrayerName = nextPrayer;
    _remaining = remaining.isNegative ? Duration.zero : remaining;
    _reverseProgress = reverseProgress;
    _statusText =
        showInPrayerText ? 'Сейчас идёт $currentPrayer' : 'Ближайшая молитва';

    _lastThirdStart = _calculateLastThirdStart(nowSaudi);
  }

  DateTime _calculateLastThirdStart(DateTime nowSaudi) {
    final DateTime fajr = _prayerTimes['Fajr']!;
    final DateTime maghrib = _prayerTimes['Maghrib']!;

    if (nowSaudi.isBefore(fajr)) {
      final DateTime previousMaghrib =
          maghrib.subtract(const Duration(days: 1));
      final Duration night = fajr.difference(previousMaghrib);
      return previousMaghrib.add(
        Duration(milliseconds: (night.inMilliseconds * 2 / 3).round()),
      );
    } else {
      final DateTime tomorrowFajr = fajr.add(const Duration(days: 1));
      final Duration night = tomorrowFajr.difference(maghrib);
      return maghrib.add(
        Duration(milliseconds: (night.inMilliseconds * 2 / 3).round()),
      );
    }
  }

  String _formatClock(DateTime time) {
    final String h = time.hour.toString().padLeft(2, '0');
    final String m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatDuration(Duration duration) {
    final int totalSeconds = duration.inSeconds < 0 ? 0 : duration.inSeconds;
    final int hours = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    final int seconds = totalSeconds % 60;

    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF08111B),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 24),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: SizedBox(
                  width: double.infinity,
                  child: AppHeader(
                    isDarkBackground: false,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 24),
              child: _CitySwitch(
                isMakkahSelected: false,
                onMakkahTap: () {
                  Navigator.of(context).pushReplacement(
                    PremiumRoute.push(const MekkaTimePage()),
                  );
                },
                onMadinahTap: () {},
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFA8F51C),
                      ),
                    )
                  : _errorText != null
                      ? _ErrorState(
                          message: _errorText!,
                          onRetry: () => _refreshOnline(silentIfCache: false),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                            24,
                            8,
                            24,
                            24,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              PrayerCountdownHero(
                                nextPrayerName: _nextPrayerName,
                                statusText: _statusText,
                                remainingText: _formatDuration(_remaining),
                                reverseProgress: _reverseProgress,
                              ),
                              const SizedBox(height: 18),
                              RichText(
                                text: const TextSpan(
                                  children: <InlineSpan>[
                                    TextSpan(
                                      text: 'Prayers',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 30,
                                        fontWeight: FontWeight.w800,
                                        height: 1,
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' Time',
                                      style: TextStyle(
                                        color: Color(0xFF7F8792),
                                        fontSize: 30,
                                        fontWeight: FontWeight.w400,
                                        height: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                              _PrayerListCard(
                                order: _order,
                                prayerTimes: _prayerTimes,
                                currentPrayerName: _currentPrayerName,
                                nextPrayerName: _nextPrayerName,
                                formatClock: _formatClock,
                              ),
                              const SizedBox(height: 16),
                              _InfoFooterCard(
                                title: 'Last Third Night ✨',
                                value: _lastThirdStart == null
                                    ? '--:--'
                                    : _formatClock(_lastThirdStart!),
                              ),
                              const SizedBox(height: 28),
                              Center(
                                child: Image.asset(
                                  'assets/images/pray_logo.png',
                                  width: 96,
                                  height: 96,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) =>
                                      const SizedBox(height: 96),
                                ),
                              ),
                              const SizedBox(height: 8),
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

class _PrayerListCard extends StatelessWidget {
  const _PrayerListCard({
    required this.order,
    required this.prayerTimes,
    required this.currentPrayerName,
    required this.nextPrayerName,
    required this.formatClock,
  });

  final List<String> order;
  final Map<String, DateTime> prayerTimes;
  final String currentPrayerName;
  final String nextPrayerName;
  final String Function(DateTime) formatClock;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.fromSTEB(22, 18, 22, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        color: Colors.white.withOpacity(0.08),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Column(
        children: order.map((String prayerName) {
          final DateTime? time = prayerTimes[prayerName];
          final bool isNext = prayerName == nextPrayerName;
          final bool isCurrent = prayerName == currentPrayerName;

          Color nameColor = Colors.white.withOpacity(0.78);
          FontWeight nameWeight = FontWeight.w400;

          if (isNext) {
            nameColor = const Color(0xFFA8F51C);
            nameWeight = FontWeight.w700;
          } else if (isCurrent) {
            nameColor = Colors.white;
            nameWeight = FontWeight.w600;
          }

          return Padding(
            padding: const EdgeInsetsDirectional.symmetric(vertical: 10),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    prayerName,
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      color: nameColor,
                      fontSize: 19,
                      fontStyle: FontStyle.italic,
                      fontWeight: nameWeight,
                    ),
                  ),
                ),
                Text(
                  time == null ? '--:--' : formatClock(time),
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    color: isNext ? const Color(0xFFA8F51C) : Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _InfoFooterCard extends StatelessWidget {
  const _InfoFooterCard({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.fromSTEB(22, 18, 22, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: Colors.white.withOpacity(0.08),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Row(
        children: <Widget>[
          const Text(
            '◉',
            style: TextStyle(
              color: Color(0xFFA8F51C),
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.start,
              style: const TextStyle(
                color: Color(0xFFA8F51C),
                fontSize: 18,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            textAlign: TextAlign.start,
            style: const TextStyle(
              color: Color(0xFFA8F51C),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CitySwitch extends StatelessWidget {
  const _CitySwitch({
    required this.isMakkahSelected,
    required this.onMakkahTap,
    required this.onMadinahTap,
  });

  final bool isMakkahSelected;
  final VoidCallback onMakkahTap;
  final VoidCallback onMadinahTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            color: Colors.white.withOpacity(0.08),
            border: Border.all(
              color: Colors.white.withOpacity(0.06),
              width: 1,
            ),
          ),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double thumbWidth = (constraints.maxWidth - 8) / 2;

              return Stack(
                children: <Widget>[
                  AnimatedPositionedDirectional(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    top: 4,
                    bottom: 4,
                    start: isMakkahSelected ? 4 : thumbWidth,
                    child: Container(
                      width: thumbWidth,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: const LinearGradient(
                          begin: AlignmentDirectional.centerStart,
                          end: AlignmentDirectional.centerEnd,
                          colors: <Color>[
                            Color(0xFFA8F51C),
                            Color(0xFF87D80A),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onMakkahTap,
                          child: Center(
                            child: Text(
                              'Makkah',
                              textAlign: TextAlign.start,
                              style: TextStyle(
                                color: isMakkahSelected
                                    ? const Color(0xFF0A131D)
                                    : Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onMadinahTap,
                          child: Center(
                            child: Text(
                              'Madinah',
                              textAlign: TextAlign.start,
                              style: TextStyle(
                                color: isMakkahSelected
                                    ? Colors.white
                                    : const Color(0xFF0A131D),
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsetsDirectional.fromSTEB(18, 12, 18, 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: const Color(0xFFA8F51C),
                ),
                child: const Text(
                  'Повторить',
                  style: TextStyle(
                    color: Color(0xFF08111B),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
