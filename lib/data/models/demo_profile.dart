import 'daily_context.dart';

/// A named passive-data profile used for the demo. The three profiles
/// exercise the three "shapes" the app is optimized to differentiate:
/// overloaded (A), active (B), quiet recovery (C).
enum DemoProfileKey { a, b, c }

class DemoProfile {
  const DemoProfile({
    required this.key,
    required this.label,
    required this.description,
    required this.context,
  });

  final DemoProfileKey key;
  final String label;
  final String description;
  final DailyContext context;
}
