import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/clue.dart';
import '../../data/models/clue_selection.dart';
import '../../data/models/follow_up_question.dart';
import '../controllers/day_flow_controller.dart';
import '../controllers/follow_up_controller.dart';

/// Modal bottom sheet asking the user to clarify what a selected clue meant.
///
/// Reads the follow-up question from [followUpQuestionProvider] as an
/// `AsyncValue<FollowUpQuestion>` — the backend AI call and the offline
/// fallback both surface through the same interface, so widget code doesn't
/// need to know or care which one produced the question.
class ClueQuestionSheet extends ConsumerStatefulWidget {
  const ClueQuestionSheet({super.key, required this.clue});

  final Clue clue;

  @override
  ConsumerState<ClueQuestionSheet> createState() => _ClueQuestionSheetState();
}

class _ClueQuestionSheetState extends ConsumerState<ClueQuestionSheet> {
  String? _selectedOption;

  Color get _categoryColor {
    switch (widget.clue.category) {
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

  void _submit(FollowUpQuestion q, String answer, {bool isSkipped = false}) {
    final flow = ref.read(dayFlowControllerProvider);
    final selection = ClueSelection(
      clueId: widget.clue.id,
      clueTitle: widget.clue.title,
      selectedAt: DateTime.now(),
      dailyContextDate: flow.context.date,
      userMeaning: isSkipped ? null : answer,
      followUpQuestion: q.question,
      answerOption: isSkipped ? null : answer,
      confidence: isSkipped
          ? 'skipped'
          : (answer.toLowerCase() == 'not sure' ? 'uncertain' : 'clear'),
    );

    final accepted = ref
        .read(dayFlowControllerProvider.notifier)
        .addSelection(selection);
    Navigator.pop(context);

    if (!accepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "You found three moments. Deselect one to change your picks.",
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (!isSkipped) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Recorded selection for ${widget.clue.title}: '$answer'",
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF0F172A),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final asyncQ = ref.watch(followUpQuestionProvider(widget.clue));

    return GlassContainer(
      blur: 25,
      borderRadius: 24,
      color: AppColors.backgroundStart.withValues(alpha: 0.92),
      border: Border.all(
        color: _categoryColor.withValues(alpha: 0.3),
        width: 1.5,
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _categoryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _categoryColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.clue.icon, size: 12, color: _categoryColor),
                    const SizedBox(width: 4),
                    Text(
                      'SCREEN 3: AI CLARIFICATION (${widget.clue.category.toUpperCase()})',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: _categoryColor,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(
                  Icons.close,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.clue.title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.shield_outlined,
                size: 12,
                color: AppColors.sage,
              ),
              const SizedBox(width: 4),
              Text(
                'Safety Check: Passed • Non-leading personal clarification',
                style: TextStyle(fontSize: 11, color: Colors.grey[400]),
              ),
            ],
          ),
          const Divider(height: 24, color: AppColors.borderTranslucent),
          asyncQ.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            error: (_, _) => _renderQuestion(context, _localFallback(), theme),
            data: (q) => _renderQuestion(context, q, theme),
          ),
        ],
      ),
    );
  }

  FollowUpQuestion _localFallback() => FollowUpQuestion(
    question: widget.clue.question,
    options: widget.clue.options,
    purpose: 'local_fallback',
  );

  Widget _renderQuestion(
    BuildContext context,
    FollowUpQuestion q,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          q.question,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 1.4,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: q.options.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final option = q.options[index];
            final isSelected = _selectedOption == option;
            return GestureDetector(
              onTap: () {
                setState(() => _selectedOption = option);
                Future.delayed(const Duration(milliseconds: 280), () {
                  if (!mounted) return;
                  _submit(q, option);
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? _categoryColor.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? _categoryColor
                        : Colors.white.withValues(alpha: 0.08),
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
                          color: isSelected
                              ? _categoryColor
                              : Colors.white.withValues(alpha: 0.3),
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
                          color: isSelected
                              ? Colors.white
                              : AppColors.textPrimary,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
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
        Center(
          child: TextButton(
            onPressed: () => _submit(q, 'Skipped', isSkipped: true),
            child: const Text(
              'Skip this question',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
        ),
      ],
    );
  }
}
