import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/firestore_utils.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/opportunity_card.dart';

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    if (user == null) {
      return const Scaffold(body: LoadingView());
    }

    final saved = ref.watch(bookmarkedOpportunitiesProvider(user.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Saved Opportunities')),
      body: saved.when(
        data: (list) {
          if (list.isEmpty) {
            return const EmptyStateView(
              icon: Icons.bookmark_border,
              title: 'No saved opportunities',
              subtitle: 'Bookmark opportunities to review them later.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, index) =>
                OpportunityCard(opportunity: list[index]),
          );
        },
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: firestoreErrorMessage(e)),
      ),
    );
  }
}
