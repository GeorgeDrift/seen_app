import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/local/demo_profiles.dart';
import '../../controllers/profile_controller.dart';
import '../../screens/therapist_portal.dart';

/// Dev-only bottom sheet for switching demo profiles and reaching the
/// clinician portal. A real user never has this — it's reached only by
/// long-pressing the "SEEN" wordmark in [MainShell].
class DemoControlsSheet extends ConsumerWidget {
  const DemoControlsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeProfileProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Demo controls',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Not visible to real users.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ...DemoProfiles.all.map((p) {
            final isActive = p.key == active.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                tileColor: isActive ? AppColors.cardCool : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                title: Text(
                  p.label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: Text(
                  p.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                trailing: isActive
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  ref.read(activeProfileProvider.notifier).selectByKey(p.key);
                  Navigator.pop(context);
                },
              ),
            );
          }),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(
              Icons.medical_services_outlined,
              color: AppColors.primary,
            ),
            title: const Text('Open clinician portal'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const TherapistPortalScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
