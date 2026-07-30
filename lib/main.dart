import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentation/screens/seen_experience.dart';

void main() {
  runApp(const ProviderScope(child: SeenApp()));
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
