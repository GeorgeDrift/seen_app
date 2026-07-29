import 'package:flutter/material.dart';
import 'models.dart';
import 'engine.dart';

class AppState extends ChangeNotifier {
  // Navigation & Mode state
  String _mode = 'patient'; // 'patient' or 'therapist'
  int _patientStep = 0; // 0 = Context Preview, 1 = Interactive Scene, 2 = Daily Summary, 3 = Longitudinal Patterns

  // Demo Profiles & Context
  String _activeProfileName = 'Profile A (Overloaded)';
  DailyContext _currentContext = DemoProfiles.profileA;
  
  // Engine outputs
  List<InterpretedSignal> _interpretedSignals = [];
  SceneComposition? _sceneComposition;
  final List<Clue> _clueCatalog = getFullClueCatalog();
  final List<String> _recentClueIds = [];

  // Hint System state (0 = off, 1 = general region, 2 = outline clues)
  int _hintLevel = 0;

  // Selections & History
  final List<ClueSelection> _todaySelections = [];
  final List<DailyEntry> _historicalEntries = [];

  // Getters
  String get mode => _mode;
  int get patientStep => _patientStep;
  String get activeProfileName => _activeProfileName;
  DailyContext get currentContext => _currentContext;
  List<InterpretedSignal> get interpretedSignals => _interpretedSignals;
  SceneComposition? get sceneComposition => _sceneComposition;
  List<Clue> get visibleClues => _sceneComposition?.visibleClues ?? [];
  int get hintLevel => _hintLevel;
  List<ClueSelection> get todaySelections => _todaySelections;
  List<DailyEntry> get historicalEntries => _historicalEntries;

  AppState() {
    _recalculateEngine();
    _generate14DayHistoricalDataset();
  }

  void setMode(String newMode) {
    _mode = newMode;
    notifyListeners();
  }

  void setPatientStep(int step) {
    _patientStep = step;
    notifyListeners();
  }

  void setDemoProfile(String profileName) {
    _activeProfileName = profileName;
    if (profileName.contains('Profile A')) {
      _currentContext = DemoProfiles.profileA;
    } else if (profileName.contains('Profile B')) {
      _currentContext = DemoProfiles.profileB;
    } else if (profileName.contains('Profile C')) {
      _currentContext = DemoProfiles.profileC;
    }
    _todaySelections.clear();
    _hintLevel = 0;
    _recalculateEngine();
    notifyListeners();
  }

  void updateContext({
    double? sleepHours,
    int? steps,
    int? calendarEventCount,
    String? calendarLoad,
    String? weather,
    String? sleepComparison,
    String? activityComparison,
  }) {
    _currentContext = _currentContext.copyWith(
      sleepHours: sleepHours,
      steps: steps,
      calendarEventCount: calendarEventCount,
      calendarLoad: calendarLoad,
      weather: weather,
      sleepComparison: sleepComparison,
      activityComparison: activityComparison,
    );
    _recalculateEngine();
    notifyListeners();
  }

  void triggerHint() {
    if (_hintLevel < 2) {
      _hintLevel++;
    } else {
      _hintLevel = 0;
    }
    notifyListeners();
  }

  void resetHint() {
    _hintLevel = 0;
    notifyListeners();
  }

  void addClueSelection(ClueSelection sel) {
    _todaySelections.removeWhere((s) => s.clueId == sel.clueId);
    _todaySelections.add(sel);
    notifyListeners();
  }

  void _recalculateEngine() {
    _interpretedSignals = interpretSignals(_currentContext);
    _sceneComposition = composeScene(_clueCatalog, _interpretedSignals, _recentClueIds);
  }

