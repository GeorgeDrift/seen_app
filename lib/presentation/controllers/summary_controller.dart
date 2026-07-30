import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/daily_entry.dart';
import '../providers/api_providers.dart';
import 'day_flow_controller.dart';

/// Persists the current day and produces its final summary.
///
/// The screen calls [DailySummaryController.commit] on mount (or on demand),
/// then watches the async state. `AsyncValue` carries loading/data/error so
/// the widget code stays declarative.
final dailySummaryControllerProvider =
    AsyncNotifierProvider<DailySummaryController, DailyEntry?>(
        DailySummaryController.new);

class DailySummaryController extends AsyncNotifier<DailyEntry?> {
  @override
  Future<DailyEntry?> build() async => null;

  /// Save the current [DayFlowState] as a completed entry and store the
  /// backend/local summary in the async state. Always resolves — the
  /// repository handles the fallback to a local summary internally.
  Future<void> commit() async {
    state = const AsyncValue.loading();
    final repo = ref.read(seenRepositoryProvider);
    final flow = ref.read(dayFlowControllerProvider);

    try {
      final entry = await repo.completeDay(
        context: flow.context,
        interpretedSignals: flow.signals,
        displayedClueIds:
            flow.scene.visibleClues.map((c) => c.id).toList(),
        selectedClues: flow.selections,
      );
      state = AsyncValue.data(entry);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void clear() {
    state = const AsyncValue.data(null);
  }
}
