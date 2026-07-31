import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../data/models/health_week_day.dart';
import '../../data/models/health_week_insights.dart';
import '../../domain/engine/reflection_habits_engine.dart';
import '../controllers/health_over_time_controller.dart';
import 'profile_screen.dart';

// ─────────────────────────────────────────────────────────────────────────
// Palette / type — mirrors seen_experience.dart's private tokens exactly
// (confirmed to match the Figma mockup's literal hex values 1:1). Kept
// local since the originals are file-private, not a cross-cutting refactor.
// ─────────────────────────────────────────────────────────────────────────

const _ink = Color(0xff2a2733);
const _muted = Color(0xff8a849a);
const _purple = Color(0xff7b6a9e);
const _softPurple = Color(0xffede9f5);
const _surface = Color(0xfff3f1f8);
const _white = Color(0xfffdfbff);
const _lavender = Color(0xffb8a9d4);

String _iconAsset(String name) => 'assets/icons/patterns/$name.svg';

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
  FontStyle style = FontStyle.normal,
}) {
  return TextStyle(
    fontFamily: 'Lora',
    color: color,
    fontSize: size,
    height: height,
    fontWeight: weight,
    fontStyle: style,
  );
}

TextStyle _kicker({Color color = _muted}) =>
    _sans(color: color, size: 11, weight: FontWeight.w600, letterSpacing: 1.1);

// ─────────────────────────────────────────────────────────────────────────
// Data shaping — turns the real health_over_time_controller.dart data into
// exactly what each widget below needs. Sleep/movement thresholds mirror
// scoring_engine.dart's Recovery/Activation cutoffs (sleep <6.5h/≥8h, steps
// <3,000/>8,000) — same established cutoffs, not new ones. Calendar/weather
// are already categorical so they map directly.
// ─────────────────────────────────────────────────────────────────────────

double _sleepIntensity(double hours) {
  if (hours < 6.5) return 0.09;
  if (hours >= 8.0) return 0.75;
  return 0.45;
}

double _stepsIntensity(int steps) {
  if (steps < 3000) return 0.09;
  if (steps > 8000) return 0.75;
  return 0.45;
}

double _calendarIntensity(String load) {
  switch (load) {
    case 'Busy':
      return 0.75;
    case 'Light':
      return 0.09;
    default:
      return 0.35; // 'Moderate' or anything unrecognized
  }
}

/// Shortened to fit the narrow heatmap cells, matching the mockup's own
/// abbreviations ("Full"/"Mod"/"Low" rather than the raw
/// "Busy"/"Moderate"/"Light" values).
String _calendarCellLabel(String load) {
  switch (load) {
    case 'Busy':
      return 'Full';
    case 'Moderate':
      return 'Mod';
    case 'Light':
      return 'Low';
    default:
      return load;
  }
}

String _weatherEmoji(String condition) {
  switch (condition) {
    case 'Rainy':
      return '🌧️';
    case 'Sunny':
      return '☀️';
    case 'Cloudy':
      return '☁️';
    default:
      return '⛅';
  }
}

String _weekdayLabel(DateTime date) =>
    const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];

class _InsightSlide {
  const _InsightSlide({
    required this.label,
    required this.body,
    required this.tags,
    required this.basis,
  });

  final String label;
  final String body;
  final List<String> tags;
  final String basis;
}

List<_InsightSlide> _insightSlides(WeeklyInsights insights) {
  final slides = <_InsightSlide>[];

  final pattern = insights.patternWorthNoticing;
  if (pattern.summary.trim().isNotEmpty && pattern.supportingDayCount > 0) {
    final days = pattern.supportingDayCount;
    slides.add(
      _InsightSlide(
        label: pattern.title,
        body: pattern.summary,
        tags: pattern.signals,
        basis: 'Based on $days reflected day${days == 1 ? '' : 's'}',
      ),
    );
  }

  final helping = insights.whatMayBeHelping;
  if (helping.title.trim().isNotEmpty && helping.summary.trim().isNotEmpty) {
    final count = helping.supportingReflectionCount;
    slides.add(
      _InsightSlide(
        label: helping.title,
        body: helping.summary,
        tags: helping.signals,
        basis: 'Based on $count reflection${count == 1 ? '' : 's'}',
      ),
    );
  }

  return slides;
}

