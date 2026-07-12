import '../core/utils/firestore_utils.dart';

enum UserRole { student, startupFounder, admin }

extension UserRoleX on UserRole {
  String get label => switch (this) {
        UserRole.student => 'Student',
        UserRole.startupFounder => 'Startup Founder',
        UserRole.admin => 'Admin',
      };

  String get firestoreValue => switch (this) {
        UserRole.student => 'student',
        UserRole.startupFounder => 'startup_founder',
        UserRole.admin => 'admin',
      };

  static UserRole fromString(String value) => switch (value) {
        'student' => UserRole.student,
        'startup_founder' => UserRole.startupFounder,
        'admin' => UserRole.admin,
        _ => UserRole.student,
      };
}

class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.role,
    required this.displayName,
    this.photoUrl,
    this.bio,
    this.major,
    this.graduationYear,
    this.skills = const [],
    this.onboardingComplete = false,
    this.createdAt,
  });

  final String id;
  final String email;
  final UserRole role;
  final String displayName;
  final String? photoUrl;
  final String? bio;
  final String? major;
  final int? graduationYear;
  final List<String> skills;
  final bool onboardingComplete;
  final DateTime? createdAt;

  bool get isStudent => role == UserRole.student;
  bool get isFounder => role == UserRole.startupFounder;
  bool get isAdmin => role == UserRole.admin;

  AppUser copyWith({
    String? displayName,
    String? photoUrl,
    String? bio,
    String? major,
    int? graduationYear,
    List<String>? skills,
    bool? onboardingComplete,
  }) {
    return AppUser(
      id: id,
      email: email,
      role: role,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      major: major ?? this.major,
      graduationYear: graduationYear ?? this.graduationYear,
      skills: skills ?? this.skills,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'email': email,
        'role': role.firestoreValue,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'bio': bio,
        'major': major,
        'graduationYear': graduationYear,
        'skills': skills,
        'onboardingComplete': onboardingComplete,
        'createdAt': createdAt,
      };

  factory AppUser.fromMap(String id, Map<String, dynamic> map) {
    return AppUser(
      id: id,
      email: map['email'] as String? ?? '',
      role: UserRoleX.fromString(map['role'] as String? ?? 'student'),
      displayName: map['displayName'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      bio: map['bio'] as String?,
      major: map['major'] as String?,
      graduationYear: asInt(map['graduationYear']),
      skills: List<String>.from(map['skills'] ?? []),
      onboardingComplete: map['onboardingComplete'] as bool? ?? false,
      createdAt: asDateTime(map['createdAt']),
    );
  }
}
