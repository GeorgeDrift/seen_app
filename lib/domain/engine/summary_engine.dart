import '../../data/models/clue_selection.dart';

/// Builds the confirmed-info-only daily summary locally.
///
/// Deliberately dumb on purpose — no causal language, no interpretation
/// beyond re-stating what the user said. If the backend AI is available
/// the repository prefers its output; this is the offline safety net.
class SummaryEngine {
  const SummaryEngine();

  String buildLocal(List<ClueSelection> selections) {
    if (selections.isEmpty) {
      return 'No moments annotated for today yet.';
    }

    final parts = <String>[];
    for (final s in selections) {
      if (s.userMeaning != null && s.confidence != 'skipped') {
        parts.add("${s.clueTitle} was marked as '${s.userMeaning}'");
      }
    }

    if (parts.isEmpty) {
      return 'Explored clues, but no explicit meanings recorded.';
    }

    return "Today's Contextual Log: ${parts.join('; ')}.";
  }
}
