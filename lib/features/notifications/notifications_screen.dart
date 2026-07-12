import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../core/theme/app_theme.dart';
import '../../core/utils/firestore_utils.dart';
import '../../models/notification_model.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common_widgets.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    if (user == null) {
      return const Scaffold(body: LoadingView());
    }

    final notifications = ref.watch(notificationsProvider(user.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () =>
                ref.read(notificationServiceProvider).markAllAsRead(user.id),
            child: const Text('Mark all read', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: notifications.when(
        data: (list) {
          if (list.isEmpty) {
            return const EmptyStateView(
              icon: Icons.notifications_none,
              title: 'No notifications',
              subtitle: 'Updates about your applications will appear here.',
            );
          }

          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, index) {
              final notification = list[index];
              return Dismissible(
                key: ValueKey(notification.id),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => ref
                    .read(notificationServiceProvider)
                    .markAsRead(notification.id),
                background: Container(
                  color: AppColors.primary,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  child: const Icon(Icons.done, color: Colors.white),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: notification.read
                        ? Colors.grey.shade200
                        : AppColors.primary.withValues(alpha: 0.15),
                    child: Icon(
                      _iconForType(notification.type),
                      color: notification.read
                          ? AppColors.textSecondary
                          : AppColors.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight:
                          notification.read ? FontWeight.normal : FontWeight.w600,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(notification.body),
                      if (notification.createdAt != null)
                        Text(
                          timeago.format(notification.createdAt!),
                          style: const TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                  onTap: () => ref
                      .read(notificationServiceProvider)
                      .markAsRead(notification.id),
                ),
              );
            },
          );
        },
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: firestoreErrorMessage(e)),
      ),
    );
  }

  IconData _iconForType(NotificationType type) {
    return switch (type) {
      NotificationType.applicationReceived => Icons.person_add,
      NotificationType.startupVerified => Icons.verified,
      NotificationType.newOpportunity => Icons.work,
      NotificationType.applicationStatusChanged => Icons.info_outline,
    };
  }
}
