import 'dart:math';

import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iumrah_project/core/localization/local_strings.dart';
import 'package:iumrah_project/core/navigation/premium_route.dart';
import 'package:iumrah_project/features/language/language_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegNamePage extends StatefulWidget {
  const RegNamePage({super.key});

  @override
  State<RegNamePage> createState() => _RegNamePageState();
}

class _RegNamePageState extends State<RegNamePage> {
  final TextEditingController _nameController = TextEditingController();
  final SupabaseClient supabase = Supabase.instance.client;

  bool _loading = false;
  bool _profileLoaded = false;

  String _iumrahId = '';
  String _selectedGender = 'male';
  String _selectedAvatarKey = 'male_01';
  String _selectedCountry = '';
  String _email = '';

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

  static const List<String> _maleAvatars = [
    'male_01',
    'male_02',
  ];

  static const List<String> _femaleAvatars = [
    'female_01',
    'female_02',
    'female_03',
  ];

  String get lang {
    final String deviceLang =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    return _supportedLangs.contains(deviceLang) ? deviceLang : 'en';
  }

  @override
  void initState() {
    super.initState();
    _generateIumrahId();
    _initPage();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _initPage() async {
    final session = supabase.auth.currentSession;
    _email = session?.user.email ?? '';

    await _loadProfileFromDbOnly();

    if (!mounted) return;
    setState(() {
      _profileLoaded = true;
    });
  }

  void _generateIumrahId() {
    final Random rand = Random();
    _iumrahId = List.generate(10, (_) => rand.nextInt(10)).join();
  }

  String _randomAvatarForGender(String gender) {
    final Random random = Random();
    final List<String> source =
        gender == 'female' ? _femaleAvatars : _maleAvatars;
    return source[random.nextInt(source.length)];
  }

  String _avatarAssetByKey(String key) {
    if (key.startsWith('male_')) {
      return 'assets/profile/avatars/male/$key.png';
    }
    if (key.startsWith('female_')) {
      return 'assets/profile/avatars/female/$key.png';
    }
    return 'assets/profile/avatars/male/male_01.png';
  }

  String _previewName() {
    final String value = _nameController.text.trim();
    return value.isEmpty ? LocalStrings.t('profile_your_name', lang) : value;
  }

  String _maleLabel() {
    return LocalStrings.t('profile_gender_male', lang);
  }

  String _femaleLabel() {
    return LocalStrings.t('profile_gender_female', lang);
  }

  Future<void> _loadProfileFromDbOnly() async {
    final User? user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final Map<String, dynamic>? data = await supabase
          .from('profiles')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (data != null) {
        final String dbName = (data['name'] ?? '').toString();
        final String dbCountry = (data['country'] ?? '').toString();

        final String dbGenderRaw = (data['gender'] ?? '').toString();
        final String dbGender = dbGenderRaw == 'female' || dbGenderRaw == 'male'
            ? dbGenderRaw
            : 'male';

        final String dbAvatarKeyRaw = (data['avatar_key'] ?? '').toString();
        final String dbAvatarKey = dbAvatarKeyRaw.isNotEmpty
            ? dbAvatarKeyRaw
            : _randomAvatarForGender(dbGender);

        final String dbIumrahIdRaw = (data['iumrah_id'] ?? '').toString();
        final String dbIumrahId =
            dbIumrahIdRaw.isNotEmpty ? dbIumrahIdRaw : _iumrahId;

        _nameController.text = dbName;
        _selectedCountry = dbCountry;
        _selectedGender = dbGender;
        _selectedAvatarKey = dbAvatarKey;
        _iumrahId = dbIumrahId;
      } else {
        _selectedGender = 'male';
        _selectedAvatarKey = _randomAvatarForGender(_selectedGender);
      }
    } catch (e) {
      debugPrint('LOAD PROFILE ERROR: $e');
      _selectedGender = 'male';
      _selectedAvatarKey = _randomAvatarForGender(_selectedGender);
    }
  }

