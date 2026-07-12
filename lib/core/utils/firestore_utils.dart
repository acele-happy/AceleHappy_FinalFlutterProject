import 'package:cloud_firestore/cloud_firestore.dart';

Map<String, dynamic> withoutNulls(Map<String, dynamic> data) {
  return Map.fromEntries(
    data.entries.where((entry) => entry.value != null),
  );
}

int? asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

DateTime? asDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is Timestamp) return value.toDate();
  if (value is Map) {
    final seconds = value['_seconds'] ?? value['seconds'];
    if (seconds is num) {
      return DateTime.fromMillisecondsSinceEpoch(seconds.toInt() * 1000);
    }
  }
  return null;
}

int compareByCreatedAtDesc(DateTime? a, DateTime? b) {
  final left = a ?? DateTime.fromMillisecondsSinceEpoch(0);
  final right = b ?? DateTime.fromMillisecondsSinceEpoch(0);
  return right.compareTo(left);
}

String firestoreErrorMessage(Object error) {
  final message = error.toString().toLowerCase();
  if (message.contains('permission-denied')) {
    return 'You do not have permission to view this data.';
  }
  if (message.contains('index')) {
    return 'Data is still syncing. Pull to refresh or try again.';
  }
  return 'Something went wrong while loading data.';
}
