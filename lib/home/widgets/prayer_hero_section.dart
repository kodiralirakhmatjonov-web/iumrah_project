import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:iumrah_project/home/widgets/prayer_countdown_hero.dart';

enum PrayerCity {
  makkah,
  madinah,
}

class PrayerHeroSection extends StatefulWidget {
  const PrayerHeroSection({
    super.key,
    required this.city,
  });

  final PrayerCity city;

  @override
  State<PrayerHeroSection> createState() => _PrayerHeroSectionState();
}

class _PrayerHeroSectionState extends State<PrayerHeroSection> {
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

  String get _cityKey {
    switch (widget.city) {
      case PrayerCity.makkah:
        return 'makkah';
      case PrayerCity.madinah:
        return 'madinah';
    }
  }

  String get _cityName {
    switch (widget.city) {
      case PrayerCity.makkah:
        return 'Makkah';
      case PrayerCity.madinah:
        return 'Madinah';
    }
  }

  @override
  void initState() {
    super.initState();
    _initWidget();
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

  Future<void> _initWidget() async {
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
    if (_isLoading) {
      return const SizedBox(
        height: 150,
        child: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFA8F51C),
          ),
        ),
      );
    }

    if (_errorText != null && _prayerTimes.isEmpty) {
      return SizedBox(
        height: 150,
        child: Center(
          child: Text(
            _errorText!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return PrayerCountdownHero(
      nextPrayerName: _nextPrayerName,
      statusText: _statusText,
      remainingText: _formatDuration(_remaining),
      reverseProgress: _reverseProgress,
    );
  }
}
