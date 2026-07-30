import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../controllers/app_navigation_controller.dart';
import 'context_preview_screen.dart';
import 'daily_summary_screen.dart';
import 'patterns_screen.dart';
import 'scene_screen.dart';
import 'therapist_portal.dart';

/// The framed shell around the four patient screens and the therapist
/// portal. Top header + patient breadcrumb navigation live here; everything
/// below reads its own state from providers.
class MainLayout extends ConsumerWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(appModeProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.backgroundStart,
              AppColors.backgroundEnd,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const _TopHeader(),
              if (mode == AppMode.patient) const _PatientJourneyStepper(),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: mode == AppMode.therapist
                      ? const TherapistPortalScreen(
                          key: ValueKey('therapist'))
                      : const _PatientStepContent(key: ValueKey('patient')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopHeader extends ConsumerWidget {
  const _TopHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(appModeProvider);
    final modeNotifier = ref.read(appModeProvider.notifier);

    return GlassContainer(
      borderRadius: 0,
      blur: 20,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      border: const Border(
        bottom: BorderSide(color: AppColors.borderTranslucent, width: 1.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.sage],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                    )
                  ],
                ),
                child: const Icon(
                  Icons.visibility,
                  size: 16,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'S E E N',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: 2.0,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'BEHAVIORAL ANNOTATION SYSTEM',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              _ModeToggleItem(
                label: 'Patient View',
                icon: Icons.person_outline,
                isActive: mode == AppMode.patient,
                onTap: () => modeNotifier.set(AppMode.patient),
              ),
              const SizedBox(width: 8),
              _ModeToggleItem(
                label: 'Therapist Portal',
                icon: Icons.medical_services_outlined,
                isActive: mode == AppMode.therapist,
                onTap: () => modeNotifier.set(AppMode.therapist),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModeToggleItem extends StatelessWidget {
  const _ModeToggleItem({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color:
              isActive ? Colors.white.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? AppColors.primary : Colors.transparent,
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PatientJourneyStepper extends ConsumerWidget {
  const _PatientJourneyStepper();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = ref.watch(patientStepProvider);
    final stepNotifier = ref.read(patientStepProvider.notifier);

    Widget divider() => const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Icon(Icons.chevron_right,
              size: 14, color: AppColors.textSecondary),
        );

    Widget crumb(int index, String label, PatientStep target) {
      final isActive = step == target;
      return GestureDetector(
        onTap: () => stepNotifier.go(target),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color:
                  isActive ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        border: const Border(
            bottom: BorderSide(
                color: AppColors.borderTranslucent, width: 0.8)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            crumb(0, '1. Context', PatientStep.contextPreview),
            divider(),
            crumb(1, '2. Scene', PatientStep.hiddenScene),
            divider(),
            crumb(2, '3. Summary', PatientStep.dailySummary),
            divider(),
            crumb(3, '4. Patterns', PatientStep.patterns),
          ],
        ),
      ),
    );
  }
}

class _PatientStepContent extends ConsumerWidget {
  const _PatientStepContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = ref.watch(patientStepProvider);
    switch (step) {
      case PatientStep.contextPreview:
        return const ContextPreviewScreen();
      case PatientStep.hiddenScene:
        return const SceneScreen();
      case PatientStep.dailySummary:
        return const DailySummaryScreen();
      case PatientStep.patterns:
        return const PatternsScreen();
    }
  }
}
