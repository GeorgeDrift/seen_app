import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../controllers/today_flow_controller.dart';

/// Shown after the day's reflection has been saved.
class DoneView extends ConsumerWidget {
  const DoneView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(todayFlowControllerProvider);
    final reflection = state.reflection;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset(
              'assets/cozy_reflection_header.png',
              width: double.infinity,
              height: 140,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "You're done reflecting for today.",
            style: Theme.of(context).textTheme.displayLarge,
          ),
          const SizedBox(height: 16),
          if (reflection != null)
            SoftCard(
              color: AppColors.cardWarm,
              padding: const EdgeInsets.all(20),
              child: Text(
                reflection.text,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          const SizedBox(height: 20),
          SecondaryButton(
            onPressed: () =>
                ref.read(todayFlowControllerProvider.notifier).backToMoments(),
            label: 'Edit today\'s moments',
          ),
        ],
      ),
    );
  }
}
