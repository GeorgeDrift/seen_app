import 'dart:convert';
import 'dart:developer' as developer;

import 'package:shared_preferences/shared_preferences.dart';

import '../models/clue_selection.dart';

const String _logTag = 'DayProgress';
const String _storageKey = 'seen_day_progress_v1';

/// Calendar-day key used to gate persistence — the real device date, not the
/// (possibly synthetic/demo) `DailyContext.date` — so "once per day" always
/// lines up with the user's actual clock.
String todayDateKey([DateTime? now]) {
  final n = now ?? DateTime.now();
  return '${n.year.toString().padLeft(4, '0')}-'
      '${n.month.toString().padLeft(2, '0')}-'
      '${n.day.toString().padLeft(2, '0')}';
}

/// A snapshot of the user's in-progress or completed day, persisted locally
/// so closing and reopening the app doesn't lose it. Only ever valid for the
/// calendar day it was saved on — a stale date is treated as "nothing saved",
/// which is what gives the "once per day" behavior.
class StoredDayProgress {
  const StoredDayProgress({
    required this.date,
    required this.stage,
    required this.selections,
    this.reflection,
    this.originalReflection,
  });

  final String date;
  final String stage;
  final List<ClueSelection> selections;
  final String? reflection;
  final String? originalReflection;

  Map<String, dynamic> toJson() => {
    'date': date,
    'stage': stage,
    'selections': selections.map((s) => s.toLocalJson()).toList(),
    'reflection': reflection,
    'originalReflection': originalReflection,
  };

  factory StoredDayProgress.fromJson(Map<String, dynamic> json) =>
      StoredDayProgress(
        date: json['date'] as String,
        stage: json['stage'] as String,
        selections: (json['selections'] as List<dynamic>? ?? const [])
            .map((e) => ClueSelection.fromJson(e as Map<String, dynamic>))
            .toList(),
        reflection: json['reflection'] as String?,
        originalReflection: json['originalReflection'] as String?,
      );
}

/// Reads/writes today's [StoredDayProgress] to on-device storage.
///
/// Persistence is intentionally scoped to a single slot ("today's entry") —
/// the app only ever needs the current day's in-progress state, and an entry
/// from a previous calendar day is treated as absent so a new day always
/// starts fresh.
class DayProgressStore {
  Future<StoredDayProgress?> load(String today) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null) {
        developer.log('load($today) -> nothing stored.', name: _logTag);
        return null;
      }
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final stored = StoredDayProgress.fromJson(json);
      if (stored.date != today) {
        developer.log(
          'load($today) -> stored entry is from ${stored.date}, '
          'treating as a new day.',
          name: _logTag,
        );
        return null;
      }
      developer.log(
        'load($today) -> restored stage=${stored.stage}, '
        '${stored.selections.length} selection(s).',
        name: _logTag,
      );
      return stored;
    } catch (e) {
      developer.log('load($today) failed: $e', name: _logTag);
      return null;
    }
  }

  Future<void> save(StoredDayProgress progress) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(progress.toJson()));
      developer.log(
        'save -> date=${progress.date} stage=${progress.stage} '
        '${progress.selections.length} selection(s).',
        name: _logTag,
      );
    } catch (e) {
      developer.log('save failed: $e', name: _logTag);
    }
  }

  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      developer.log('clear -> done.', name: _logTag);
    } catch (e) {
      developer.log('clear failed: $e', name: _logTag);
    }
  }
}
