import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/scene_hotspot.dart';
import '../controllers/today_flow_controller.dart';

/// Bottom sheet for capturing a free-text moment from a tapped scene
/// hotspot. Replaces the old AI-driven `ClueQuestionSheet` — there is no
/// per-clue AI question in the redesigned flow, just a static prompt and a
/// multi-line text field.
class MomentCaptureSheet extends ConsumerStatefulWidget {
  const MomentCaptureSheet({super.key, required this.hotspot});

  final SceneHotspot hotspot;

  @override
  ConsumerState<MomentCaptureSheet> createState() => _MomentCaptureSheetState();
}

class _MomentCaptureSheetState extends ConsumerState<MomentCaptureSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final existing = ref
        .read(todayFlowControllerProvider)
        .moments
        .where((m) => m.clueId == widget.hotspot.id)
        .firstOrNull;
    _controller = TextEditingController(text: existing?.userMeaning ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final accepted = ref
        .read(todayFlowControllerProvider.notifier)
        .addMoment(widget.hotspot, text);
    Navigator.pop(context);
    if (!accepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "You've found three moments. Remove one to add a new one.",
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 24,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(widget.hotspot.title, style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(kMomentCapturePrompt, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              minLines: 3,
              maxLines: 5,
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Write a few words…',
                filled: true,
                fillColor: AppColors.cardWarm,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    onPressed: () => Navigator.pop(context),
                    label: 'Cancel',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    onPressed: _save,
                    label: 'Save this moment',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
