import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:iumrah_project/home/profile_page.dart';

import '../../core/bootstrap/app_bootstrap.dart';
import '../../core/localization/local_strings.dart';
import '../../core/localization/translations_store.dart';
import '../../core/navigation/premium_route.dart';

class LanguageModal extends StatefulWidget {
  const LanguageModal({super.key});

  @override
  State<LanguageModal> createState() => _LanguageModalState();
}

class _LanguageModalState extends State<LanguageModal> {
  String? _selectedLang;
  bool _isLoading = false;

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

  Future<void> _loadAudio(String lang) async {}

  Future<void> _continue() async {
    if (_selectedLang == null || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      await AppBootstrap.setLanguage(_selectedLang!);
      await _loadAudio(_selectedLang!);

      if (!TranslationsStore.isReady) {
        throw Exception('Store not ready');
      }

      if (!mounted) return;

      Navigator.of(context).pop(); // ✅ закрываем модалку

      Navigator.of(context).pushReplacement(
        PremiumRoute.push(const ProfilePage()),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocalStrings.t('lang_load_error', _Lang)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = _selectedLang != null && !_isLoading;

    return WillPopScope(
      onWillPop: () async => !_isLoading, // 🔒 блок назад
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.9,
        minChildSize: 0.9,
        builder: (_, controller) {
          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFFE6E6EF),
              borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 50),

                  Text(
                    LocalStrings.t('lang_title', _Lang),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      height: 1.0,
                      letterSpacing: -0.9,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ===== LIST =====
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: ListView.builder(
                        controller: controller,
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

                  // ===== BUTTON =====
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
                            ? const CupertinoActivityIndicator(radius: 14)
                            : Text(
                                LocalStrings.t('continue_btn', _Lang),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
