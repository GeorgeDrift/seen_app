import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Shown while `generateReflection` runs, over the real Figma-exported
/// journey/path illustration.
class ReflectionLoadingView extends StatelessWidget {
  const ReflectionLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/figma_loading_background.png', fit: BoxFit.cover),
        Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(32),
          child: SoftCard(
            color: AppColors.white,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Bringing your day together.',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Weaving your moments into a reflection…',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
