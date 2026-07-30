import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/health_week_dataset.dart';
import '../../data/models/health_week_day.dart';
import '../../data/models/health_week_insights.dart';
import '../../domain/engine/reflection_habits_engine.dart';
import '../providers/api_providers.dart';

/// The fixed 7-day dummy dataset driving "Health over time". Deliberately a
/// plain [Provider] (not a controller) — the calendar row and passive-
/// context timeline sections must be calculated directly from this data,
/// never AI-generated, so there's no mutable state to manage here.
final healthWeekDatasetProvider = Provider<List<HealthWeekDay>>((ref) {
  return HealthWeekDataset.demo;
});

/// Reflection-completion count/rate/typical-submission-window — calculated
/// directly from the dataset (per spec: never AI-generated).
final reflectionHabitsProvider = Provider<ReflectionHabits>((ref) {
  final days = ref.watch(healthWeekDatasetProvider);
  return const ReflectionHabitsEngine().summarize(days);
});

/// The three AI-generated sections (pattern worth noticing, what may be
/// helping, recurring themes) for the current 7-day dataset. One backend
/// call, structured JSON — falls back to a static low-confidence response if
/// the backend is unreachable or the call fails (see
/// `SeenRepositoryImpl.weeklyInsights`). Consume via `.when(data:/loading:/error:)`.
final weeklyInsightsProvider = FutureProvider<WeeklyInsights>((ref) async {
  final repo = ref.watch(seenRepositoryProvider);
  final days = ref.watch(healthWeekDatasetProvider);
  return repo.weeklyInsights(days);
});
