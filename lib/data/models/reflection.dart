/// The AI-generated (or user-refined) whole-day narrative reflection.
class Reflection {
  const Reflection({
    required this.text,
    required this.generatedAt,
    this.isEdited = false,
  });

  final String text;
  final DateTime generatedAt;
  final bool isEdited;

  Reflection copyWith({String? text, DateTime? generatedAt, bool? isEdited}) =>
      Reflection(
        text: text ?? this.text,
        generatedAt: generatedAt ?? this.generatedAt,
        isEdited: isEdited ?? this.isEdited,
      );
}
