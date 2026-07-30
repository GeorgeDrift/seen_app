import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/daily_context.dart';
import '../../data/models/interpreted_signal.dart';
import '../providers/api_providers.dart';
import 'profile_controller.dart';

/// The passive-data context + derived signals for the day currently being
/// annotated. Scene composition now lives in [SceneCatalog] (a fixed room
/// per profile) rather than here — this controller only drives the
/// "glimpse of your day" stat cards and the `interpretedSignals` sent to
/// the backend.
class DayFlowState {
  const DayFlowState({required this.context, required this.signals});

  final DailyContext context;
  final List<InterpretedSignal> signals;
}

/// Re-derives whenever the active profile changes (i.e. [activeProfileProvider]
/// emits).
final dayFlowControllerProvider =
    NotifierProvider<DayFlowController, DayFlowState>(DayFlowController.new);

class DayFlowController extends Notifier<DayFlowState> {
  @override
  DayFlowState build() {
    final profile = ref.watch(activeProfileProvider);
    final repo = ref.watch(seenRepositoryProvider);
    final signals = repo.interpretSignals(profile.context);
    return DayFlowState(context: profile.context, signals: signals);
  }
}
