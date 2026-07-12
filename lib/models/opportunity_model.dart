import '../core/utils/firestore_utils.dart';

enum OpportunityStatus { open, closed }

extension OpportunityStatusX on OpportunityStatus {
  String get firestoreValue => switch (this) {
        OpportunityStatus.open => 'open',
        OpportunityStatus.closed => 'closed',
      };

  static OpportunityStatus fromString(String value) =>
      value == 'closed' ? OpportunityStatus.closed : OpportunityStatus.open;
}

class Opportunity {
  const Opportunity({
    required this.id,
    required this.startupId,
    required this.startupName,
    required this.title,
    required this.description,
    required this.skills,
    required this.type,
    this.location = 'Kigali Campus',
    this.isRemote = false,
    this.hoursPerWeek = 10,
    this.deadline,
    this.status = OpportunityStatus.open,
    this.applicationCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String startupId;
  final String startupName;
  final String title;
  final String description;
  final List<String> skills;
  final String type;
  final String location;
  final bool isRemote;
  final int hoursPerWeek;
  final DateTime? deadline;
  final OpportunityStatus status;
  final int applicationCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isOpen => status == OpportunityStatus.open;

  Opportunity copyWith({
    String? title,
    String? description,
    List<String>? skills,
    String? type,
    String? location,
    bool? isRemote,
    int? hoursPerWeek,
    DateTime? deadline,
    OpportunityStatus? status,
    int? applicationCount,
    DateTime? updatedAt,
  }) {
    return Opportunity(
      id: id,
      startupId: startupId,
      startupName: startupName,
      title: title ?? this.title,
      description: description ?? this.description,
      skills: skills ?? this.skills,
      type: type ?? this.type,
      location: location ?? this.location,
      isRemote: isRemote ?? this.isRemote,
      hoursPerWeek: hoursPerWeek ?? this.hoursPerWeek,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      applicationCount: applicationCount ?? this.applicationCount,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'startupId': startupId,
        'startupName': startupName,
        'title': title,
        'description': description,
        'skills': skills,
        'type': type,
        'location': location,
        'isRemote': isRemote,
        'hoursPerWeek': hoursPerWeek,
        'deadline': deadline,
        'status': status.firestoreValue,
        'applicationCount': applicationCount,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  factory Opportunity.fromMap(String id, Map<String, dynamic> map) {
    return Opportunity(
      id: id,
      startupId: map['startupId'] as String? ?? '',
      startupName: map['startupName'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      skills: List<String>.from(map['skills'] ?? []),
      type: map['type'] as String? ?? 'Internship',
      location: map['location'] as String? ?? 'Kigali Campus',
      isRemote: map['isRemote'] as bool? ?? false,
      hoursPerWeek: asInt(map['hoursPerWeek']) ?? 10,
      deadline: asDateTime(map['deadline']),
      status: OpportunityStatusX.fromString(
        map['status'] as String? ?? 'open',
      ),
      applicationCount: asInt(map['applicationCount']) ?? 0,
      createdAt: asDateTime(map['createdAt']),
      updatedAt: asDateTime(map['updatedAt']),
    );
  }
}
