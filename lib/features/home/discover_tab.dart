import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/firestore_utils.dart';
import '../../models/opportunity_model.dart';
import '../../models/user_model.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/opportunity_card.dart';

class DiscoverTab extends ConsumerWidget {
  const DiscoverTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final opportunities = ref.watch(filteredOpportunitiesProvider);
    final filter = ref.watch(opportunityFilterProvider);
    final startups = ref.watch(verifiedStartupsProvider);
    final isFounder = user?.isFounder == true;

    return DefaultTabController(
      length: isFounder ? 2 : 2,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(AppConstants.appName),
              Text(
                'Hello, ${user?.displayName.split(' ').first ?? 'there'}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.normal),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () => context.push('/notifications'),
            ),
          ],
          bottom: TabBar(
            indicatorColor: AppColors.accent,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              const Tab(text: 'Opportunities'),
              Tab(text: isFounder ? 'My Posts' : 'Startups'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _OpportunitiesList(
              opportunities: opportunities,
              filter: filter,
              user: user,
            ),
            isFounder
                ? _FounderOpportunitiesTab(founderId: user!.id)
                : startups.when(
                    data: (list) => list.isEmpty
                        ? const EmptyStateView(
                            icon: Icons.business_outlined,
                            title: 'No verified startups yet',
                            subtitle:
                                'Check back as more ALU ventures get verified.',
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: list.length,
                            itemBuilder: (context, index) {
                              final startup = list[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        AppColors.primary.withValues(alpha: 0.1),
                                    child: Text(startup.name[0].toUpperCase()),
                                  ),
                                  title: Text(
                                    startup.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(startup.industry),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () =>
                                      context.push('/startup/${startup.id}'),
                                ),
                              );
                            },
                          ),
                    loading: () => const LoadingView(),
                    error: (e, _) => ErrorView(message: firestoreErrorMessage(e)),
                  ),
          ],
        ),
      ),
    );
  }
}

class _OpportunitiesList extends ConsumerWidget {
  const _OpportunitiesList({
    required this.opportunities,
    required this.filter,
    required this.user,
  });

  final AsyncValue<List<Opportunity>> opportunities;
  final OpportunityFilter filter;
  final AppUser? user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Search opportunities...',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (v) =>
                    ref.read(opportunityFilterProvider.notifier).setQuery(v),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Remote'),
                      selected: filter.remoteOnly,
                      onSelected: (v) => ref
                          .read(opportunityFilterProvider.notifier)
                          .setRemoteOnly(v),
                    ),
                    const SizedBox(width: 8),
                    ...AppConstants.opportunityTypes.map((type) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(type),
                          selected: filter.type == type,
                          onSelected: (selected) => ref
                              .read(opportunityFilterProvider.notifier)
                              .setType(selected ? type : null),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: opportunities.when(
            data: (list) {
              if (list.isEmpty) {
                return EmptyStateView(
                  icon: Icons.work_off_outlined,
                  title: 'No opportunities found',
                  subtitle: user?.isFounder == true
                      ? 'Post your first opportunity to attract students.'
                      : 'Try adjusting your filters or check back later.',
                  action: user?.isFounder == true
                      ? ElevatedButton.icon(
                          onPressed: () => context.push('/opportunity/create'),
                          icon: const Icon(Icons.add),
                          label: const Text('Post Opportunity'),
                        )
                      : null,
                );
              }

              final studentSkills = user?.isStudent == true ? user!.skills : <String>[];
              final recommended = studentSkills.isNotEmpty
                  ? list
                      .where(
                        (opp) => opp.skills.any(
                          (s) => studentSkills.any(
                            (us) => us.toLowerCase() == s.toLowerCase(),
                          ),
                        ),
                      )
                      .take(3)
                      .toList()
                  : <Opportunity>[];

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(openOpportunitiesProvider);
                },
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    if (recommended.isNotEmpty) ...[
                      const Text(
                        'Recommended for You',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...recommended.map(
                        (opp) => OpportunityCard(opportunity: opp),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'All Opportunities',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    ...list.map((opp) => OpportunityCard(opportunity: opp)),
                    const SizedBox(height: 80),
                  ],
                ),
              );
            },
            loading: () => const LoadingView(message: 'Loading opportunities...'),
            error: (e, _) => ErrorView(
              message: 'Failed to load opportunities',
              onRetry: () => ref.invalidate(openOpportunitiesProvider),
            ),
          ),
        ),
      ],
    );
  }
}

class _FounderOpportunitiesTab extends ConsumerWidget {
  const _FounderOpportunitiesTab({required this.founderId});

  final String founderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opportunities = ref.watch(founderOpportunitiesProvider(founderId));
    final startup = ref.watch(founderStartupProvider(founderId));

    return opportunities.when(
      data: (list) {
        if (list.isEmpty) {
          return EmptyStateView(
            icon: Icons.post_add,
            title: 'No posts yet',
            subtitle: startup.asData?.value == null
                ? 'Complete your startup profile first.'
                : 'Create your first opportunity listing.',
            action: ElevatedButton.icon(
              onPressed: () => context.push('/opportunity/create'),
              icon: const Icon(Icons.add),
              label: const Text('Post Opportunity'),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (context, index) => OpportunityCard(
            opportunity: list[index],
            showBookmark: false,
          ),
        );
      },
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(message: firestoreErrorMessage(e)),
    );
  }
}
