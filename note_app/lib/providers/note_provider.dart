import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/note.dart';
import '../services/storage_service.dart';

class NoteProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  List<Note> notes = [];
  bool isDark = false;
  String? appPin;
  Timer? _reminderTimer;
  String _searchQuery = '';

  NoteProvider() {
    _init();
  }

  Future<void> _init() async {
    notes = await _storage.loadNotes();
    isDark = await _storage.isDarkMode();
    appPin = await _storage.getPin();
    _startReminderLoop();
    notifyListeners();
  }

  void _startReminderLoop() {
    _reminderTimer?.cancel();
    _reminderTimer = Timer.periodic(Duration(seconds: 30), (_) => _checkReminders());
  }

  void _checkReminders() {
    final now = DateTime.now();
    for (var n in notes) {
      if (n.reminder != null && !n.locked) {
        final diff = n.reminder!.difference(now);
        if (diff.inSeconds <= 0 && diff.inSeconds > -60) {
          // mark reminder fired
          n.reminder = null;
          saveAll();
          // simple in-app callback via listeners; UI should show SnackBars when detected
          notifyListeners();
        }
      }
    }
  }

  Future<void> addNote(Note n) async {
    notes.insert(0, n);
    await saveAll();
    notifyListeners();
  }

  Future<void> updateNote(Note n) async {
    n.updatedAt = DateTime.now();
    final idx = notes.indexWhere((x) => x.id == n.id);
    if (idx >= 0) notes[idx] = n;
    await saveAll();
    notifyListeners();
  }

  Future<void> deleteNote(String id, {bool permanent = false}) async {
    final idx = notes.indexWhere((n) => n.id == id);
    if (idx < 0) return;
    if (permanent) {
      notes.removeAt(idx);
    } else {
      // soft-delete
      notes[idx].deleted = true;
      notes[idx].deletedAt = DateTime.now();
    }
    await saveAll();
    notifyListeners();
  }

  Future<void> restoreNote(String id) async {
    final idx = notes.indexWhere((n) => n.id == id);
    if (idx < 0) return;
    notes[idx].deleted = false;
    notes[idx].deletedAt = null;
    await saveAll();
    notifyListeners();
  }

  Future<void> emptyTrash() async {
    notes.removeWhere((n) => n.deleted);
    await saveAll();
    notifyListeners();
  }

  Note createEmpty({String type = 'note'}) {
    return Note(id: Uuid().v4(), checklist: [], type: type);
  }

  Future<void> saveAll() async {
    await _storage.saveNotes(notes);
  }

  Future<void> setTheme(bool dark) async {
    isDark = dark;
    await _storage.setDarkMode(dark);
    notifyListeners();
  }

  Future<void> setPin(String? pin) async {
    appPin = pin;
    await _storage.setPin(pin);
    notifyListeners();
  }

  bool validatePin(String input) => appPin != null && appPin == input;

  Future<void> togglePin(String id) async {
    final idx = notes.indexWhere((n) => n.id == id);
    if (idx < 0) return;
    notes[idx].pinned = !notes[idx].pinned;
    notes[idx].pinnedAt = notes[idx].pinned ? DateTime.now() : null;
    await saveAll();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase().trim();
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  bool _matchesSearch(Note note) {
    if (_searchQuery.isEmpty) return true;
    
    final query = _searchQuery;
    final titleMatch = note.title.toLowerCase().contains(query);
    final contentMatch = note.content.toLowerCase().contains(query);
    final checklistMatch = note.checklist.any((item) => 
      item.text.toLowerCase().contains(query));
    
    return titleMatch || contentMatch || checklistMatch;
  }

  List<Note> get activeNotes {
    final active = notes.where((n) => !n.deleted).toList();
    // Sort: pinned notes first (by pinnedAt), then unpinned notes (by updatedAt)
    active.sort((a, b) {
      if (a.pinned && !b.pinned) return -1;
      if (!a.pinned && b.pinned) return 1;
      if (a.pinned && b.pinned) {
        // Both pinned: sort by pinnedAt (earlier pinned = first)
        final aPinnedAt = a.pinnedAt ?? DateTime(0);
        final bPinnedAt = b.pinnedAt ?? DateTime(0);
        return aPinnedAt.compareTo(bPinnedAt);
      }
      // Both unpinned: sort by updatedAt (newer = first)
      return b.updatedAt.compareTo(a.updatedAt);
    });
    if (_searchQuery.isEmpty) return active;
    return active.where(_matchesSearch).toList();
  }
  
  List<Note> get trashNotes => notes.where((n) => n.deleted).toList();
  
  String get searchQuery => _searchQuery;
}
