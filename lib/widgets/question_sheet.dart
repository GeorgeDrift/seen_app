import 'package:flutter/material.dart';
import '../models.dart';
import '../theme.dart';

class ClueQuestionSheet extends StatefulWidget {
  final Clue clue;
  final DailyContext context;
  final Function(ClueSelection) onSelectionSaved;

  const ClueQuestionSheet({
    super.key,
    required this.clue,
    required this.context,
    required this.onSelectionSaved,
  });

  @override
  State<ClueQuestionSheet> createState() => _ClueQuestionSheetState();
}

class _ClueQuestionSheetState extends State<ClueQuestionSheet> {
  String? _selectedOption;
  String _confidence = 'clear';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryColor = _getCategoryColor(widget.clue.category);

    // Get question & options (using clue template or category fallback)
    final questionText = widget.clue.question;
    final optionsList = widget.clue.options;

    return GlassContainer(
      blur: 25,
      borderRadius: 24,
      color: AppColors.backgroundStart.withOpacity(0.92),
      border: Border.all(
        color: categoryColor.withOpacity(0.3),
        width: 1.5,
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Badge Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: categoryColor.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.clue.icon, size: 12, color: categoryColor),
                    const SizedBox(width: 4),
                    Text(
                      'SCREEN 3: AI CLARIFICATION (${widget.clue.category.toUpperCase()})',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: categoryColor,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          const SizedBox(height: 12),

          // Title
          Text(
            widget.clue.title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),

          // Safety & Purpose Indicator
          Row(
            children: [
              const Icon(Icons.shield_outlined, size: 12, color: AppColors.sage),
              const SizedBox(width: 4),
              Text(
                'Safety Check: Passed • Non-leading personal clarification',
                style: TextStyle(fontSize: 11, color: Colors.grey[400]),
              ),
            ],
          ),
          const Divider(height: 24, color: AppColors.borderTranslucent),

          // Question Text
          Text(
            questionText,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          // Options List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: optionsList.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final option = optionsList[index];
              final isSelected = _selectedOption == option;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedOption = option;
                    if (option == 'Not sure') _confidence = 'uncertain';
                  });

                  Future.delayed(const Duration(milliseconds: 280), () {
                    if (!mounted) return;
                    _submitSelection(option);
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? categoryColor.withOpacity(0.15)
                        : Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? categoryColor
                          : Colors.white.withOpacity(0.08),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? categoryColor : Colors.white.withOpacity(0.3),
                            width: isSelected ? 4.5 : 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          option,
                          style: TextStyle(
                            fontSize: 13,
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // Skip Option Button
          Center(
            child: TextButton(
              onPressed: () {
                _submitSelection('Skipped', isSkipped: true);
              },
              child: const Text(
                'Skip this question',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submitSelection(String answer, {bool isSkipped = false}) {
    final selection = ClueSelection(
      clueId: widget.clue.id,
      clueTitle: widget.clue.title,
      selectedAt: DateTime.now(),
      userMeaning: answer,
      followUpQuestion: widget.clue.question,
      answerOption: answer,
      confidence: isSkipped ? 'skipped' : _confidence,
    );

    widget.onSelectionSaved(selection);
    Navigator.pop(context);
  }

  Color _getCategoryColor(String cat) {
    switch (cat) {
      case 'sleep':
        return AppColors.sleep;
      case 'movement':
        return AppColors.steps;
      case 'workload':
        return AppColors.calendar;
      case 'environment':
        return AppColors.weatherRain;
      case 'recovery':
        return AppColors.sage;
      default:
        return AppColors.lavender;
    }
  }
}