class _HabitBar {
  const _HabitBar({required this.height, required this.tone});
  final double height;
  final String tone; // 'quiet' | 'warm' | 'peak'
}

const _toneColors = {
  'quiet': Color.fromRGBO(123, 106, 158, 0.08),
  'warm': Color.fromRGBO(123, 106, 158, 0.28),
  'peak': _purple,
};

List<_HabitBar> _habitBars(List<int> hourlyCounts) {
  if (hourlyCounts.isEmpty) {
    return List.generate(24, (_) => const _HabitBar(height: 4, tone: 'quiet'));
  }
  final maxCount = hourlyCounts.reduce(math.max);
  return hourlyCounts.map((count) {
    if (maxCount == 0 || count == 0) {
      return const _HabitBar(height: 4, tone: 'quiet');
    }
    final height = 4 + 32 * (count / maxCount);
    return _HabitBar(height: height, tone: count == maxCount ? 'peak' : 'warm');
  }).toList();
}

const _themeIconBgs = [
  Color.fromRGBO(139, 125, 184, 0.12),
  Color.fromRGBO(122, 155, 181, 0.12),
  Color.fromRGBO(168, 137, 106, 0.12),
];

// ─────────────────────────────────────────────────────────────────────────
// Small presentational pieces
// ─────────────────────────────────────────────────────────────────────────

class _PatternsHeader extends StatelessWidget {
  const _PatternsHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Patterns',
                  style: _lora(
                    size: 26,
                    weight: FontWeight.w500,
                    height: 1.5,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'How your context and reflections connect over time',
                  style: _sans(color: _muted, size: 13, height: 1.4),
                ),
              ],
            ),
          ),
          // TODO: wire up to an actual date-range picker.
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _softPurple,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '7 days',
                  style: _sans(
                    color: _purple,
                    size: 12,
                    weight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 5),
                SvgPicture.asset(
                  _iconAsset('chevron-down-small'),
                  width: 10,
                  height: 10,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
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
      child: child,
    );
  }
}

class _WeekStreakCard extends StatelessWidget {
  const _WeekStreakCard({required this.days});
  final List<HealthWeekDay> days;

