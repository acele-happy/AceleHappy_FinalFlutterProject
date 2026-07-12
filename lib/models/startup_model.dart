import '../core/utils/firestore_utils.dart';

enum VerificationStatus { pending, verified, rejected }

extension VerificationStatusX on VerificationStatus {
  String get label => switch (this) {
        VerificationStatus.pending => 'Pending Review',
        VerificationStatus.verified => 'ALU Verified',
        VerificationStatus.rejected => 'Not Verified',
      };

  String get firestoreValue => switch (this) {
        VerificationStatus.pending => 'pending',
        VerificationStatus.verified => 'verified',
        VerificationStatus.rejected => 'rejected',
      };

  static VerificationStatus fromString(String value) => switch (value) {
        'verified' => VerificationStatus.verified,
        'rejected' => VerificationStatus.rejected,
        _ => VerificationStatus.pending,
      };
}

class Startup {
  const Startup({
    required this.id,
    required this.founderId,
    required this.name,
    required this.description,
    required this.industry,
    this.stage = 'Early Stage',
    this.logoUrl,
    this.verificationStatus = VerificationStatus.pending,
    this.aluProgram,
    this.website,
    this.teamSize = 1,
    this.createdAt,
  });

  final String id;
  final String founderId;
  final String name;
  final String description;
  final String industry;
  final String stage;
  final String? logoUrl;
  final VerificationStatus verificationStatus;
  final String? aluProgram;
  final String? website;
  final int teamSize;
  final DateTime? createdAt;

  bool get isVerified => verificationStatus == VerificationStatus.verified;

  Startup copyWith({
    String? name,
    String? description,
    String? industry,
    String? stage,
    String? logoUrl,
    VerificationStatus? verificationStatus,
    String? aluProgram,
    String? website,
    int? teamSize,
  }) {
    return Startup(
      id: id,
      founderId: founderId,
      name: name ?? this.name,
      description: description ?? this.description,
      industry: industry ?? this.industry,
      stage: stage ?? this.stage,
      logoUrl: logoUrl ?? this.logoUrl,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      aluProgram: aluProgram ?? this.aluProgram,
      website: website ?? this.website,
      teamSize: teamSize ?? this.teamSize,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'founderId': founderId,
        'name': name,
        'description': description,
        'industry': industry,
        'stage': stage,
        'logoUrl': logoUrl,
        'verificationStatus': verificationStatus.firestoreValue,
        'aluProgram': aluProgram,
        'website': website,
        'teamSize': teamSize,
        'createdAt': createdAt,
      };

  factory Startup.fromMap(String id, Map<String, dynamic> map) {
    return Startup(
      id: id,
      founderId: map['founderId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      industry: map['industry'] as String? ?? 'Other',
      stage: map['stage'] as String? ?? 'Early Stage',
      logoUrl: map['logoUrl'] as String?,
      verificationStatus: VerificationStatusX.fromString(
        map['verificationStatus'] as String? ?? 'pending',
      ),
      aluProgram: map['aluProgram'] as String?,
      website: map['website'] as String?,
      teamSize: asInt(map['teamSize']) ?? 1,
      createdAt: asDateTime(map['createdAt']),
    );
  }
}