  Future<void> _pickCountry() async {
    showCountryPicker(
      context: context,
      showPhoneCode: false,
      countryListTheme: CountryListThemeData(
        backgroundColor: Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28),
        ),
        inputDecoration: InputDecoration(
          hintText: LocalStrings.t('profile_country_label', lang),
          filled: true,
          fillColor: const Color(0xFFF7F6F2),
          contentPadding: const EdgeInsetsDirectional.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide.none,
          ),
          prefixIcon: const Icon(Icons.search_rounded),
        ),
      ),
      onSelect: (Country country) {
        setState(() {
          _selectedCountry = country.name;
        });
      },
    );
  }

  void _selectGender(String gender) {
    if (_selectedGender == gender) return;

    setState(() {
      _selectedGender = gender;
      _selectedAvatarKey = _randomAvatarForGender(gender);
    });
  }

  Future<void> _copyIumrahId() async {
    await Clipboard.setData(ClipboardData(text: _iumrahId));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(LocalStrings.t('copied_btn', lang)),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _submit() async {
    if (_loading) return;

    final String name = _nameController.text.trim();
    final String country = _selectedCountry.trim();
    final User? user = supabase.auth.currentUser;

    if (name.isEmpty || country.isEmpty || user == null) return;

    setState(() => _loading = true);

    try {
      final Map<String, dynamic>? res = await supabase
          .from('profiles')
          .upsert(
            {
              'user_id': user.id,
              'name': name,
              'country': country,
              'gender': _selectedGender,
              'avatar_key': _selectedAvatarKey,
              'iumrah_id': _iumrahId,
              'updated_at': DateTime.now().toIso8601String(),
            },
            onConflict: 'user_id',
          )
          .select()
          .maybeSingle();

      if (res == null) {
        throw Exception('Save failed');
      }

      final String savedGenderRaw =
          (res['gender'] ?? _selectedGender).toString();
      _selectedGender = savedGenderRaw == 'female' || savedGenderRaw == 'male'
          ? savedGenderRaw
          : 'male';

      final String savedAvatarKeyRaw =
          (res['avatar_key'] ?? _selectedAvatarKey).toString();
      if (savedAvatarKeyRaw.isNotEmpty) {
        _selectedAvatarKey = savedAvatarKeyRaw;
      }

      final String savedIumrahIdRaw =
          (res['iumrah_id'] ?? _iumrahId).toString();
      if (savedIumrahIdRaw.isNotEmpty) {
        _iumrahId = savedIumrahIdRaw;
      }

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        PremiumRoute.push(const LanguagePage()),
      );
    } catch (e) {
      debugPrint('SUBMIT ERROR: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ошибка сохранения профиля'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canContinue = _nameController.text.trim().isNotEmpty &&
        _selectedCountry.trim().isNotEmpty &&
        !_loading;

    return Stack(
      children: [
        AbsorbPointer(
          absorbing: _loading,
          child: Scaffold(
            backgroundColor: const Color(0xFFe6e6ef),
            body: SafeArea(
              child: !_profileLoaded
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(24, 18, 24, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Image.asset(
                                'assets/images/iumrah_logo.png',
                                height: 85,
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  height: 50,
                                  width: 50,
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
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                18, 20, 18, 18),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDFCF8),
                              borderRadius: BorderRadius.circular(40),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 82,
                                  height: 82,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFFF3F1EA),
                                    image: DecorationImage(
                                      image: AssetImage(
                                        _avatarAssetByKey(_selectedAvatarKey),
                                      ),
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  _previewName(),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFF4A4A54),
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _email.isEmpty ? '—' : _email,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFF9D9A92),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Container(
                                  height: 52,
                                  padding: const EdgeInsetsDirectional.all(4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F1EA),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: _GenderButton(
                                          title: _maleLabel(),
                                          selected: _selectedGender == 'male',
                                          selectedColor:
                                              const Color(0xFF2C8CFF),
                                          onTap: () => _selectGender('male'),
                                        ),
                                      ),
                                      Expanded(
                                        child: _GenderButton(
                                          title: _femaleLabel(),
                                          selected: _selectedGender == 'female',
                                          selectedColor:
                                              const Color(0xFFE46BD7),
                                          onTap: () => _selectGender('female'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          _InputLabel(
                            text: LocalStrings.t('profile_name_label', lang),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFBFAF5),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            alignment: AlignmentDirectional.centerStart,
                            padding: const EdgeInsetsDirectional.symmetric(
                                horizontal: 20),
                            child: TextField(
                              controller: _nameController,
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText:
                                    LocalStrings.t('profile_your_name', lang),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          _InputLabel(
                            text: LocalStrings.t('profile_country_label', lang),
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: _pickCountry,
                            child: Container(
                              height: 60,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFBFAF5),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: const EdgeInsetsDirectional.symmetric(
                                  horizontal: 20),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _selectedCountry.isEmpty
                                          ? LocalStrings.t(
                                              'profile_country_label', lang)
                                          : _selectedCountry,
                                    ),
                                  ),
                                  const Icon(Icons.menu_rounded),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          _InputLabel(
                            text: LocalStrings.t('profile_id_label', lang),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFBFAF5),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsetsDirectional.symmetric(
                                horizontal: 20),
                            child: Row(
                              children: [
                                Expanded(child: Text(_iumrahId)),
                                GestureDetector(
                                  onTap: _copyIumrahId,
                                  child: Text(LocalStrings.t('copy_btn', lang)),
                                )
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 64,
                            child: ElevatedButton(
                              onPressed: canContinue ? _submit : null,
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor:
                                    const Color.fromARGB(255, 0, 0, 0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(32),
                                ),
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color:
                                            Color.fromARGB(255, 255, 255, 255),
                                      ),
                                    )
                                  : Text(
                                      LocalStrings.t('continue_btn', lang),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
        if (_loading) Container(color: Colors.black.withOpacity(0.1)),
      ],
    );
  }
}

class _InputLabel extends StatelessWidget {
  final String text;

  const _InputLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(text);
  }
}

class _GenderButton extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;
  final Color selectedColor;

  const _GenderButton({
    required this.title,
    required this.selected,
    required this.onTap,
    required this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? selectedColor : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Text(title),
      ),
    );
  }
}
