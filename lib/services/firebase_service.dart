import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/firestore_utils.dart';
import '../models/application_model.dart';
import '../models/notification_model.dart';
import '../models/opportunity_model.dart';
import '../models/startup_model.dart';
import '../models/user_model.dart';

class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<AppUser?> getCurrentAppUser() async {
    final user = currentUser;
    if (user == null) return null;
    final doc = await _firestore
        .collection(AppConstants.collectionUsers)
        .doc(user.uid)
        .get();
    if (!doc.exists) return null;
    return AppUser.fromMap(doc.id, doc.data()!);
  }

  Future<AppUser> signUp({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
  }) async {
    if (!AppConstants.isAllowedAluEmail(email)) {
      throw AuthException(
        'Please use your ALU email (${AppConstants.aluEmailDomainsLabel}).',
      );
    }

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      final uid = credential.user!.uid;
      final appUser = AppUser(
        id: uid,
        email: email.trim().toLowerCase(),
        role: role,
        displayName: displayName.trim(),
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(uid)
          .set({
        ...withoutNulls(appUser.toMap()),
        'createdAt': FieldValue.serverTimestamp(),
      });

      return appUser;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_authErrorMessage(e));
    } on FirebaseException catch (e) {
      throw AuthException(
        e.message ?? 'Could not save your profile. Check Firestore setup.',
      );
    }
  }

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      final doc = await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(credential.user!.uid)
          .get();

      if (!doc.exists) {
        throw AuthException('User profile not found. Please contact support.');
      }

      return AppUser.fromMap(doc.id, doc.data()!);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_authErrorMessage(e));
    } on FirebaseException catch (e) {
      throw AuthException(
        e.message ?? 'Could not load your profile. Check Firestore setup.',
      );
    }
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
  }

  Future<void> updateUserProfile(AppUser user) async {
    final data = withoutNulls(user.toMap());
    await _firestore
        .collection(AppConstants.collectionUsers)
        .doc(user.id)
        .set(data, SetOptions(merge: true));
  }

  Stream<AppUser?> watchUser(String userId) {
    return _firestore
        .collection(AppConstants.collectionUsers)
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return AppUser.fromMap(doc.id, doc.data()!);
    });
  }
}

class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

String _authErrorMessage(FirebaseAuthException error) {
  switch (error.code) {
    case 'email-already-in-use':
      return 'This email is already registered. Try signing in instead.';
    case 'invalid-email':
      return 'That email address is not valid.';
    case 'weak-password':
      return 'Password is too weak. Use at least 6 characters.';
    case 'operation-not-allowed':
      return 'Email/password sign-in is disabled in Firebase. Enable it in Authentication settings.';
    case 'configuration-not-found':
      return 'Firebase Authentication is not set up yet. Enable Email/Password in Firebase Console.';
    case 'network-request-failed':
      return 'Network error. Check your internet connection and try again.';
    case 'wrong-password':
    case 'invalid-credential':
      return 'Incorrect email or password.';
    case 'user-not-found':
      return 'No account found for this email.';
    default:
      return error.message ?? 'Authentication failed (${error.code}).';
  }
}

class StartupService {
  StartupService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<Startup> createStartup(Startup startup) async {
    final ref = _firestore.collection(AppConstants.collectionStartups).doc();
    final data = withoutNulls(startup.toMap())
      ..['createdAt'] = FieldValue.serverTimestamp();
    await ref.set(data);
    final saved = await ref.get();
    return Startup.fromMap(ref.id, saved.data()!);
  }

  Future<void> updateStartup(Startup startup) async {
    final data = withoutNulls(startup.toMap());
    await _firestore
        .collection(AppConstants.collectionStartups)
        .doc(startup.id)
        .set(data, SetOptions(merge: true));
  }

  Future<List<Startup>> getStartupsByFounder(String founderId) async {
    final snapshot = await _firestore
        .collection(AppConstants.collectionStartups)
        .where('founderId', isEqualTo: founderId)
        .get();
    final startups = snapshot.docs
        .map((doc) => Startup.fromMap(doc.id, doc.data()))
        .toList()
      ..sort((a, b) => compareByCreatedAtDesc(a.createdAt, b.createdAt));
    return startups;
  }

