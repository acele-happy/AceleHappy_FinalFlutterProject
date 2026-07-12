import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/application_model.dart';
import '../models/notification_model.dart';
import '../models/opportunity_model.dart';
import '../models/startup_model.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';

// Service providers
final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final startupServiceProvider = Provider<StartupService>((ref) => StartupService());
final opportunityServiceProvider =
    Provider<OpportunityService>((ref) => OpportunityService());
final applicationServiceProvider =
    Provider<ApplicationService>((ref) => ApplicationService());
final bookmarkServiceProvider =
    Provider<BookmarkService>((ref) => BookmarkService());
final notificationServiceProvider =
    Provider<NotificationService>((ref) => NotificationService());

// Auth state
final authStateProvider = StreamProvider((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return ref.watch(authServiceProvider).watchUser(user.uid);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

// Data streams
final openOpportunitiesProvider = StreamProvider<List<Opportunity>>((ref) {
  return ref.watch(opportunityServiceProvider).watchOpenOpportunities();
});

final verifiedStartupsProvider = StreamProvider<List<Startup>>((ref) {
  return ref.watch(startupServiceProvider).watchVerifiedStartups();
});

final pendingStartupsProvider = StreamProvider<List<Startup>>((ref) {
  return ref.watch(startupServiceProvider).watchPendingStartups();
});

final founderStartupProvider = StreamProvider.family<Startup?, String>((ref, founderId) {
  return ref.watch(startupServiceProvider).watchStartupByFounder(founderId);
});

final startupOpportunitiesProvider =
    StreamProvider.family<List<Opportunity>, String>((ref, startupId) {
  return ref.watch(opportunityServiceProvider).watchStartupOpportunities(startupId);
});

final founderOpportunitiesProvider =
    StreamProvider.family<List<Opportunity>, String>((ref, founderId) {
  return ref.watch(opportunityServiceProvider).watchFounderOpportunities(founderId);
});

final studentApplicationsProvider =
    StreamProvider.family<List<Application>, String>((ref, studentId) {
  return ref.watch(applicationServiceProvider).watchStudentApplications(studentId);
});

final startupApplicationsProvider =
    StreamProvider.family<List<Application>, String>((ref, startupId) {
  return ref.watch(applicationServiceProvider).watchStartupApplications(startupId);
});

final founderApplicationsProvider =
    StreamProvider.family<List<Application>, String>((ref, founderId) {
  return ref.watch(applicationServiceProvider).watchFounderApplications(founderId);
});

final bookmarkIdsProvider = StreamProvider.family<Set<String>, String>((ref, userId) {
  return ref.watch(bookmarkServiceProvider).watchBookmarkedOpportunityIds(userId);
});

final bookmarkedOpportunitiesProvider =
    StreamProvider.family<List<Opportunity>, String>((ref, userId) {
  return ref.watch(bookmarkServiceProvider).watchBookmarkedOpportunities(userId);
});

final notificationsProvider =
    StreamProvider.family<List<AppNotification>, String>((ref, userId) {
  return ref.watch(notificationServiceProvider).watchNotifications(userId);
});

// Search & filter state
class OpportunityFilter {
  const OpportunityFilter({
    this.query = '',
    this.skill,
    this.type,
    this.remoteOnly = false,
  });

  final String query;
  final String? skill;
  final String? type;
  final bool remoteOnly;

  OpportunityFilter copyWith({
    String? query,
    String? skill,
    String? type,
    bool? remoteOnly,
    bool clearSkill = false,
    bool clearType = false,
  }) {
    return OpportunityFilter(
      query: query ?? this.query,
      skill: clearSkill ? null : (skill ?? this.skill),
      type: clearType ? null : (type ?? this.type),
      remoteOnly: remoteOnly ?? this.remoteOnly,
    );
  }
}

class OpportunityFilterNotifier extends StateNotifier<OpportunityFilter> {
  OpportunityFilterNotifier() : super(const OpportunityFilter());

  void setQuery(String query) => state = state.copyWith(query: query);
  void setSkill(String? skill) =>
      state = state.copyWith(skill: skill, clearSkill: skill == null);
  void setType(String? type) =>
      state = state.copyWith(type: type, clearType: type == null);
  void setRemoteOnly(bool value) => state = state.copyWith(remoteOnly: value);
  void reset() => state = const OpportunityFilter();
}

final opportunityFilterProvider =
    StateNotifierProvider<OpportunityFilterNotifier, OpportunityFilter>(
  (ref) => OpportunityFilterNotifier(),
);

List<Opportunity> filterOpportunities(
  List<Opportunity> opportunities,
  OpportunityFilter filter,
) {
  return opportunities.where((opp) {
    final matchesQuery = filter.query.isEmpty ||
        opp.title.toLowerCase().contains(filter.query.toLowerCase()) ||
        opp.startupName.toLowerCase().contains(filter.query.toLowerCase()) ||
        opp.description.toLowerCase().contains(filter.query.toLowerCase());

    final matchesSkill = filter.skill == null ||
        opp.skills.any(
          (s) => s.toLowerCase() == filter.skill!.toLowerCase(),
        );

    final matchesType =
        filter.type == null || opp.type.toLowerCase() == filter.type!.toLowerCase();

    final matchesRemote = !filter.remoteOnly || opp.isRemote;

    return matchesQuery && matchesSkill && matchesType && matchesRemote;
  }).toList();
}

final filteredOpportunitiesProvider = Provider<AsyncValue<List<Opportunity>>>((ref) {
  final opportunities = ref.watch(openOpportunitiesProvider);
  final filter = ref.watch(opportunityFilterProvider);

  return opportunities.whenData(
    (list) => filterOpportunities(list, filter),
  );
});

final unreadNotificationCountProvider = Provider.family<int, String>((ref, userId) {
  final notifications = ref.watch(notificationsProvider(userId));
  return notifications.maybeWhen(
    data: (list) => list.where((n) => !n.read).length,
    orElse: () => 0,
  );
});
