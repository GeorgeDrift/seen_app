import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which top-level surface the user is looking at.
enum AppMode { patient, therapist }

/// Which of the four MVP screens the patient flow is on.
enum PatientStep { contextPreview, hiddenScene, dailySummary, patterns }

/// Whether the intro walkthrough has been completed.
final walkthroughDoneProvider =
    NotifierProvider<WalkthroughDoneController, bool>(
      WalkthroughDoneController.new,
    );

class WalkthroughDoneController extends Notifier<bool> {
  @override
  bool build() => false;

  void markDone() => state = true;
  void reset() => state = false;
}

/// Which top-level pane (patient vs therapist portal) is showing.
final appModeProvider = NotifierProvider<AppModeController, AppMode>(
  AppModeController.new,
);

class AppModeController extends Notifier<AppMode> {
  @override
  AppMode build() => AppMode.patient;

  void set(AppMode m) => state = m;
}

/// Which step of the patient flow (0..3) is showing.
final patientStepProvider =
    NotifierProvider<PatientStepController, PatientStep>(
      PatientStepController.new,
    );

class PatientStepController extends Notifier<PatientStep> {
  @override
  PatientStep build() => PatientStep.contextPreview;

  void go(PatientStep step) => state = step;

  void next() {
    final values = PatientStep.values;
    final i = values.indexOf(state);
    if (i < values.length - 1) state = values[i + 1];
  }
}