  Future<Startup?> getStartupByFounder(String founderId) async {
    final startups = await getStartupsByFounder(founderId);
    if (startups.isEmpty) return null;
    return startups.firstWhere(
      (startup) => startup.isVerified,
      orElse: () => startups.first,
    );
  }

  Stream<List<Startup>> watchStartupsByFounder(String founderId) {
    return _firestore
        .collection(AppConstants.collectionStartups)
        .where('founderId', isEqualTo: founderId)
        .snapshots()
        .map((snapshot) {
      final startups = snapshot.docs
          .map((doc) => Startup.fromMap(doc.id, doc.data()))
          .toList()
        ..sort((a, b) => compareByCreatedAtDesc(a.createdAt, b.createdAt));
      return startups;
    });
  }

  Stream<Startup?> watchStartupByFounder(String founderId) {
    return watchStartupsByFounder(founderId).map((startups) {
      if (startups.isEmpty) return null;
      return startups.firstWhere(
        (startup) => startup.isVerified,
        orElse: () => startups.first,
      );
    });
  }

  Stream<List<Startup>> watchVerifiedStartups() {
    return _firestore
        .collection(AppConstants.collectionStartups)
        .where('verificationStatus', isEqualTo: 'verified')
        .snapshots()
        .map((snapshot) {
      final startups = snapshot.docs
          .map((doc) => Startup.fromMap(doc.id, doc.data()))
          .toList()
        ..sort((a, b) => compareByCreatedAtDesc(a.createdAt, b.createdAt));
      return startups;
    });
  }

  Future<Startup?> getStartup(String id) async {
    final doc =
        await _firestore.collection(AppConstants.collectionStartups).doc(id).get();
    if (!doc.exists) return null;
    return Startup.fromMap(doc.id, doc.data()!);
  }

