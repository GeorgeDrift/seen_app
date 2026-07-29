import 'package:flutter/material.dart';
import 'theme.dart';
import 'models.dart';
import 'app_state.dart';
import 'screens/context_preview_screen.dart';
import 'widgets/scene_canvas.dart';
import 'widgets/question_sheet.dart';
import 'screens/daily_summary_screen.dart';
import 'screens/patterns_screen.dart';
import 'screens/therapist_portal.dart';
import 'screens/walkthrough_screen.dart';

void main() {
  runApp(const SeenApp());
}

class SeenApp extends StatelessWidget {
  const SeenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Seen — Behavioral Annotation & Therapist System',
      debugShowCheckedModeBanner: false,
      theme: getDarkSeenTheme(),
      home: const AppEntry(),
    );
  }
}

// ── Entry point: Walkthrough → Main App ────────────────────────────────────
class AppEntry extends StatefulWidget {
  const AppEntry({super.key});

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  bool _walkthroughDone = false;

  void _onWalkthroughComplete() {
    setState(() => _walkthroughDone = true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
        );
      },
      child: _walkthroughDone
          ? const MainLayout(key: ValueKey('main'))
          : WalkthroughScreen(
              key: const ValueKey('walkthrough'),
              onComplete: _onWalkthroughComplete,
            ),
    );
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final AppState _appState = AppState();

  @override
  void initState() {
    super.initState();
    _appState.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _appState.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
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
              // Top Header with Mode Switcher
              _buildTopHeader(),

              // Patient Journey Stepper Breadcrumbs (Only shown in Patient mode)
              if (_appState.mode == 'patient') _buildPatientJourneyStepper(),

              // Active Main View Content
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _appState.mode == 'therapist'
                      ? TherapistPortalScreen(appState: _appState)
                      : _buildPatientStepContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
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
          // Logo & Branding
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
                      color: AppColors.primary.withOpacity(0.3),
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

          // Patient vs Therapist Mode Switcher
          Row(
            children: [
              _buildModeToggleItem('patient', 'Patient View', Icons.person_outline),
              const SizedBox(width: 8),
              _buildModeToggleItem('therapist', 'Therapist Portal', Icons.medical_services_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggleItem(String modeKey, String label, IconData icon) {
    final isActive = _appState.mode == modeKey;

    return GestureDetector(
      onTap: () => _appState.setMode(modeKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withOpacity(0.08) : Colors.transparent,
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

  Widget _buildPatientJourneyStepper() {
    final step = _appState.patientStep;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        border: const Border(bottom: BorderSide(color: AppColors.borderTranslucent, width: 0.8)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildStepBreadcrumb(0, '1. Context Preview', step == 0),
            _buildStepDivider(),
            _buildStepBreadcrumb(1, '2. Hidden Scene', step == 1),
            _buildStepDivider(),
            _buildStepBreadcrumb(2, '3. Daily Summary', step == 2),
            _buildStepDivider(),
            _buildStepBreadcrumb(3, '4. 14-Day Patterns', step == 3),
          ],
        ),
      ),
    );
  }

  Widget _buildStepBreadcrumb(int index, String label, bool isActive) {
    return GestureDetector(
      onTap: () => _appState.setPatientStep(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildStepDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6),
      child: Icon(Icons.chevron_right, size: 14, color: AppColors.textSecondary),
    );
  }

  Widget _buildPatientStepContent() {
    final step = _appState.patientStep;
    switch (step) {
      case 0:
        return ContextPreviewScreen(
          appState: _appState,
          onProceedToScene: () => _appState.setPatientStep(1),
        );
      case 1:
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Expanded(
                child: SceneCanvas(
                  appState: _appState,
                  onClueTapped: _showQuestionnaire,
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _appState.setPatientStep(2),
                  icon: const Icon(Icons.check_circle_outline, color: AppColors.sage, size: 16),
                  label: const Text('Complete Daily Entry & View Summary →', style: TextStyle(color: AppColors.sage, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      case 2:
        return DailySummaryScreen(
          appState: _appState,
          onProceedToPatterns: () => _appState.setPatientStep(3),
        );
      case 3:
      default:
        return PatternsScreen(appState: _appState);
    }
  }

  void _showQuestionnaire(Clue clue) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ClueQuestionSheet(
        clue: clue,
        context: _appState.currentContext,
        onSelectionSaved: (selection) {
          _appState.addClueSelection(selection);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Recorded selection for ${clue.title}: '${selection.userMeaning}'"),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF0F172A),
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }
}
