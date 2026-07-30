/// A user's choice of one clue on a given day, plus the follow-up question
/// they were shown and (optionally) the option they picked.
class ClueSelection {
  const ClueSelection({
    required this.clueId,
    required this.clueTitle,
    required this.selectedAt,
    required this.dailyContextDate,
    this.userMeaning,
    this.followUpQuestion,
    this.answerOption,
    this.confidence = 'clear',
  });

  final String clueId;
  final String clueTitle;
  final DateTime selectedAt;
  final String dailyContextDate;
  final String? userMeaning;
  final String? followUpQuestion;
  final String? answerOption;
  final String confidence; // 'clear' | 'uncertain' | 'skipped'

  ClueSelection copyWith({
    String? userMeaning,
    String? followUpQuestion,
    String? answerOption,
    String? confidence,
  }) => ClueSelection(
    clueId: clueId,
    clueTitle: clueTitle,
    selectedAt: selectedAt,
    dailyContextDate: dailyContextDate,
    userMeaning: userMeaning ?? this.userMeaning,
    followUpQuestion: followUpQuestion ?? this.followUpQuestion,
    answerOption: answerOption ?? this.answerOption,
    confidence: confidence ?? this.confidence,
  );

  Map<String, dynamic> toJson() => {
    'clueId': clueId,
    'selectedAt': selectedAt.toIso8601String(),
    'dailyContextDate': dailyContextDate,
    'userMeaning': userMeaning,
    'followUpQuestion': followUpQuestion,
    'answerOption': answerOption,
    'confidence': confidence,
  };
}