  @override
  Widget build(BuildContext context) {
    final completed = days.where((d) => d.reflection.completed).length;

    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('YOUR PAST 7 DAYS', style: _kicker())),
              const SizedBox(width: 8),
              SvgPicture.asset(
                _iconAsset('chevron-left'),
                width: 16,
                height: 16,
              ),
              const SizedBox(width: 8),
              SvgPicture.asset(
                _iconAsset('chevron-right'),
                width: 16,
                height: 16,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: days.map((day) {
              final date = DateTime.parse(day.date);
              final reflected = day.reflection.completed;
              return Expanded(
                child: Column(
                  children: [
                    Text(
                      _weekdayLabel(date),
                      style: _sans(
                        size: 10,
                        weight: FontWeight.w500,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (reflected)
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(110, 175, 130, 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color.fromRGBO(110, 175, 130, 0.4),
                          ),
                        ),
                        child: Center(
                          child: SvgPicture.asset(
                            _iconAsset('check-icon'),
                            width: 14,
                            height: 14,
                          ),
                        ),
                      )
                    else
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xffd4d0dc),
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 8,
                            height: 1.5,
                            decoration: BoxDecoration(
                              color: const Color(0xffc4c0cc),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      '${date.day}',
                      style: _sans(size: 10, weight: FontWeight.w500),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              '$completed of ${days.length} days reflected',
              style: _sans(color: _muted, size: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeatmapCell extends StatelessWidget {
  const _HeatmapCell({this.text, this.emoji, this.intensity});

  final String? text;
  final String? emoji;
  final double? intensity;

  @override
  Widget build(BuildContext context) {
    if (emoji != null) {
      return Expanded(
        child: Container(
          height: 30,
          decoration: BoxDecoration(
            color: const Color.fromRGBO(139, 125, 184, 0.06),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Text(emoji!, style: const TextStyle(fontSize: 13)),
        ),
      );
    }
    final level = intensity ?? 0;
    final textColor = level >= 0.45 ? const Color(0xff4a4260) : _muted;
    return Expanded(
      child: Container(
        height: 30,
        decoration: BoxDecoration(
          color: Color.fromRGBO(139, 125, 184, level),
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: Text(
          text ?? '',
          style: _sans(color: textColor, size: 9, weight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _WeekAtGlanceCard extends StatefulWidget {
  const _WeekAtGlanceCard({required this.days});
  final List<HealthWeekDay> days;

  @override
  State<_WeekAtGlanceCard> createState() => _WeekAtGlanceCardState();
}

class _WeekAtGlanceCardState extends State<_WeekAtGlanceCard> {
  bool _gridView = true;

  @override
  Widget build(BuildContext context) {
    final days = widget.days;

    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('YOUR WEEK AT A GLANCE', style: _kicker())),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: _softPurple,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _ToggleButton(
                      icon: 'toggle-icon-1',
                      selected: !_gridView,
                      onTap: () => setState(() => _gridView = false),
                    ),
                    _ToggleButton(
                      icon: 'toggle-icon-2',
                      selected: _gridView,
                      onTap: () => setState(() => _gridView = true),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 52,
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      for (final label in const ['Sleep', 'Move', 'Weather', 'Cal.'])
                        SizedBox(
                          height: 30,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: Text(
                                label,
                                style: _sans(color: _muted, size: 10, weight: FontWeight.w500),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          for (final day in days)
                            Expanded(
                              child: SizedBox(
                                height: 24,
                                child: Center(
                                  child: Text(
                                    _weekdayLabel(DateTime.parse(day.date)),
                                    style: _sans(
                                      color: _muted,
                                      size: 9,
                                      weight: FontWeight.w600,
                                      letterSpacing: 0.27,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          for (final day in days)
                            _HeatmapCell(
                              text: '${day.sleep.durationHours.toStringAsFixed(1)}h',
                              intensity: _sleepIntensity(day.sleep.durationHours),
                            ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          for (final day in days)
                            _HeatmapCell(
                              text: '${(day.movement.steps / 1000).toStringAsFixed(1)}k',
                              intensity: _stepsIntensity(day.movement.steps),
                            ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          for (final day in days)
                            _HeatmapCell(emoji: _weatherEmoji(day.weather.condition)),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          for (final day in days)
                            _HeatmapCell(
                              text: _calendarCellLabel(day.calendar.load),
                              intensity: _calendarIntensity(day.calendar.load),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.only(top: 13),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color.fromRGBO(123, 106, 158, 0.08)),
              ),
            ),
            child: Row(
              children: [
                Text('Less', style: _sans(color: _muted, size: 10)),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    children: [
                      for (final level in const [0.09, 0.22, 0.45, 0.75])
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1.5),
                            height: 10,
                            decoration: BoxDecoration(
                              color: Color.fromRGBO(139, 125, 184, level),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text('More', style: _sans(color: _muted, size: 10)),
                const SizedBox(width: 6),
                Text(
                  '· Weather uses icons',
                  style: _sans(color: _lavender, size: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? _white : null,
          borderRadius: BorderRadius.circular(6),
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
        child: SvgPicture.asset(_iconAsset(icon), width: 14, height: 14),
      ),
    );
  }
}

class _InsightCarousel extends StatefulWidget {
  const _InsightCarousel({required this.slides});
  final List<_InsightSlide> slides;

  @override
  State<_InsightCarousel> createState() => _InsightCarouselState();
}

class _InsightCarouselState extends State<_InsightCarousel> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final slides = widget.slides;
    final insight = slides.isEmpty
        ? const _InsightSlide(
            label: 'Still gathering insights',
            body:
                'Keep reflecting and patterns will start to show up here — '
                'nothing forced, just what your own words support.',
            tags: [],
            basis: '',
          )
        : slides[_index.clamp(0, slides.length - 1)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('INSIGHTS', style: _kicker()),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment(-0.7, -1),
              end: Alignment(0.7, 1),
              colors: [Color(0xff2a2733), Color(0xff3d3450)],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(42, 39, 51, 0.22),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                insight.label.toUpperCase(),
                style: _sans(
                  color: _lavender,
                  size: 10,
                  weight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                insight.body,
                style: _lora(color: const Color(0xfff3f1f8), size: 15, height: 1.6),
              ),
              if (insight.tags.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: insight.tags
                      .map(
                        (tag) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(184, 169, 212, 0.18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            tag,
                            style: _sans(
                              color: const Color(0xffc4a8e8),
                              size: 10,
                              weight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
              if (insight.basis.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        insight.basis,
                        style: _sans(color: _muted, size: 11),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(184, 169, 212, 0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'See how this was found',
                        style: _sans(
                          color: const Color(0xffc4a8e8),
                          size: 11,
                          weight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (slides.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < slides.length; i++)
                GestureDetector(
                  onTap: () => setState(() => _index = i),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _index ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _index ? _purple : const Color(0xffd4ceea),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ReflectionCard extends StatefulWidget {
  const _ReflectionCard({
    required this.theme,
    required this.iconBg,
    required this.defaultOpen,
  });

  final WeeklyTheme theme;
  final Color iconBg;
  final bool defaultOpen;

  @override
  State<_ReflectionCard> createState() => _ReflectionCardState();
}

class _ReflectionCardState extends State<_ReflectionCard> {
  late bool _open = widget.defaultOpen;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final expandable = theme.quotes.isNotEmpty || theme.description.isNotEmpty;
    final clueSuffix = theme.relatedClues.isNotEmpty
        ? ' · clue: ${theme.relatedClues.first.toLowerCase()}'
        : '';
    final count = theme.reflectionCount;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color.fromRGBO(123, 106, 158, 0.07)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(123, 106, 158, 0.08),
            blurRadius: 8,
            offset: Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: expandable ? () => setState(() => _open = !_open) : null,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: widget.iconBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: SvgPicture.asset(
                      _iconAsset('sparkle-icon'),
                      width: 20,
                      height: 20,
                      colorFilter: const ColorFilter.mode(_ink, BlendMode.srcIn),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          theme.title,
                          style: _sans(size: 13, weight: FontWeight.w600, height: 1.3),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$count reflection${count == 1 ? '' : 's'}$clueSuffix',
                          style: _sans(color: _muted, size: 12, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: AnimatedRotation(
                      turns: expandable && _open ? 0.5 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: SvgPicture.asset(
                        _iconAsset(expandable ? 'chevron-accordion' : 'chevron-static'),
                        width: 16,
                        height: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (expandable && _open)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color.fromRGBO(123, 106, 158, 0.07)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (theme.description.isNotEmpty)
                    Text(
                      theme.description,
                      style: _sans(color: const Color(0xff4a4260), size: 13, height: 1.6),
                    ),
                  if (theme.quotes.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: theme.quotes
                          .map(
                            (quote) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Container(
                                padding: const EdgeInsets.only(left: 15),
                                decoration: const BoxDecoration(
                                  border: Border(
                                    left: BorderSide(color: Color(0xff8b7db8), width: 3),
                                  ),
                                ),
                                child: Text(
                                  '“$quote”',
                                  style: _lora(
                                    style: FontStyle.italic,
                                    size: 13,
                                    height: 1.55,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _WhatShowingUpSection extends StatelessWidget {
  const _WhatShowingUpSection({required this.themes});
  final List<WeeklyTheme> themes;

  @override
  Widget build(BuildContext context) {
    if (themes.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What has been showing up',
          style: _lora(size: 17, weight: FontWeight.w500, height: 1.5),
        ),
        const SizedBox(height: 2),
        Text(
          'Drawn from the words and moments you chose',
          style: _sans(color: _muted, size: 12, height: 1.4),
        ),
        const SizedBox(height: 10),
        Column(
          children: [
            for (var i = 0; i < themes.length; i++)
              Padding(
                padding: EdgeInsets.only(bottom: i == themes.length - 1 ? 0 : 8),
                child: _ReflectionCard(
                  theme: themes[i],
                  iconBg: _themeIconBgs[i % _themeIconBgs.length],
                  defaultOpen: i == 0,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ReflectionHabitsCard extends StatelessWidget {
  const _ReflectionHabitsCard({required this.habits});
  final ReflectionHabits habits;

  @override
  Widget build(BuildContext context) {
    final bars = _habitBars(habits.hourlyCounts);
    final hasRange = habits.timeRangeLabel.isNotEmpty;

    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('YOUR REFLECTION HABITS', style: _kicker()),
          const SizedBox(height: 12),
          Text(
            'You reflected on ${habits.completedCount} of the past ${habits.totalDays} days.',
            style: _lora(size: 15, height: 1.55),
          ),
          if (hasRange) ...[
            const SizedBox(height: 4),
            Text(
              'Most reflections were completed between ${habits.timeRangeLabel}.',
              style: _sans(color: const Color(0xff4a4260), size: 13, height: 1.55),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: 36,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final bar in bars)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: Container(
                        height: bar.height,
                        decoration: BoxDecoration(
                          color: _toneColors[bar.tone],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final label in const ['6 AM', '12 PM', '6 PM', '12 AM'])
                Text(label, style: _sans(color: _lavender, size: 9)),
            ],
          ),
          if (habits.consistentWindow && habits.typicalWindowLabel.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Your most consistent time was in the ${habits.typicalWindowLabel}.',
              style: _sans(color: _muted, size: 12, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(123, 106, 158, 0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: SvgPicture.asset(_iconAsset('info-icon'), width: 16, height: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Patterns are based on the context available and the '
              'reflections you confirmed. They are not medical conclusions.',
              style: _sans(color: _muted, size: 12, height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}

class _PatternsBottomNav extends StatelessWidget {
  const _PatternsBottomNav();

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
            icon: 'nav-icon-today',
            label: 'Today',
            selected: false,
            onTap: () => Navigator.of(context).pop(),
          ),
          const _NavTab(icon: 'nav-icon-patterns', label: 'Patterns', selected: true),
          _NavTab(
            icon: 'nav-icon-profile',
            label: 'Profile',
            selected: false,
            onTap: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
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

  final String icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? _purple : _muted;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 4),
          child: Column(
            children: [
              SvgPicture.asset(_iconAsset(icon), width: 22, height: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: _sans(
                  color: color,
                  size: 11,
                  weight: selected ? FontWeight.w600 : FontWeight.w400,
                  letterSpacing: 0.11,
                ),
              ),
              const SizedBox(height: 4),
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

// ─────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────

class PatternsScreen extends ConsumerWidget {
  const PatternsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(healthWeekDatasetProvider);
    final habits = ref.watch(reflectionHabitsProvider);
    final insightsAsync = ref.watch(weeklyInsightsProvider);

    return Scaffold(
      backgroundColor: _surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _PatternsHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _WeekStreakCard(days: days),
                    const SizedBox(height: 14),
                    _WeekAtGlanceCard(days: days),
                    const SizedBox(height: 14),
                    insightsAsync.when(
                      data: (insights) =>
                          _InsightCarousel(slides: _insightSlides(insights)),
                      loading: () => const _InsightCarousel(slides: []),
                      error: (_, _) => const _InsightCarousel(slides: []),
                    ),
                    const SizedBox(height: 14),
                    insightsAsync.when(
                      data: (insights) =>
                          _WhatShowingUpSection(themes: insights.themes),
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 14),
                    _ReflectionHabitsCard(habits: habits),
                    const SizedBox(height: 14),
                    const _Disclaimer(),
                  ],
                ),
              ),
            ),
            const _PatternsBottomNav(),
          ],
        ),
      ),
    );
  }
}
