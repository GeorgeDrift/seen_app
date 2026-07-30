import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../controllers/today_flow_controller.dart';

/// Shows the AI-generated (or refined) reflection with an inline edit panel
/// for steering the tone via free text, and the final save/back actions.
class ReflectionView extends ConsumerStatefulWidget {
  const ReflectionView({super.key});

  @override
  ConsumerState<ReflectionView> createState() => _ReflectionViewState();
}

class _ReflectionViewState extends ConsumerState<ReflectionView> {
  bool _editing = false;
  final _steeringController = TextEditingController();

  @override
  void dispose() {
    _steeringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(todayFlowControllerProvider);
    final controller = ref.read(todayFlowControllerProvider.notifier);
    final reflection = state.reflection;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your reflection.',
            style: Theme.of(context).textTheme.displayLarge,
          ),
          const SizedBox(height: 20),
          SoftCard(
            color: AppColors.cardWarm,
            padding: const EdgeInsets.all(20),
            child: reflection == null
                ? const SizedBox.shrink()
                : Text(
                    reflection.text,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _editing = !_editing),
              icon: Icon(
                _editing ? Icons.close : Icons.edit_outlined,
                size: 16,
              ),
              label: Text(_editing ? 'Close editor' : 'Edit reflection'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ),
          if (_editing) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _steeringController,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Make it sound more like you…',
                filled: true,
                fillColor: AppColors.cardCool,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    onPressed: state.isBusy
                        ? null
                        : () {
                            controller.restoreOriginal();
                            _steeringController.clear();
                          },
                    label: 'Restore original version',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    onPressed: state.isBusy
                        ? null
                        : () async {
                            final text = _steeringController.text.trim();
                            if (text.isEmpty) return;
                            await controller.refine(text);
                          },
                    label: state.isBusy ? 'Saving…' : 'Save changes',
                    expand: true,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 28),
          PrimaryButton(
            onPressed: state.isBusy ? null : () => controller.saveReflection(),
            label: state.isBusy ? 'Saving…' : 'Save reflection',
          ),
          const SizedBox(height: 12),
          SecondaryButton(
            onPressed: state.isBusy ? null : controller.backToMoments,
            label: 'Go back to my moments',
          ),
        ],
      ),
    );
  }
}
