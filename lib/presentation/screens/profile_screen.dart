import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/demo_profiles.dart';
import '../../data/models/daily_context.dart';
import '../../data/models/demo_profile.dart';
import '../controllers/profile_controller.dart';
import 'patterns_screen.dart';

// ─────────────────────────────────────────────────────────────────────────
// Palette / type — mirrors seen_experience.dart's/patterns_screen.dart's
// private tokens, kept local per this codebase's existing per-file
// convention rather than a cross-cutting theme refactor.
// ─────────────────────────────────────────────────────────────────────────

const _ink = Color(0xff2a2733);
const _muted = Color(0xff8a849a);
const _purple = Color(0xff7b6a9e);
const _softPurple = Color(0xffede9f5);
const _surface = Color(0xfff3f1f8);
const _white = Color(0xfffdfbff);

TextStyle _sans({
  Color color = _ink,
  double size = 13,
  double height = 1.4,
  FontWeight weight = FontWeight.w400,
  double letterSpacing = 0,
}) {
  return TextStyle(
    fontFamily: 'DMSans',
    color: color,
    fontSize: size,
    height: height,
    fontWeight: weight,
    letterSpacing: letterSpacing,
  );
}

TextStyle _lora({
  Color color = _ink,
  double size = 15,
  double? height,
  FontWeight weight = FontWeight.w400,
}) {
  return TextStyle(
    fontFamily: 'Lora',
    color: color,
    fontSize: size,
    height: height,
    fontWeight: weight,
  );
}

String _formatSleep(double? hours) {
  if (hours == null) return '—';
  final whole = hours.floor();
  final minutes = ((hours - whole) * 60).round();
  return '${whole}h ${minutes}m';
}

String _formatNumber(int? value) {
  if (value == null) return '—';
  return value.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );
}

String _titleCase(String value) {
  if (value.isEmpty) return value;
  final normalized = value == 'rain' ? 'rainy' : value;
  return '${normalized[0].toUpperCase()}${normalized.substring(1)}';
}

/// 0-2 events: Free · 3-5: Moderate · 6+: Busy — mirrors the same thresholds
/// used on the Today screen's glimpse card.
String _calendarLoadLabel(int eventCount) {
  if (eventCount < 3) return 'Free';
  if (eventCount <= 5) return 'Moderate';
  return 'Busy';
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(activeProfileProvider);
    final notifier = ref.read(activeProfileProvider.notifier);

    return Scaffold(
      backgroundColor: _surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profile',
                    style: _lora(size: 26, weight: FontWeight.w500, height: 1.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Switch between your real device data and test profiles.',
                    style: _sans(color: _muted, size: 13, height: 1.4),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ModeToggle(
                      mode: profile.mode,
                      onSelectReal: notifier.useRealData,
                      onSelectDemo: () {
                        if (profile.mode != DataSourceMode.demo) {
                          notifier.selectByKey(DemoProfileKey.a);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    if (profile.mode == DataSourceMode.real)
                      _RealDataCard(dailyContext: profile.context)
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final demo in DemoProfiles.all)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _DemoProfileCard(
                                profile: demo,
                                selected: profile.demoKey == demo.key,
                                onTap: () => notifier.selectByKey(demo.key),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const _ProfileBottomNav(),
          ],
        ),
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({
    required this.mode,
    required this.onSelectReal,
    required this.onSelectDemo,
  });

  final DataSourceMode mode;
  final VoidCallback onSelectReal;
  final VoidCallback onSelectDemo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: _softPurple,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeToggleButton(
              label: 'Real data',
              selected: mode == DataSourceMode.real,
              onTap: onSelectReal,
            ),
          ),
          Expanded(
            child: _ModeToggleButton(
              label: 'Demo profiles',
              selected: mode == DataSourceMode.demo,
              onTap: onSelectDemo,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeToggleButton extends StatelessWidget {
  const _ModeToggleButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _white : null,
          borderRadius: BorderRadius.circular(9),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color.fromRGBO(123, 106, 158, 0.14),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: _sans(
            color: selected ? _purple : _muted,
            size: 13,
            weight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _RealDataCard extends StatelessWidget {
  const _RealDataCard({required this.dailyContext});
  final DailyContext dailyContext;

  @override
  Widget build(BuildContext context) {
    final c = dailyContext;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(19, 19, 19, 17),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color.fromRGBO(123, 106, 158, 0.07)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(123, 106, 158, 0.08),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.smartphone_rounded, size: 16, color: _purple),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Using your real device data',
                  style: _sans(weight: FontWeight.w600, size: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _RealDataStat(
                  label: 'Sleep',
                  value: _formatSleep(c.sleepHours),
                ),
              ),
              Expanded(
                child: _RealDataStat(
                  label: 'Movement',
                  value: _formatNumber(c.steps),
                ),
              ),
              Expanded(
                child: _RealDataStat(
                  label: 'Weather',
                  value: _titleCase(c.weather),
                ),
              ),
              Expanded(
                child: _RealDataStat(
                  label: 'Calendar',
                  value: _calendarLoadLabel(c.calendarEventCount),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Sleep and calendar fall back to a demo value on this device '
            'whenever the real permission isn\'t granted or the source has '
            'nothing to report yet.',
            style: _sans(color: _muted, size: 11.5, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _RealDataStat extends StatelessWidget {
  const _RealDataStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: _sans(
            color: _muted,
            size: 9.5,
            weight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 4),
        Text(value, style: _sans(weight: FontWeight.w600, size: 13)),
      ],
    );
  }
}

class _DemoProfileCard extends StatelessWidget {
  const _DemoProfileCard({
    required this.profile,
    required this.selected,
    required this.onTap,
  });

  final DemoProfile profile;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? _purple : const Color.fromRGBO(123, 106, 158, 0.1),
            width: selected ? 1.4 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(123, 106, 158, 0.08),
              blurRadius: 8,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.label,
                    style: _sans(weight: FontWeight.w600, size: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile.description,
                    style: _sans(color: _muted, size: 12.5, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? _purple : Colors.transparent,
                border: Border.all(
                  color: selected ? _purple : const Color(0xffd4d0dc),
                  width: 1.4,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 15)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileBottomNav extends StatelessWidget {
  const _ProfileBottomNav();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: 1,
        bottom: 16 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: _white,
        border: Border(top: BorderSide(color: Color.fromRGBO(123, 106, 158, 0.1))),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(123, 106, 158, 0.07),
            blurRadius: 10,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          _NavTab(
            icon: Icons.calendar_today_outlined,
            label: 'Today',
            selected: false,
            onTap: () => Navigator.of(context).pop(),
          ),
          _NavTab(
            icon: Icons.show_chart_rounded,
            label: 'Patterns',
            selected: false,
            onTap: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const PatternsScreen()),
              );
            },
          ),
          const _NavTab(
            icon: Icons.person_outline_rounded,
            label: 'Profile',
            selected: true,
          ),
        ],
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.icon,
    required this.label,
    required this.selected,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? _purple : const Color(0xffc4b8d8);
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 4),
          child: Column(
            children: [
              Icon(icon, size: 21, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                style: _sans(
                  color: color,
                  size: 11,
                  weight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: selected ? _purple : Colors.transparent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
