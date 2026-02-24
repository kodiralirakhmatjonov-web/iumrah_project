import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyDuaStore {
  static const String _key = 'my_dua_notes';

  final ValueNotifier<List<String>> notes = ValueNotifier<List<String>>([]);

  MyDuaStore() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_key);
    if (saved != null) {
      notes.value = saved;
    } else {
      notes.value = [];
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, notes.value);
  }

  void add() {
    final updated = List<String>.from(notes.value)..add('');
    notes.value = updated;
    _save();
  }

  void update(int index, String value) {
    final updated = List<String>.from(notes.value);
    updated[index] = value;
    notes.value = updated;
    _save();
  }

  void remove(int index) {
    final updated = List<String>.from(notes.value)..removeAt(index);
    notes.value = updated;
    _save();
  }
}
