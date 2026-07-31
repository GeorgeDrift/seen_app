import '../../data/models/clue.dart';
import '../../data/models/follow_up_question.dart';

/// Follow-up questions used whenever the AI call fails or is unavailable.
/// Always clue-specific — every [Clue] already carries its own hand-written
/// `question`/`options` pair, so tapping different items never yields the
/// same fallback question just because they share a category.
class FallbackQuestions {
  const FallbackQuestions._();

  /// The clue's own question/options — the fallback used offline or when
  /// the backend call fails. Always matches the exact item tapped.
  static FollowUpQuestion forClue(Clue clue) => FollowUpQuestion(
    question: clue.question,
    options: clue.options,
    purpose: 'fallback_clarification',
  );

  /// Category-level fallback, kept only for category-only call sites (none
  /// currently in the app) — prefer [forClue] wherever a [Clue] is available.
  static const Map<String, FollowUpQuestion> _byCategory = {
    'sleep': FollowUpQuestion(
      question: 'How did this affect your energy today?',
      options: [
        'Lower energy',
        'Harder to focus',
        'Did not affect me',
        'Not sure',
      ],
      purpose: 'fallback_clarification',
    ),
    'workload': FollowUpQuestion(
      question: 'How did this schedule or workload feel today?',
      options: ['Manageable', 'Energizing', 'Draining', 'Not sure'],
      purpose: 'fallback_clarification',
    ),
    'movement': FollowUpQuestion(
      question: 'What was behind your physical activity level today?',
      options: [
        'Needed physical movement',
        'Felt stuck at desk',
        'Felt restorative rest',
        'Not sure',
      ],
      purpose: 'fallback_clarification',
    ),
    'social': FollowUpQuestion(
      question: 'How did this interaction feel?',
      options: ['Supportive', 'Draining', 'Neutral', 'Not sure'],
      purpose: 'fallback_clarification',
    ),
    'recovery': FollowUpQuestion(
      question: 'What did this moment mean to you today?',
      options: [
        'Helped me recover',
        'Felt isolating',
        'Felt neutral',
        'Not sure',
      ],
      purpose: 'fallback_clarification',
    ),
    'environment': FollowUpQuestion(
      question: 'How did your surroundings impact your mindset?',
      options: [
        'Created cozy focus',
        'Made me feel restless',
        'Had no impact',
        'Not sure',
      ],
      purpose: 'fallback_clarification',
    ),
  };

  static const _generic = FollowUpQuestion(
    question: 'What did this moment mean to you?',
    options: ['Positive', 'Neutral', 'Difficult', 'Not sure'],
    purpose: 'fallback_clarification',
  );

  static FollowUpQuestion forCategory(String category) =>
      _byCategory[category] ?? _generic;
}
