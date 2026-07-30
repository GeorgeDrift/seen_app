import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../controllers/app_navigation_controller.dart';
import 'context_preview_screen.dart';
import 'daily_summary_screen.dart';
import 'patterns_screen.dart';
import 'scene_screen.dart';
import 'therapist_portal.dart';

/// The framed shell around the four patient screens and the therapist portal.
///
/// Patient screens are rendered FULL-SCREEN with no shell chrome —
/// each screen manages its own background, header, and navigation.
/// The therapist portal still uses the original dark-mode shell with tabs.
class MainLayout extends ConsumerWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(appModeProvider);

    if (mode == AppMode.therapist) {
      return _TherapistShell(ref: ref);
    }

    // ── Patient mode: full-screen immersive, no app-level chrome ─────────
    return _PatientFlow();
  }
}

// ── Patient Flow — full-screen per-step ──────────────────────────────────────

class _PatientFlow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = ref.watch(patientStepProvider);

    // Determine the status-bar style per step
    // Light steps (contextPreview, dailySummary) → dark icons
    // Dark steps (hiddenScene) → light icons
    final isDarkStep = step == PatientStep.hiddenScene;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDarkStep
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _bgForStep(step),
        body: SafeArea(
          // Scene screen manages its own SafeArea internally
          top: step == PatientStep.hiddenScene ? false : true,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: KeyedSubtree(key: ValueKey(step), child: _buildStep(step)),
          ),
        ),
      ),
    );
  }

  Color _bgForStep(PatientStep step) {
    switch (step) {
      case PatientStep.contextPreview:
        return Colors.white;
      case PatientStep.hiddenScene:
        return const Color(0xFF0F172A);
      case PatientStep.dailySummary:
        return const Color(0xFF0F172A);
      case PatientStep.patterns:
        return const Color(0xFF0F172A);
    }
  }

  Widget _buildStep(PatientStep step) {
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

// ── Therapist Shell — keeps full dark chrome ──────────────────────────────────

class _TherapistShell extends StatelessWidget {
  const _TherapistShell({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.backgroundStart, AppColors.backgroundEnd],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _TherapistHeader(ref: ref),
              const Expanded(child: TherapistPortalScreen()),
            ],
          ),
        ),
      ),
    );
  }
}

class _TherapistHeader extends StatelessWidget {
  const _TherapistHeader({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
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
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.visibility,
                  size: 16,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'S E E N  —  Therapist Portal',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 1.5,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => modeNotifier.set(AppMode.patient),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Patient View',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
