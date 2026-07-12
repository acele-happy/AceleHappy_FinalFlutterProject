import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../models/startup_model.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common_widgets.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingStartupsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Admin — Startup Verification')),
      body: pending.when(
        data: (list) {
          if (list.isEmpty) {
            return const EmptyStateView(
              icon: Icons.verified_user,
              title: 'No pending verifications',
              subtitle: 'All startup applications have been reviewed.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final startup = list[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        startup.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('${startup.industry} • ${startup.aluProgram ?? 'N/A'}'),
                      const SizedBox(height: 8),
                      Text(
                        startup.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _verify(
                                ref,
                                startup,
                                VerificationStatus.rejected,
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: const BorderSide(color: AppColors.error),
                              ),
                              child: const Text('Reject'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _verify(
                                ref,
                                startup,
                                VerificationStatus.verified,
                              ),
                              child: const Text('Verify'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: e.toString()),
      ),
    );
  }

  Future<void> _verify(
    WidgetRef ref,
    Startup startup,
    VerificationStatus status,
  ) async {
    await ref
        .read(startupServiceProvider)
        .verifyStartup(startup.id, status);
  }
}
