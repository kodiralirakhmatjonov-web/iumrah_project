import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iumrah_project/core/profiles/profile_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage>
    with SingleTickerProviderStateMixin {
  final SupabaseClient supabase = Supabase.instance.client;

  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();

  bool _isSaving = false;

  String _gender = 'male';
  String _avatarKey = 'male_01';
  String _email = '';

  static const List<String> _maleAvatars = [
    'male_01',
    'male_02',
  ];

  static const List<String> _femaleAvatars = [
    'female_01',
    'female_02',
    'female_03',
  ];

  @override
  void initState() {
    super.initState();

    final profile = ProfileStore.notifier.value;
    _nameController.text = profile.name;
    _avatarKey = profile.avatarKey.isEmpty ? 'male_01' : profile.avatarKey;
    _email = profile.email;

    if (_avatarKey.startsWith('female_')) {
      _gender = 'female';
    } else {
      _gender = 'male';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  List<String> get _avatars =>
      _gender == 'female' ? _femaleAvatars : _maleAvatars;

  String _avatarPath(String key) {
    if (key.startsWith('male_')) {
      return 'assets/profile/avatars/male/$key.png';
    }
    if (key.startsWith('female_')) {
      return 'assets/profile/avatars/female/$key.png';
    }
    return 'assets/profile/avatars/male/male_01.png';
  }

  Future<void> _focusName() async {
    await HapticFeedback.selectionClick();
    if (!mounted) return;
    _nameFocusNode.requestFocus();
    _nameController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _nameController.text.length,
    );
  }

  Future<void> _selectGender(String gender) async {
    if (_gender == gender) return;

    await HapticFeedback.selectionClick();

    setState(() {
      _gender = gender;
      final list = _avatars;
      if (!list.contains(_avatarKey)) {
        _avatarKey = list.first;
      }
    });
  }

  Future<void> _selectAvatar(String key) async {
    if (_avatarKey == key) return;

    await HapticFeedback.selectionClick();

    setState(() {
      _avatarKey = key;
    });
  }

  Future<void> _save() async {
    if (_isSaving) return;

    final User? user = supabase.auth.currentUser;
    if (user == null) return;

    final String name = _nameController.text.trim();
    if (name.isEmpty) {
      await HapticFeedback.heavyImpact();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter your name'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    await HapticFeedback.mediumImpact();

    try {
      await supabase.from('profiles').upsert(
        {
          'user_id': user.id,
          'name': name,
          'gender': _gender,
          'avatar_key': _avatarKey,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id',
      );

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String uid = user.id;
      final String email = supabase.auth.currentSession?.user.email ??
          supabase.auth.currentUser?.email ??
          _email;

      await prefs.setString('profile_name_$uid', name);
      await prefs.setString('profile_email_$uid', email);
      await prefs.setString('profile_avatar_key_$uid', _avatarKey);
      await prefs.setString('profile_gender_$uid', _gender);
      await prefs.setBool('profile_loaded_$uid', true);

      await ProfileStore.update(
        ProfileData(
          name: name,
          email: email,
          avatarKey: _avatarKey,
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('EDIT PROFILE SAVE ERROR: $e');
      await HapticFeedback.heavyImpact();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save profile'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String displayName = _nameController.text.trim().isEmpty
        ? 'Your name'
        : _nameController.text.trim();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFE9E8F0),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),

              /// HEADER
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 0),
                child: Row(
                  children: [
                    _PremiumCircleButton(
                      size: 52,
                      backgroundColor: const Color(0xFFF7F6F1),
                      icon: Icons.close_rounded,
                      iconColor: const Color(0xFFB8B6AF),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                      },
                    ),
                    const Spacer(),
                    Image.asset(
                      'assets/images/iumrah_logo.png',
                      height: 70,
                      fit: BoxFit.contain,
                    ),
                    const Spacer(),
                    _PremiumCircleButton(
                      size: 52,
                      backgroundColor: const Color(0xFF93E313),
                      icon: _isSaving ? null : Icons.check_rounded,
                      iconColor: Colors.white,
                      onTap: _save,
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CupertinoActivityIndicator(
                                radius: 15,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 50),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 24),
                  child: Column(
                    children: [
                      /// TOP CARD
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsetsDirectional.fromSTEB(
                            18, 18, 18, 18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F6F1),
                          borderRadius: BorderRadius.circular(34),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.035),
                              blurRadius: 22,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFEDEBE4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  _avatarPath(_avatarKey),
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) {
                                    return const Icon(
                                      Icons.person_rounded,
                                      size: 38,
                                      color: Color(0xFFB5B2A9),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 220),
                                    child: TextField(
                                      controller: _nameController,
                                      focusNode: _nameFocusNode,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontFamily: 'Lato',
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF45434B),
                                        height: 1.1,
                                      ),
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        border: InputBorder.none,
                                        contentPadding:
                                            EdgeInsetsDirectional.zero,
                                        hintText: 'Your name',
                                        hintStyle: TextStyle(
                                          fontFamily: 'Lato',
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF45434B),
                                        ),
                                      ),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                _PremiumTinyIconButton(
                                  onTap: _focusName,
                                  icon: Icons.edit_outlined,
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _email.isEmpty ? '—' : _email,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Lato',
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF9A978F),
                                height: 1.15,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      /// GENDER SWITCH
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsetsDirectional.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1EFE8),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _GenderSegmentButton(
                                title: 'Мужчины',
                                selected: _gender == 'male',
                                selectedColor: const Color(0xFF138CFF),
                                onTap: () => _selectGender('male'),
                              ),
                            ),
                            Expanded(
                              child: _GenderSegmentButton(
                                title: 'Женщины',
                                selected: _gender == 'female',
                                selectedColor: const Color(0xFFE55FCE),
                                onTap: () => _selectGender('female'),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      /// AVATAR GRID
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsetsDirectional.fromSTEB(
                            14, 14, 14, 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1EFE8),
                          borderRadius: BorderRadius.circular(34),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.025),
                              blurRadius: 16,
                              offset: const Offset(0, 7),
                            ),
                          ],
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 240),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeOutCubic,
                          child: GridView.builder(
                            key: ValueKey<String>(_gender),
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _avatars.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              mainAxisSpacing: 14,
                              crossAxisSpacing: 14,
                              childAspectRatio: 1,
                            ),
                            itemBuilder: (context, index) {
                              final String key = _avatars[index];
                              final bool selected = key == _avatarKey;

                              return _AvatarTile(
                                imagePath: _avatarPath(key),
                                selected: selected,
                                onTap: () => _selectAvatar(key),
                              );
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      /// NAME PREVIEW SPACER FEEL
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 180),
                        opacity: displayName == 'Your name' ? 0.0 : 1.0,
                        child: const SizedBox(height: 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumCircleButton extends StatelessWidget {
  final double size;
  final Color backgroundColor;
  final IconData? icon;
  final Color iconColor;
  final VoidCallback onTap;
  final Widget? child;

  const _PremiumCircleButton({
    required this.size,
    required this.backgroundColor,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return _PremiumTap(
      onTap: onTap,
      borderRadius: BorderRadius.circular(size / 2),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.85),
              blurRadius: 1,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        alignment: AlignmentDirectional.center,
        child: child ??
            Icon(
              icon,
              color: iconColor,
              size: 28,
            ),
      ),
    );
  }
}

