import 'package:flutter/material.dart';
import '../app_state.dart';
import '../theme.dart';
import '../models.dart';

class ContextPreviewScreen extends StatelessWidget {
  final AppState appState;
  final VoidCallback onProceedToScene;

  const ContextPreviewScreen({
    super.key,
    required this.appState,
    required this.onProceedToScene,
  });

  @override
  Widget build(BuildContext context) {
    final ctx = appState.currentContext;
    final signals = appState.interpretedSignals;
    final activeProfile = appState.activeProfileName;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.query_stats, size: 14, color: AppColors.primary),
                SizedBox(width: 6),
                Text(
                  'SCREEN 1: DAILY CONTEXT PREVIEW',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Text(
            "Today's Passive Data Context",
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            "Passive data signals collected from sensors/apps. Seen uses these facts to compose today's visual hidden-object scene without guessing what they mean.",
            style: TextStyle(fontSize: 13, color: Colors.grey[400], height: 1.4),
          ),
          const SizedBox(height: 24),

          // Demo Profile Switcher
          Text(
            'Select Simulated Demo Profile:',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildProfileChip(context, 'Profile A (Overloaded)', Icons.thunderstorm_outlined, AppColors.coral),
                const SizedBox(width: 8),
                _buildProfileChip(context, 'Profile B (Active)', Icons.wb_sunny_outlined, AppColors.amber),
                const SizedBox(width: 8),
                _buildProfileChip(context, 'Profile C (Quiet Recovery)', Icons.bedtime_outlined, AppColors.sage),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Raw Telemetry Cards Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: isWide ? 4 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _buildMetricCard(
                    title: 'Sleep Duration',
                    value: '${ctx.sleepHours?.toStringAsFixed(1) ?? "--"} hrs',
                    subtitle: 'Baseline: ${ctx.sleepComparison.toUpperCase()}',
                    icon: Icons.dark_mode_outlined,
                    color: AppColors.sleep,
                  ),
                  _buildMetricCard(
                    title: 'Steps / Movement',
                    value: '${ctx.steps ?? 0}',
                    subtitle: 'Activity: ${ctx.activityComparison.toUpperCase()}',
                    icon: Icons.directions_walk,
                    color: AppColors.steps,
                  ),
                  _buildMetricCard(
                    title: 'Calendar Load',
                    value: '${ctx.calendarEventCount} events',
                    subtitle: 'Density: ${ctx.calendarLoad.toUpperCase()}',
                    icon: Icons.calendar_month,
                    color: AppColors.calendar,
                  ),
                  _buildMetricCard(
                    title: 'Weather & Env',
                    value: ctx.weather.toUpperCase(),
                    subtitle: 'Location: ${ctx.locationPattern}',
                    icon: Icons.cloud_outlined,
                    color: AppColors.weatherRain,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Signal Interpreter Engine Output
          GlassContainer(
            padding: const EdgeInsets.all(20),
            borderRadius: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.memory, color: AppColors.primary, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Signal Interpreter Output',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Non-Clinical Tags',
                        style: TextStyle(fontSize: 10, color: AppColors.sage, fontWeight: FontWeight.bold),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Raw data is transformed into non-judgmental semantic tags for clue scoring.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                ),
                const Divider(height: 24, color: AppColors.borderTranslucent),

                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: signals.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final sig = signals[index];
                    return Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    sig.tag,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '(${sig.source})',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                sig.explanation,
                                style: TextStyle(fontSize: 12, color: Colors.grey[300]),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'Strength: ${(sig.strength * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Proceed Button
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
              ),
              onPressed: onProceedToScene,
              icon: const Icon(Icons.palette_outlined, size: 18),
              label: const Text(
                'Proceed to Scene Composition →',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileChip(BuildContext context, String title, IconData icon, Color color) {
    final isSelected = appState.activeProfileName == title;
    return ChoiceChip(
      avatar: Icon(icon, size: 14, color: isSelected ? Colors.black : color),
      label: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isSelected ? Colors.black : Colors.white,
        ),
      ),
      selected: isSelected,
      selectedColor: color,
      backgroundColor: Colors.white.withOpacity(0.04),
      onSelected: (selected) {
        if (selected) appState.setDemoProfile(title);
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: isSelected ? color : Colors.white.withOpacity(0.1)),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.all(12),
      borderRadius: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 9.5, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