  Stream<List<Startup>> watchPendingStartups() {
    return _firestore
        .collection(AppConstants.collectionStartups)
        .where('verificationStatus', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Startup.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> verifyStartup(String startupId, VerificationStatus status) async {
    final startupRef =
        _firestore.collection(AppConstants.collectionStartups).doc(startupId);
    final startupDoc = await startupRef.get();
    if (!startupDoc.exists) return;

    await startupRef.update({
      'verificationStatus': status.firestoreValue,
    });

    if (status == VerificationStatus.verified) {
      final founderId = startupDoc.data()!['founderId'] as String;
      await NotificationService().createNotification(
        AppNotification(
          id: '',
          userId: founderId,
          title: 'Startup Verified!',
          body:
              'Your startup "${startupDoc.data()!['name']}" has been verified by ALU.',
          type: NotificationType.startupVerified,
          relatedId: startupId,
          createdAt: DateTime.now(),
        ),
      );
    }
  }
}

class OpportunityService {
  OpportunityService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<Opportunity> createOpportunity(Opportunity opportunity) async {
    final ref = _firestore.collection(AppConstants.collectionOpportunities).doc();
    final now = FieldValue.serverTimestamp();
    final data = withoutNulls(opportunity.toMap())
      ..['createdAt'] = now
      ..['updatedAt'] = now;
    await ref.set(data);
    final saved = await ref.get();
    return Opportunity.fromMap(ref.id, saved.data()!);
  }

  Future<void> updateOpportunity(Opportunity opportunity) async {
    await _firestore
        .collection(AppConstants.collectionOpportunities)
        .doc(opportunity.id)
        .set({
      ...withoutNulls(opportunity.toMap()),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<Opportunity>> watchOpenOpportunities() {
    return _firestore
        .collection(AppConstants.collectionOpportunities)
        .where('status', isEqualTo: 'open')
        .snapshots()
        .map((snapshot) {
      final opportunities = snapshot.docs
          .map((doc) => Opportunity.fromMap(doc.id, doc.data()))
          .toList()
        ..sort((a, b) => compareByCreatedAtDesc(a.createdAt, b.createdAt));
      return opportunities;
    });
  }

  Stream<List<Opportunity>> watchStartupOpportunities(String startupId) {
    return _firestore
        .collection(AppConstants.collectionOpportunities)
        .where('startupId', isEqualTo: startupId)
        .snapshots()
        .map((snapshot) {
      final opportunities = snapshot.docs
          .map((doc) => Opportunity.fromMap(doc.id, doc.data()))
          .toList()
        ..sort((a, b) => compareByCreatedAtDesc(a.createdAt, b.createdAt));
      return opportunities;
    });
  }

  Stream<List<Opportunity>> watchFounderOpportunities(String founderId) {
    return StartupService(firestore: _firestore)
        .watchStartupsByFounder(founderId)
        .asyncExpand((startups) {
      final startupIds = startups.map((startup) => startup.id).toList();
      if (startupIds.isEmpty) {
        return Stream.value(<Opportunity>[]);
      }
      if (startupIds.length == 1) {
        return watchStartupOpportunities(startupIds.first);
      }

      final queryIds = startupIds.length > 10
          ? startupIds.sublist(0, 10)
          : startupIds;

      return _firestore
          .collection(AppConstants.collectionOpportunities)
          .where('startupId', whereIn: queryIds)
          .snapshots()
          .map((snapshot) {
        final opportunities = snapshot.docs
            .map((doc) => Opportunity.fromMap(doc.id, doc.data()))
            .toList()
          ..sort((a, b) => compareByCreatedAtDesc(a.createdAt, b.createdAt));
        return opportunities;
      });
    });
  }

  Future<Opportunity?> getOpportunity(String id) async {
    final doc = await _firestore
        .collection(AppConstants.collectionOpportunities)
        .doc(id)
        .get();
    if (!doc.exists) return null;
    return Opportunity.fromMap(doc.id, doc.data()!);
  }
}

class ApplicationService {
  ApplicationService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<bool> hasApplied(String studentId, String opportunityId) async {
    final snapshot = await _firestore
        .collection(AppConstants.collectionApplications)
        .where('studentId', isEqualTo: studentId)
        .where('opportunityId', isEqualTo: opportunityId)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Future<Application> submitApplication(Application application) async {
    final exists = await hasApplied(
      application.studentId,
      application.opportunityId,
    );
    if (exists) {
      throw ApplicationException('You have already applied to this opportunity.');
    }

    final ref = _firestore.collection(AppConstants.collectionApplications).doc();
    final now = FieldValue.serverTimestamp();
    final data = withoutNulls(application.toMap())
      ..['createdAt'] = now
      ..['updatedAt'] = now;

    await ref.set(data);

    await _firestore
        .collection(AppConstants.collectionOpportunities)
        .doc(application.opportunityId)
        .update({
      'applicationCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final startup = await StartupService().getStartup(application.startupId);
    if (startup != null) {
      await NotificationService().createNotification(
        AppNotification(
          id: '',
          userId: startup.founderId,
          title: 'New Application',
          body:
              '${application.studentName} applied for "${application.opportunityTitle}".',
          type: NotificationType.applicationReceived,
          relatedId: ref.id,
          createdAt: DateTime.now(),
        ),
      );
    }

    return Application.fromMap(ref.id, (await ref.get()).data()!);
  }

  Future<void> updateApplicationStatus(
    String applicationId,
    ApplicationStatus status,
    String studentId,
    String opportunityTitle,
  ) async {
    await _firestore
        .collection(AppConstants.collectionApplications)
        .doc(applicationId)
        .update({
      'status': status.firestoreValue,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await NotificationService().createNotification(
      AppNotification(
        id: '',
        userId: studentId,
        title: 'Application Update',
        body:
            'Your application for "$opportunityTitle" is now ${status.label.toLowerCase()}.',
        type: NotificationType.applicationStatusChanged,
        relatedId: applicationId,
        createdAt: DateTime.now(),
      ),
    );
  }

  Stream<List<Application>> watchStudentApplications(String studentId) {
    return _firestore
        .collection(AppConstants.collectionApplications)
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snapshot) {
      final applications = snapshot.docs
          .map((doc) => Application.fromMap(doc.id, doc.data()))
          .toList()
        ..sort((a, b) => compareByCreatedAtDesc(a.createdAt, b.createdAt));
      return applications;
    });
  }

  Stream<List<Application>> watchStartupApplications(String startupId) {
    return _firestore
        .collection(AppConstants.collectionApplications)
        .where('startupId', isEqualTo: startupId)
        .snapshots()
        .map((snapshot) {
      final applications = snapshot.docs
          .map((doc) => Application.fromMap(doc.id, doc.data()))
          .toList()
        ..sort((a, b) => compareByCreatedAtDesc(a.createdAt, b.createdAt));
      return applications;
    });
  }

  Stream<List<Application>> watchFounderApplications(String founderId) {
    return StartupService(firestore: _firestore)
        .watchStartupsByFounder(founderId)
        .asyncExpand((startups) {
      final startupIds = startups.map((startup) => startup.id).toList();
      if (startupIds.isEmpty) {
        return Stream.value(<Application>[]);
      }
      if (startupIds.length == 1) {
        return watchStartupApplications(startupIds.first);
      }

      final queryIds = startupIds.length > 10
          ? startupIds.sublist(0, 10)
          : startupIds;

      return _firestore
          .collection(AppConstants.collectionApplications)
          .where('startupId', whereIn: queryIds)
          .snapshots()
          .map((snapshot) {
        final applications = snapshot.docs
            .map((doc) => Application.fromMap(doc.id, doc.data()))
            .toList()
          ..sort((a, b) => compareByCreatedAtDesc(a.createdAt, b.createdAt));
        return applications;
      });
    });
  }
}

class ApplicationException implements Exception {
  ApplicationException(this.message);
  final String message;

  @override
  String toString() => message;
}

class BookmarkService {
  BookmarkService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _bookmarks(String userId) =>
      _firestore
          .collection(AppConstants.collectionUsers)
          .doc(userId)
          .collection(AppConstants.collectionBookmarks);

  Stream<Set<String>> watchBookmarkedOpportunityIds(String userId) {
    return _bookmarks(userId).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => doc.data()['opportunityId'] as String)
              .toSet(),
        );
  }

  Stream<List<Opportunity>> watchBookmarkedOpportunities(String userId) {
    return watchBookmarkedOpportunityIds(userId).asyncExpand((ids) {
      if (ids.isEmpty) {
        return Stream.value(<Opportunity>[]);
      }

      final queryIds = ids.take(10).toList();
      return _firestore
          .collection(AppConstants.collectionOpportunities)
          .where(FieldPath.documentId, whereIn: queryIds)
          .snapshots()
          .map((snapshot) {
        final opportunities = snapshot.docs
            .map((doc) => Opportunity.fromMap(doc.id, doc.data()))
            .toList()
          ..sort((a, b) => compareByCreatedAtDesc(a.createdAt, b.createdAt));
        return opportunities;
      });
    });
  }

  Future<void> toggleBookmark(String userId, String opportunityId) async {
    final snapshot = await _bookmarks(userId)
        .where('opportunityId', isEqualTo: opportunityId)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      await snapshot.docs.first.reference.delete();
    } else {
      await _bookmarks(userId).add({
        'userId': userId,
        'opportunityId': opportunityId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}

class NotificationService {
  NotificationService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> createNotification(AppNotification notification) async {
    await _firestore.collection(AppConstants.collectionNotifications).add({
      ...withoutNulls(notification.toMap()),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<AppNotification>> watchNotifications(String userId) {
    return _firestore
        .collection(AppConstants.collectionNotifications)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final notifications = snapshot.docs
          .map((doc) => AppNotification.fromMap(doc.id, doc.data()))
          .toList()
        ..sort((a, b) => compareByCreatedAtDesc(a.createdAt, b.createdAt));
      return notifications.take(50).toList();
    });
  }

  Future<void> markAsRead(String notificationId) async {
    await _firestore
        .collection(AppConstants.collectionNotifications)
        .doc(notificationId)
        .update({'read': true});
  }

  Future<void> markAllAsRead(String userId) async {
    final snapshot = await _firestore
        .collection(AppConstants.collectionNotifications)
        .where('userId', isEqualTo: userId)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      if (doc.data()['read'] == true) continue;
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }
}
