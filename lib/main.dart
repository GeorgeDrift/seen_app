import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/local/demo_profiles.dart';
import 'data/services/passive_data_service.dart';
import 'presentation/providers/api_providers.dart';
import 'presentation/screens/seen_experience.dart';

/// How long to wait for real device data (health/calendar/location, plus any
/// first-run permission prompts) before giving up and letting the app start
/// with demo values instead. The OS's native launch screen stays up for this
/// whole window since it's before `runApp`, so this trades a slightly longer
/// cold start for never showing a fallback value that then jumps to a real
/// one once collection finishes.
const _passiveDataPrefetchTimeout = Duration(seconds: 8);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final fallback = DemoProfiles.all.first.context;
  PassiveDataResult? prefetched;
  try {
    prefetched = await PassiveDataService()
        .collect(fallback: fallback)
        .timeout(_passiveDataPrefetchTimeout);
  } catch (e) {
    developer.log(
      'Passive data prefetch failed or timed out ($e) — '
      'starting with demo values instead.',
      name: 'PassiveData',
    );
    prefetched = null;
  }

  runApp(
    ProviderScope(
      overrides: [prefetchedPassiveDataProvider.overrideWithValue(prefetched)],
      child: const SeenApp(),
    ),
  );
}

class SeenApp extends StatelessWidget {
  const SeenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Seen — Behavioral Annotation & Therapist System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'DMSans',
        colorScheme: const ColorScheme.light(primary: Color(0xff7b6a9e)),
        scaffoldBackgroundColor: const Color(0xfff3f1f8),
      ),
      home: const SeenExperience(),
    );
  }
}
