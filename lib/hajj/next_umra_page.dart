import 'package:flutter/material.dart';
import 'package:iumrah_project/core/localization/translations_store.dart';
import 'package:iumrah_project/home/widgets/app_header.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NextUmrahPage extends StatefulWidget {
  const NextUmrahPage({super.key});

  @override
  State<NextUmrahPage> createState() => _NextUmrahPageState();
}

class _NextUmrahPageState extends State<NextUmrahPage> {
  static const String _prefsNextUmrahDateKey = 'next_umrah_date';
  static const String _prefsNextUmrahGoalKey = 'next_umrah_goal';

  final TextEditingController _goalController = TextEditingController();

  DateTime? _selectedDate;
  bool _saving = false;

  String t(String key, String fallback) {
    final value = TranslationsStore.get(key);
    if (value.trim().isEmpty || value == key) return fallback;
    return value;
  }

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();

    final rawDate = prefs.getString(_prefsNextUmrahDateKey);
    final goal = prefs.getString(_prefsNextUmrahGoalKey) ?? '';

    DateTime? parsed;
    if (rawDate != null && rawDate.isNotEmpty) {
      final date = DateTime.tryParse(rawDate);
      if (date != null) {
        parsed = DateTime(date.year, date.month, date.day);
      }
    }

    if (!mounted) return;

    setState(() {
      _selectedDate = parsed;
      _goalController.text = goal;
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final initialDate =
        (_selectedDate != null && !_selectedDate!.isBefore(today))
            ? _selectedDate!
            : today;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: DateTime(today.year + 10, 12, 31),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF07E2FF),
              onPrimary: Color(0xFF041019),
              surface: Color(0xFF131B25),
              onSurface: Colors.black,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFF131B25),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF07E2FF),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    setState(() {
      _selectedDate = DateTime(picked.year, picked.month, picked.day);
    });
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day.$month.$year';
  }

  Future<void> _save() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t(
              'next_umrah_pick_date_error',
              'Сначала выберите дату следующей умры',
            ),
          ),
        ),
      );
      return;
    }

    if (_selectedDate!.isBefore(today)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t(
              'next_umrah_past_date_error',
              'Нельзя выбрать дату раньше сегодняшнего дня',
            ),
          ),
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsNextUmrahDateKey,
      _selectedDate!.toIso8601String(),
    );
    await prefs.setString(
      _prefsNextUmrahGoalKey,
      _goalController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _saving = false;
    });

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final dateText = _selectedDate == null
        ? t('next_umrah_pick_date', 'Выберите дату')
        : _formatDate(_selectedDate!);

    return Scaffold(
      backgroundColor: const Color(0xFF050A12),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF050A12),
                gradient: RadialGradient(
                  center: Alignment(0.0, -0.28),
                  radius: 1.08,
                  colors: [
                    Color(0xC907E2FF),
                    Color(0x6607E2FF),
                    Color(0x1C07E2FF),
                    Color(0x0007E2FF),
                  ],
                  stops: [0.0, 0.32, 0.62, 1.0],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x00050A12),
                      Color(0x22050A12),
                      Color(0x90050A12),
                      Color(0xFF050A12),
                    ],
                    stops: [0.0, 0.35, 0.72, 1.0],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsetsDirectional.fromSTEB(24, 10, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppHeader(isDarkBackground: false),
                  const SizedBox(height: 28),
                  Text(
                    t('next_umrah_title', 'Следующая умра'),
                    textAlign: TextAlign.start,
                    style: const TextStyle(
                      fontFamily: 'Lato',
                      fontWeight: FontWeight.w800,
                      fontSize: 34,
                      height: 1.05,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    t(
                      'next_umrah_subtitle',
                      'Выберите примерную дату и зафиксируйте личную цель. Прошлую дату выбрать нельзя.',
                    ),
                    textAlign: TextAlign.start,
                    style: const TextStyle(
                      fontFamily: 'Lato',
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      height: 1.35,
                      color: Color(0xCCFFFFFF),
                    ),
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(20, 18, 20, 18),
                      decoration: BoxDecoration(
                        color: const Color(0x14FFFFFF),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: const Color(0x2607E2FF),
                          width: 1,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1207E2FF),
                            blurRadius: 18,
                            spreadRadius: 0,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t(
                                    'next_umrah_date_label',
                                    'Дата следующей умры',
                                  ),
                                  textAlign: TextAlign.start,
                                  style: const TextStyle(
                                    fontFamily: 'Lato',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: Color(0xB3FFFFFF),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  dateText,
                                  textAlign: TextAlign.start,
                                  style: TextStyle(
                                    fontFamily: 'Lato',
                                    fontWeight: FontWeight.w800,
                                    fontSize: 22,
                                    color: _selectedDate == null
                                        ? const Color(0x80FFFFFF)
                                        : Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.calendar_month_rounded,
                            size: 28,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsetsDirectional.fromSTEB(18, 14, 18, 14),
                    decoration: BoxDecoration(
                      color: const Color(0x14FFFFFF),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: const Color(0x2607E2FF),
                        width: 1,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1207E2FF),
                          blurRadius: 18,
                          spreadRadius: 0,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t('next_umrah_goal_label', 'Моя цель'),
                          textAlign: TextAlign.start,
                          style: const TextStyle(
                            fontFamily: 'Lato',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Color(0xB3FFFFFF),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _goalController,
                          minLines: 4,
                          maxLines: 6,
                          keyboardAppearance: Brightness.dark,
                          cursorColor: const Color(0xFF07E2FF),
                          style: const TextStyle(
                            fontFamily: 'Lato',
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                          decoration: InputDecoration(
                            isCollapsed: true,
                            border: InputBorder.none,
                            hintText: t(
                              'next_umrah_goal_hint',
                              'Например: совершить следующую умру осознанно, спокойно и без спешки',
                            ),
                            hintStyle: const TextStyle(
                              fontFamily: 'Lato',
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                              height: 1.35,
                              color: Color(0x66FFFFFF),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    t(
                      'next_umrah_note',
                      'Можно выбрать только сегодняшнюю или будущую дату.',
                    ),
                    textAlign: TextAlign.start,
                    style: const TextStyle(
                      fontFamily: 'Lato',
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      color: Color(0x99FFFFFF),
                    ),
                  ),
                  const SizedBox(height: 30),
                  GestureDetector(
                    onTap: _saving ? null : _save,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 180),
                      opacity: _saving ? 0.82 : 1,
                      child: Container(
                        width: double.infinity,
                        height: 62,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: AlignmentDirectional.centerStart,
                            end: AlignmentDirectional.centerEnd,
                            colors: [
                              Color(0xFF45F7FF),
                              Color(0xFF07E2FF),
                              Color(0xFF008CFF),
                            ],
                            stops: [0.0, 0.52, 1.0],
                          ),
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x5507E2FF),
                              blurRadius: 24,
                              spreadRadius: 0,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        alignment: AlignmentDirectional.center,
                        child: _saving
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Text(
                                t('next_umrah_save', 'Сохранить цель'),
                                textAlign: TextAlign.start,
                                style: const TextStyle(
                                  fontFamily: 'Lato',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
