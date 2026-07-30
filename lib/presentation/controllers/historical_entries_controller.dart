import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/daily_entry.dart';
import '../../domain/engine/pattern_engine.dart';
import '../providers/api_providers.dart';

/// The 14-day synthetic history the patterns/therapist screens read from.
///
/// Cached via `Provider` (rebuilt only if the repository changes), so
/// switching profiles or navigating away and back never reshuffles the
/// dataset the demo relies on.
final historicalEntriesProvider = Provider<List<DailyEntry>>((ref) {
  return ref.watch(seenRepositoryProvider).loadHistoricalEntries();
});

/// Derived, presentation-ready pattern insights over the 14-day dataset.
final patternInsightsProvider = Provider<List<PatternInsight>>((ref) {
  final repo = ref.watch(seenRepositoryProvider);
  final entries = ref.watch(historicalEntriesProvider);
  return repo.patternInsights(entries);
});