  // --- PATTERN ENGINE (14-Day Co-occurrence Calculation) ---
  List<Map<String, dynamic>> calculatePatterns() {
    final List<Map<String, dynamic>> patterns = [];

    // Pattern 1: Short sleep & Quiet corner as restorative
    int shortSleepDays = 0;
    int quietCornerRestorative = 0;
    for (var entry in _historicalEntries) {
      final isShortSleep = entry.context.sleepHours != null && entry.context.sleepHours! < 6.5;
      if (isShortSleep) shortSleepDays++;
      
      final hasQuietCornerRestorative = entry.selectedClues.any((s) => 
        s.clueId == 'quiet_corner_01' && (s.userMeaning?.contains('Restorative') == true || s.userMeaning?.contains('recovery') == true));
      if (isShortSleep && hasQuietCornerRestorative) quietCornerRestorative++;
    }
    if (shortSleepDays > 0) {
      patterns.add({
        'title': 'Quiet Solitude on Short Sleep Days',
        'desc': 'On $quietCornerRestorative of the $shortSleepDays days with short sleep (<6.5h), you selected Quiet Corner as restorative.',
        'tag': 'Restorative Solitude',
        'color': const Color(0xFF00BFA5),
        'count': quietCornerRestorative,
        'total': shortSleepDays,
      });
    }

    // Pattern 2: Heavy workload & Meeting overload
    int heavyWorkloadDays = 0;
    int meetingDraining = 0;
    for (var entry in _historicalEntries) {
      final isHeavy = entry.context.calendarLoad == 'high' || entry.context.calendarEventCount >= 6;
      if (isHeavy) heavyWorkloadDays++;

      final hasDrainingMeeting = entry.selectedClues.any((s) => 
        s.clueId == 'meeting_overload_01' && s.userMeaning == 'Draining');
      if (isHeavy && hasDrainingMeeting) meetingDraining++;
    }
    if (heavyWorkloadDays > 0) {
      patterns.add({
        'title': 'Schedule Density & Energy Drain',
        'desc': 'Meeting Overload was marked as "Draining" on $meetingDraining of $heavyWorkloadDays high-density calendar days.',
        'tag': 'Workload Drain',
        'color': const Color(0xFFFBBF24),
        'count': meetingDraining,
        'total': heavyWorkloadDays,
      });
    }

    // Pattern 3: High Movement & Head Clearing
    int highMovementDays = 0;
    int headClearingWorkout = 0;
    for (var entry in _historicalEntries) {
      final isHighMove = entry.context.steps != null && entry.context.steps! > 8000;
      if (isHighMove) highMovementDays++;

      final hasWorkoutHeadClear = entry.selectedClues.any((s) => 
        s.clueId == 'walking_shoes_01' && s.userMeaning?.contains('Workout') == true);
      if (isHighMove && hasWorkoutHeadClear) headClearingWorkout++;
    }
    if (highMovementDays > 0) {
      patterns.add({
        'title': 'Active Movement for Mindset',
        'desc': 'On $headClearingWorkout of $highMovementDays high-step days (>8k steps), walking/running was marked as "Workout to clear head".',
        'tag': 'Active Recovery',
        'color': const Color(0xFF34D399),
        'count': headClearingWorkout,
        'total': highMovementDays,
      });
    }

    return patterns;
  }

  // --- EHR CLINICAL SUMMARY GENERATOR (Therapist View) ---
  String getEhrSummary() {
    final patterns = calculatePatterns();
    final totalDays = _historicalEntries.length;
    final buffer = StringBuffer();
    buffer.writeln("=== SEEN PATIENT BEHAVIORAL ANNOTATION SUMMARY ===");
    buffer.writeln("Patient ID: Alex Morgan (#P-4089)");
    buffer.writeln("Observation Period: 14 Days ($totalDays completed daily entries)");
    buffer.writeln("Data Provenance: Self-annotated visual context logs (Zero PII raw telemetry stored)");
    buffer.writeln("");
    buffer.writeln("--- KEY OBSERVED ASSOCIATIONS (NON-CAUSAL) ---");
    for (var p in patterns) {
      buffer.writeln("• ${p['title']}: ${p['desc']}");
    }
    buffer.writeln("");
    buffer.writeln("--- THERAPIST CLINICAL NOTES ---");
    buffer.writeln("Patient consistently leverages solitary quiet moments on high-demand days as restorative recovery rather than isolation.");
    return buffer.toString();
  }

  // Generate 14-day synthetic dataset
  void _generate14DayHistoricalDataset() {
    final now = DateTime.now();
    for (int i = 1; i <= 14; i++) {
      final dt = now.subtract(Duration(days: i));
      final dateStr = "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
      final isOverloaded = (i % 3 == 0);
      final isActive = (i % 3 == 1);

      final ctx = isOverloaded
          ? DailyContext(date: dateStr, sleepHours: 5.5, sleepComparison: 'lower', steps: 2400, activityComparison: 'lower', calendarEventCount: 7, calendarLoad: 'high', weather: 'rain')
          : (isActive
              ? DailyContext(date: dateStr, sleepHours: 7.6, sleepComparison: 'typical', steps: 9800, activityComparison: 'higher', calendarEventCount: 2, calendarLoad: 'low', weather: 'sunny')
              : DailyContext(date: dateStr, sleepHours: 8.2, sleepComparison: 'typical', steps: 3400, activityComparison: 'lower', calendarEventCount: 1, calendarLoad: 'low', weather: 'cloudy'));

      final sigs = interpretSignals(ctx);
      final selections = <ClueSelection>[];

      if (isOverloaded) {
        selections.add(ClueSelection(
          clueId: 'quiet_corner_01',
          clueTitle: 'Quiet Corner',
          selectedAt: dt,
          userMeaning: 'Restorative solitude',
          confidence: 'clear',
        ));
        selections.add(ClueSelection(
          clueId: 'meeting_overload_01',
          clueTitle: 'Meeting Overload',
          selectedAt: dt,
          userMeaning: 'Draining',
          confidence: 'clear',
        ));
      } else if (isActive) {
        selections.add(ClueSelection(
          clueId: 'walking_shoes_01',
          clueTitle: 'Walking Shoes',
          selectedAt: dt,
          userMeaning: 'Workout to clear head',
          confidence: 'clear',
        ));
      }

      _historicalEntries.add(DailyEntry(
        id: 'entry_$i',
        date: dateStr,
        context: ctx,
        interpretedSignals: sigs,
        displayedClueIds: ['quiet_corner_01', 'meeting_overload_01', 'walking_shoes_01'],
        selectedClues: selections,
        generatedSummary: generateConfirmedDailySummary(selections),
      ));
    }
  }
}
