import 'dart:math';
import 'package:flutter/material.dart';
import 'package:iumrah_project/core/localization/local_strings.dart';
import 'package:iumrah_project/features/language/language_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:iumrah_project/core/navigation/premium_route.dart';

class RegNamePage extends StatefulWidget {
  const RegNamePage({super.key});

  @override
  State<RegNamePage> createState() => _RegNamePageState();
}

class _RegNamePageState extends State<RegNamePage> {
  final _nameController = TextEditingController();
  final _countryController = TextEditingController();

  final supabase = Supabase.instance.client;

  String _iumrahId = '';
  bool _loading = false;

  static const Set<String> _supportedLangs = {
    'ru',
    'uz',
    'kk',
    'id',
    'tr',
    'ms',
    'bn',
    'en',
    'fr',
  };

  String get lang {
    final deviceLang =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    return _supportedLangs.contains(deviceLang) ? deviceLang : 'en';
  }

  @override
  void initState() {
    super.initState();
    _generateIumrahId();
  }

  void _generateIumrahId() {
    final rand = Random();
    _iumrahId = List.generate(10, (_) => rand.nextInt(10)).join(); // 10 цифр
  }

  Future<void> _submit() async {
    if (_nameController.text.isEmpty || _countryController.text.isEmpty) {
      return;
    }

    setState(() => _loading = true);

    final user = supabase.auth.currentUser;

    await supabase.from('profiles').upsert({
      'user_id': user!.id,
      'name': _nameController.text.trim(),
      'country': _countryController.text.trim(),
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_name', _nameController.text.trim());
    await prefs.setString('profile_country', _countryController.text.trim());
    await prefs.setString('iumrah_id', _iumrahId);

    setState(() => _loading = false);

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PremiumRoute.push(const LanguagePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filled =
        _nameController.text.isNotEmpty && _countryController.text.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 30),

              /// ===== HEADER =====
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset(
                    'assets/images/iumrah_id2.png',
                    height: 60,
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 30,
                        color: Colors.black,
                      ),
                    ),
                  )
                ],
              ),

              const SizedBox(height: 70),

              /// ===== CARD =====
              Container(
                width: 324,
                height: 186,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    colors: [
                      Color.fromARGB(255, 0, 0, 0),
                      Color.fromARGB(255, 0, 0, 0),
                    ],
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xFF07E2FF),
                      blurRadius: 25,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset(
                      'assets/images/iumrah_id2.png',
                      height: 30,
                    ),
                    const Spacer(),
                    if (filled)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _nameController.text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _countryController.text.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 60),

              /// ===== FORM =====
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: LocalStrings.t('profile_name_label', lang),
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(
                            Radius.circular(50),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _countryController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: LocalStrings.t('profile_country_label', lang),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(
                            Radius.circular(50),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 70,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                        child: _loading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                LocalStrings.t('continue_btn', lang),
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
