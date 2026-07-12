import '../core/utils/firestore_utils.dart';

enum NotificationType {
  applicationReceived,
  applicationStatusChanged,
  startupVerified,
  newOpportunity,
}

extension NotificationTypeX on NotificationType {
  String get firestoreValue => switch (this) {
        NotificationType.applicationReceived => 'application_received',
        NotificationType.applicationStatusChanged => 'status_changed',
        NotificationType.startupVerified => 'startup_verified',
        NotificationType.newOpportunity => 'new_opportunity',
      };

  static NotificationType fromString(String value) => switch (value) {
        'application_received' => NotificationType.applicationReceived,
        'status_changed' => NotificationType.applicationStatusChanged,
        'startup_verified' => NotificationType.startupVerified,
        'new_opportunity' => NotificationType.newOpportunity,
        _ => NotificationType.applicationStatusChanged,
      };
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.relatedId,
    this.read = false,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final String? relatedId;
  final bool read;
  final DateTime? createdAt;

  AppNotification copyWith({bool? read}) {
    return AppNotification(
      id: id,
      userId: userId,
      title: title,
      body: body,
      type: type,
      relatedId: relatedId,
      read: read ?? this.read,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'title': title,
        'body': body,
        'type': type.firestoreValue,
        'relatedId': relatedId,
        'read': read,
        'createdAt': createdAt,
      };

  factory AppNotification.fromMap(String id, Map<String, dynamic> map) {
    return AppNotification(
      id: id,
      userId: map['userId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      type: NotificationTypeX.fromString(
        map['type'] as String? ?? 'status_changed',
      ),
      relatedId: map['relatedId'] as String?,
      read: map['read'] as bool? ?? false,
      createdAt: asDateTime(map['createdAt']),
    );
  }
}

class Bookmark {
  const Bookmark({
    required this.id,
    required this.userId,
    required this.opportunityId,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String opportunityId;
  final DateTime? createdAt;

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'opportunityId': opportunityId,
        'createdAt': createdAt,
      };

  factory Bookmark.fromMap(String id, Map<String, dynamic> map) {
    return Bookmark(
      id: id,
      userId: map['userId'] as String? ?? '',
      opportunityId: map['opportunityId'] as String? ?? '',
      createdAt: asDateTime(map['createdAt']),
    );
  }
}
