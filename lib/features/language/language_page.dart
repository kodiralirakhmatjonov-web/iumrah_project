import 'package:flutter/material.dart';
import 'package:iumrah_project/splash/onboarding_page.dart';

import '../../core/bootstrap/app_bootstrap.dart';
import '../../core/localization/local_strings.dart';
import '../../core/localization/translations_store.dart';
import '../../core/navigation/premium_route.dart';

class LanguagePage extends StatefulWidget {
  const LanguagePage({super.key});

  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  String? _selectedLang;
  bool _isLoading = false;

  // Язык UI на этой странице: если не выбран — показываем RU по умолчанию
  String get _Lang => _selectedLang ?? 'en';

  final List<Map<String, String>> _languages = const [
    {'code': 'en', 'label': 'English'},
    {'code': 'ru', 'label': 'Русский'},
    {'code': 'ar', 'label': 'العربية'},
    {'code': 'fr', 'label': 'Français'},
    {'code': 'tr', 'label': 'Türkçe'},
    {'code': 'id', 'label': 'Bahasa Indonesia'},
    {'code': 'ms', 'label': 'Bahasa Melayu'},
    {'code': 'uz', 'label': "O‘zbek"},
    {'code': 'kk', 'label': 'Қазақ'},
    {'code': 'bn', 'label': 'বাংলা'},
  ];

  Future<void> _continue() async {
    if (_selectedLang == null || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      await AppBootstrap.setLanguage(_selectedLang!);

      // Жёсткая проверка: только если реально готово — уходим на Home
      if (!TranslationsStore.isReady) {
        throw Exception('Store not ready after load');
      }

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        PremiumRoute.push(const OnboardingPage()),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 3),
          content: Text(LocalStrings.t('lang_load_error', _Lang)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = _selectedLang != null && !_isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFE6E6EF),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 48),
            Image.asset(
              'assets/images/iumrah_logo.png',
              height: 80,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            Text(
              LocalStrings.t('lang_title', _Lang),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: ListView.builder(
                  itemCount: _languages.length,
                  itemBuilder: (context, index) {
                    final item = _languages[index];
                    final code = item['code']!;
                    final label = item['label']!;
                    final selected = _selectedLang == code;

                    return GestureDetector(
                      onTap: _isLoading
                          ? null
                          : () => setState(() => _selectedLang = code),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey),
                                color: selected
                                    ? Colors.green
                                    : Colors.transparent,
                              ),
                              child: selected
                                  ? const Icon(Icons.check,
                                      size: 16, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              label,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: canContinue ? _continue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        canContinue ? Colors.green : Colors.grey.shade400,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          LocalStrings.t('continue_btn', _Lang),
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white),
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