class _PremiumTinyIconButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;

  const _PremiumTinyIconButton({
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return _PremiumTap(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 24,
        height: 24,
        alignment: AlignmentDirectional.center,
        child: Icon(
          icon,
          size: 18,
          color: const Color(0xFF96938B),
        ),
      ),
    );
  }
}

class _GenderSegmentButton extends StatelessWidget {
  final String title;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _GenderSegmentButton({
    required this.title,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _PremiumTap(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        height: 46,
        alignment: AlignmentDirectional.center,
        decoration: BoxDecoration(
          color: selected ? selectedColor : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: selectedColor.withOpacity(0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Lato',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: selected
                ? Colors.white
                : const Color(0xFF9D998F).withOpacity(0.92),
          ),
        ),
      ),
    );
  }
}

class _AvatarTile extends StatelessWidget {
  final String imagePath;
  final bool selected;
  final VoidCallback onTap;

  const _AvatarTile({
    required this.imagePath,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _PremiumTap(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFF7F6F1),
          border: Border.all(
            color: selected ? const Color(0xFF3B3A3E) : Colors.transparent,
            width: 1.6,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(selected ? 0.07 : 0.03),
              blurRadius: selected ? 16 : 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsetsDirectional.all(6),
        child: ClipOval(
          child: Image.asset(
            imagePath,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) {
              return const ColoredBox(
                color: Color(0xFFE6E2D9),
                child: Icon(
                  Icons.person_rounded,
                  color: Color(0xFFB8B4AB),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PremiumTap extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final BorderRadius borderRadius;

  const _PremiumTap({
    required this.child,
    required this.onTap,
    required this.borderRadius,
  });

  @override
  State<_PremiumTap> createState() => _PremiumTapState();
}

class _PremiumTapState extends State<_PremiumTap> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        scale: _pressed ? 0.97 : 1,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          opacity: _pressed ? 0.92 : 1,
          child: ClipRRect(
            borderRadius: widget.borderRadius,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
