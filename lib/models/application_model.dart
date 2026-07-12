import '../core/utils/firestore_utils.dart';

enum ApplicationStatus { pending, reviewing, accepted, rejected }

extension ApplicationStatusX on ApplicationStatus {
  String get label => switch (this) {
        ApplicationStatus.pending => 'Pending',
        ApplicationStatus.reviewing => 'Under Review',
        ApplicationStatus.accepted => 'Accepted',
        ApplicationStatus.rejected => 'Rejected',
      };

  String get firestoreValue => switch (this) {
        ApplicationStatus.pending => 'pending',
        ApplicationStatus.reviewing => 'reviewing',
        ApplicationStatus.accepted => 'accepted',
        ApplicationStatus.rejected => 'rejected',
      };

  static ApplicationStatus fromString(String value) => switch (value) {
        'reviewing' => ApplicationStatus.reviewing,
        'accepted' => ApplicationStatus.accepted,
        'rejected' => ApplicationStatus.rejected,
        _ => ApplicationStatus.pending,
      };
}

class Application {
  const Application({
    required this.id,
    required this.opportunityId,
    required this.opportunityTitle,
    required this.studentId,
    required this.studentName,
    required this.startupId,
    required this.startupName,
    required this.coverLetter,
    this.status = ApplicationStatus.pending,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String opportunityId;
  final String opportunityTitle;
  final String studentId;
  final String studentName;
  final String startupId;
  final String startupName;
  final String coverLetter;
  final ApplicationStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Application copyWith({
    ApplicationStatus? status,
    DateTime? updatedAt,
  }) {
    return Application(
      id: id,
      opportunityId: opportunityId,
      opportunityTitle: opportunityTitle,
      studentId: studentId,
      studentName: studentName,
      startupId: startupId,
      startupName: startupName,
      coverLetter: coverLetter,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'opportunityId': opportunityId,
        'opportunityTitle': opportunityTitle,
        'studentId': studentId,
        'studentName': studentName,
        'startupId': startupId,
        'startupName': startupName,
        'coverLetter': coverLetter,
        'status': status.firestoreValue,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  factory Application.fromMap(String id, Map<String, dynamic> map) {
    return Application(
      id: id,
      opportunityId: map['opportunityId'] as String? ?? '',
      opportunityTitle: map['opportunityTitle'] as String? ?? '',
      studentId: map['studentId'] as String? ?? '',
      studentName: map['studentName'] as String? ?? '',
      startupId: map['startupId'] as String? ?? '',
      startupName: map['startupName'] as String? ?? '',
      coverLetter: map['coverLetter'] as String? ?? '',
      status: ApplicationStatusX.fromString(
        map['status'] as String? ?? 'pending',
      ),
      createdAt: asDateTime(map['createdAt']),
      updatedAt: asDateTime(map['updatedAt']),
    );
  }
}
