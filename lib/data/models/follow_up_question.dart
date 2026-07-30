/// The AI's clarifying question for a selected clue. Always has 3–4 options.
///
/// The backend safety layer strips causal/diagnostic language before this
/// reaches the client — see `followUpEngine.ts` in the Azure Functions repo.
/// If validation fails, the backend swaps in a fixed fallback question and
/// still returns this same shape.
class FollowUpQuestion {
  const FollowUpQuestion({
    required this.question,
    required this.options,
    required this.purpose,
    this.answerType = 'single_select',
    this.safetyCheck = 'passed',
  });

  final String question;
  final String answerType;
  final List<String> options;
  final String purpose;
  final String safetyCheck;

  factory FollowUpQuestion.fromJson(Map<String, dynamic> json) =>
      FollowUpQuestion(
        question: json['question'] as String,
        answerType: json['answerType'] as String? ?? 'single_select',
        options: (json['options'] as List)
            .map((e) => e.toString())
            .toList(growable: false),
        purpose: json['purpose'] as String? ?? '',
        safetyCheck: json['safetyCheck'] as String? ?? 'passed',
      );

  Map<String, dynamic> toJson() => {
        'question': question,
        'answerType': answerType,
        'options': options,
        'purpose': purpose,
        'safetyCheck': safetyCheck,
      };
}
