/// The AI-generated (or user-edited) whole-day narrative reflection.
class Reflection {
  const Reflection({
    required this.text,
    required this.generatedAt,
    this.isEdited = false,
  });

  final String text;
  final DateTime generatedAt;
  final bool isEdited;
}
