import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../core/theme/app_theme.dart';
import '../../core/utils/firestore_utils.dart';
import '../../models/application_model.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common_widgets.dart';

class ApplicationsScreen extends ConsumerWidget {
  const ApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;

    if (user == null) {
      return const Scaffold(body: LoadingView());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Applications')),
      body: user.isStudent
          ? _StudentApplicationsList(studentId: user.id)
          : _FounderApplicationsList(founderId: user.id),
    );
  }
}

class _StudentApplicationsList extends ConsumerWidget {
  const _StudentApplicationsList({required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applications = ref.watch(studentApplicationsProvider(studentId));

    return applications.when(
      data: (list) {
        if (list.isEmpty) {
          return const EmptyStateView(
            icon: Icons.assignment_outlined,
            title: 'No applications yet',
            subtitle: 'Browse opportunities and apply to get started.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final app = list[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(
                  app.opportunityTitle,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(app.startupName),
                    const SizedBox(height: 4),
                    if (app.createdAt != null)
                      Text(
                        timeago.format(app.createdAt!),
                        style: const TextStyle(fontSize: 12),
                      ),
                  ],
                ),
                trailing: ApplicationStatusChip(status: app.status),
                onTap: () => context.push('/application/${app.id}', extra: app),
              ),
            );
          },
        );
      },
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(message: firestoreErrorMessage(e)),
    );
  }
}

class _FounderApplicationsList extends ConsumerWidget {
  const _FounderApplicationsList({required this.founderId});

  final String founderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applications = ref.watch(founderApplicationsProvider(founderId));
    final startup = ref.watch(founderStartupProvider(founderId));

    return applications.when(
      data: (list) {
        if (list.isEmpty) {
          return EmptyStateView(
            icon: Icons.inbox_outlined,
            title: 'No applications yet',
            subtitle: startup.asData?.value == null
                ? 'Set up your startup to receive applications.'
                : 'Applications will appear here in real time.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final app = list[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(app.studentName[0].toUpperCase()),
                ),
                title: Text(
                  app.studentName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(app.opportunityTitle),
                trailing: ApplicationStatusChip(status: app.status),
                onTap: () =>
                    context.push('/application/${app.id}', extra: app),
              ),
            );
          },
        );
      },
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(message: firestoreErrorMessage(e)),
    );
  }
}

class ApplicationDetailScreen extends ConsumerWidget {
  const ApplicationDetailScreen({super.key, required this.applicationId});

  final String applicationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final extra = GoRouterState.of(context).extra;
    if (extra is! Application) {
      return const Scaffold(
        body: ErrorView(message: 'Application not found'),
      );
    }

    final app = extra;
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Application Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    app.opportunityTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                ApplicationStatusChip(status: app.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              app.startupName,
              style: const TextStyle(
                color: AppColors.primaryLight,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (user?.isFounder == true) ...[
              const SizedBox(height: 16),
              Text(
                'Applicant: ${app.studentName}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(height: 24),
            const Text(
              'Cover Letter',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              app.coverLetter,
              style: const TextStyle(height: 1.5, color: AppColors.textSecondary),
            ),
            if (user?.isFounder == true) ...[
              const SizedBox(height: 32),
              const Text(
                'Update Status',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ApplicationStatus.values.map((status) {
                  final selected = app.status == status;
                  return ChoiceChip(
                    label: Text(status.label),
                    selected: selected,
                    onSelected: selected
                        ? null
                        : (_) async {
                            await ref
                                .read(applicationServiceProvider)
                                .updateApplicationStatus(
                                  app.id,
                                  status,
                                  app.studentId,
                                  app.opportunityTitle,
                                );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Status updated to ${status.label}',
                                  ),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                              context.pop();
                            }
                          },
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
