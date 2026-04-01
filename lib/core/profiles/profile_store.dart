import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileStore {
  static final ValueNotifier<ProfileData> notifier =
      ValueNotifier(ProfileData.empty());

  static String _key(String base, String userId) => '${base}_$userId';

  /// ================== LOAD ==================
  /// Загружает профиль ТОЛЬКО текущего пользователя
  static Future<void> load() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      notifier.value = ProfileData.empty();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final uid = user.id;

    final name = prefs.getString(_key('profile_name', uid)) ?? '';
    final email = prefs.getString(_key('profile_email', uid)) ?? '';
    final avatar =
        prefs.getString(_key('profile_avatar_key', uid)) ?? 'male_01';

    notifier.value = ProfileData(
      name: name,
      email: email,
      avatarKey: avatar,
    );
  }

  /// ================== UPDATE ==================
  /// Обновляет и кэш и UI
  static Future<void> update(ProfileData data) async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    final uid = user.id;

    await prefs.setString(_key('profile_name', uid), data.name);
    await prefs.setString(_key('profile_email', uid), data.email);
    await prefs.setString(_key('profile_avatar_key', uid), data.avatarKey);

    notifier.value = data;
  }

  /// ================== CLEAR ==================
  /// Полная очистка ТЕКУЩЕГО пользователя
  static Future<void> clear() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      final uid = user.id;

      await prefs.remove(_key('profile_name', uid));
      await prefs.remove(_key('profile_email', uid));
      await prefs.remove(_key('profile_avatar_key', uid));
    }

    notifier.value = ProfileData.empty();
  }

  /// ================== HARD RESET ==================
  /// 🔥 Один раз вызвать при обновлении версии (чтобы убить старые ключи)
  static Future<void> clearLegacyKeys() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('profile_name');
    await prefs.remove('profile_email');
    await prefs.remove('profile_avatar_key');
    await prefs.remove('profile_country');
    await prefs.remove('profile_gender');
    await prefs.remove('iumrah_id');
  }
}

class ProfileData {
  final String name;
  final String email;
  final String avatarKey;

  const ProfileData({
    required this.name,
    required this.email,
    required this.avatarKey,
  });

  factory ProfileData.empty() {
    return const ProfileData(
      name: '',
      email: '',
      avatarKey: 'male_01',
    );
  }
}
