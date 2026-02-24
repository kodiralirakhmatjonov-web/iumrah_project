import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PremiumService {
  static const String _premiumKey = 'is_premium';

  /// 🔹 Проверка локального premium (Offline Mode)
  static Future<bool> isPremium() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_premiumKey) ?? false;
  }

  /// 🔹 Синхронизация premium статуса с Supabase (Online Mode)
  static Future<void> syncPremiumStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final supabase = Supabase.instance.client;

    final user = supabase.auth.currentUser;
    if (user == null) return;

    final response = await supabase
        .from('profiles')
        .select('is_premium')
        .eq('user_id', user.id) // ✅ ТВОЯ КОЛОНКА!
        .single();

    final bool isPremium = response['is_premium'] ?? false;

    await prefs.setBool(_premiumKey, isPremium);
  }

  /// 🔹 АКТИВАЦИЯ Premium после успешной покупки
  static Future<void> activatePremium() async {
    final prefs = await SharedPreferences.getInstance();
    final supabase = Supabase.instance.client;

    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase
        .from('profiles')
        .update({'is_premium': true}).eq('user_id', user.id); // ✅ ТВОЯ КОЛОНКА!

    await prefs.setBool(_premiumKey, true);
  }

  /// 🔹 Сброс (на будущее если будет Restore Purchase)
  static Future<void> deactivatePremium() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumKey, false);
  }
}
