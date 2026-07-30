import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/clue.dart';
import '../../data/models/follow_up_question.dart';
import '../providers/api_providers.dart';
import 'day_flow_controller.dart';

/// Family-keyed `AsyncNotifier` that resolves the follow-up question for a
/// specific clue. The presentation layer just watches
/// `followUpQuestionProvider(clue)` and gets an `AsyncValue<FollowUpQuestion>`
/// it can pattern-match on (loading / data / error).
///
/// The repository already handles the fallback path so this rarely (never)
/// enters the error branch — it exists purely as a safety net.
final followUpQuestionProvider =
    AsyncNotifierProviderFamily<FollowUpController, FollowUpQuestion, Clue>(
        FollowUpController.new);

class FollowUpController
    extends FamilyAsyncNotifier<FollowUpQuestion, Clue> {
  @override
  Future<FollowUpQuestion> build(Clue arg) async {
    final repo = ref.watch(seenRepositoryProvider);
    final flow = ref.read(dayFlowControllerProvider);
    final previousMeaning =
        ref.read(dayFlowControllerProvider.notifier).lastAnsweredOption;
    return repo.followUpQuestion(
      clue: arg,
      context: flow.context,
      interpretedSignals: flow.signals,
      previousMeaning: previousMeaning,
    );
  }
}
