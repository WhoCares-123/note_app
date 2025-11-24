import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/note.dart';

class StorageService {
  static const _boxName = 'note_app_box';
  static const _notesKey = 'notes_v1';
  static const _themeKey = 'theme_is_dark';
  static const _pinKey = 'app_pin';

  Box _box() {
    // box is opened in main(); return the already-open box
    return Hive.box(_boxName);
  }

  Future<List<Note>> loadNotes() async {
    final b = _box();
    final raw = (b.get(_notesKey, defaultValue: <String>[]) as List).cast<String>();
    return raw.map((s) => Note.fromJson(s)).toList();
  }

  Future<void> saveNotes(List<Note> notes) async {
    final b = _box();
    final raw = notes.map((n) => n.toJson()).toList();
    await b.put(_notesKey, raw);
  }

  Future<bool> isDarkMode() async {
    final b = _box();
    return b.get(_themeKey, defaultValue: false) as bool;
  }

  Future<void> setDarkMode(bool v) async {
    final b = _box();
    await b.put(_themeKey, v);
  }

  Future<void> setPin(String? pin) async {
    final b = _box();
    if (pin == null) await b.delete(_pinKey);
    else await b.put(_pinKey, base64Encode(utf8.encode(pin)));
  }

  Future<String?> getPin() async {
    final b = _box();
    final raw = b.get(_pinKey) as String?;
    if (raw == null) return null;
    return utf8.decode(base64Decode(raw));
  }
}
