import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/health_week_dataset.dart';
import '../../data/models/health_week_day.dart';
import '../../data/models/health_week_insights.dart';
import '../../domain/engine/reflection_habits_engine.dart';
import '../providers/api_providers.dart';
import 'profile_controller.dart';

final healthWeekDatasetProvider = Provider<List<HealthWeekDay>>((ref) {
  final profile = ref.watch(activeProfileProvider);
  return HealthWeekDataset.forProfile(profile.demoKey);
});

final reflectionHabitsProvider = Provider<ReflectionHabits>((ref) {
  final days = ref.watch(healthWeekDatasetProvider);
  return const ReflectionHabitsEngine().summarize(days);
});

final weeklyInsightsProvider = FutureProvider<WeeklyInsights>((ref) async {
  final repo = ref.watch(seenRepositoryProvider);
  final days = ref.watch(healthWeekDatasetProvider);
  return repo.weeklyInsights(days);
});
