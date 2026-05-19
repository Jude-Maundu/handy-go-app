import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/build_config.dart';
import '../models/job_model.dart';

class JobProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final List<Job> _jobsList = [];
  final List<Job> _myJobsList = [];
  final List<Job> _paymentList = [];
  final List<Map<String, dynamic>> _fundis = [];
  Job? _selectedJob;
  bool _isJobsLoading = false;
  bool _isFundisLoading = false;
  String? _jobsError;
  String? _selectedCategory;
  String? _searchQuery;
  bool _hasMoreJobs = true;
  Map<String, dynamic> _userStats = {};
  String? _lastCreatedJobId;

  List<Job> get jobsList => _jobsList;
  List<Job> get myJobsList => _myJobsList;
  List<Job> get paymentList => _paymentList;
  List<Map<String, dynamic>> get fundis => _fundis;
  Job? get selectedJob => _selectedJob;
  bool get isJobsLoading => _isJobsLoading;
  bool get isFundisLoading => _isFundisLoading;
  String? get jobsError => _jobsError;
  bool get hasMoreJobs => _hasMoreJobs;
  String? get selectedCategory => _selectedCategory;
  String? get searchQuery => _searchQuery;
  Map<String, dynamic> get userStats => _userStats;
  String? get lastCreatedJobId => _lastCreatedJobId;

  // ── Real-time streams ──────────────────────────────────────────────────────

  /// Live feed of pending jobs for fundis (Uber-style request queue).
  Stream<List<Job>> streamPendingJobs() {
    return _col.where('status', isEqualTo: 'pending').snapshots().map((snap) {
      final jobs = snap.docs.map((d) => Job.fromFirestore(d)).toList();
      jobs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return jobs;
    });
  }

  /// Live stream of a single job document (client uses this to wait for match).
  Stream<Job?> streamJobById(String jobId) {
    return _col.doc(jobId).snapshots().map((doc) => doc.exists ? Job.fromFirestore(doc) : null);
  }

  /// Fundi accepts a pending job — uses a transaction to prevent double-accepts.
  Future<bool> acceptJob({
    required String jobId,
    required String fundiId,
    required String fundiName,
  }) async {
    try {
      await _db.runTransaction((tx) async {
        final ref = _col.doc(jobId);
        final doc = await tx.get(ref);
        if (!doc.exists || doc.data()!['status'] != 'pending') {
          throw Exception('Job no longer available');
        }
        tx.update(ref, {
          'status': 'accepted',
          'fundiId': fundiId,
          'fundiName': fundiName,
          'acceptedAt': FieldValue.serverTimestamp(),
        });
      });
      // Notify client
      await _writeNotif(
        userId: '', // will be filled by notification trigger or leave empty
        title: 'Fundi Found!',
        body: '$fundiName has accepted your job request.',
        type: 'job_accepted',
        jobId: jobId,
      );
      return true;
    } catch (e) {
      _jobsError = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Cancel a pending job (client-side cancel while searching).
  Future<void> cancelJob(String jobId) async {
    try {
      await _col.doc(jobId).update({'status': 'cancelled'});
    } catch (_) {}
  }

  Future<void> updatePaymentStatus(String jobId, String status,
      {String? checkoutRequestId}) async {
    final data = <String, dynamic>{'paymentStatus': status};
    if (checkoutRequestId != null) data['checkoutRequestId'] = checkoutRequestId;
    await _col.doc(jobId).update(data);
  }

  Job? getJob(String id) {
    return _jobsList.cast<Job?>().firstWhere((j) => j?.id == id, orElse: () => null) ??
        _myJobsList.cast<Job?>().firstWhere((j) => j?.id == id, orElse: () => null);
  }

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('jobs');
  CollectionReference<Map<String, dynamic>> get _notif => _db.collection('notifications');

  // ──────────────────────────────────────────────────────────────────────────
  // Jobs
  // ──────────────────────────────────────────────────────────────────────────

  Future<bool> fetchJobs({String? category, String? location, bool refresh = false}) async {
    if (refresh) _jobsList.clear();

    _isJobsLoading = true;
    _jobsError = null;
    notifyListeners();

    try {
      Query<Map<String, dynamic>> query =
          _col.where('status', isEqualTo: 'pending').orderBy('createdAt', descending: true);

      if (_selectedCategory != null) {
        query = query.where('category', isEqualTo: _selectedCategory);
      }

      final snap = await query.limit(50).get();
      _jobsList
        ..clear()
        ..addAll(snap.docs.map((d) => Job.fromFirestore(d)));
      _hasMoreJobs = snap.docs.length == 50;
      return true;
    } catch (e) {
      _jobsError = 'Error fetching jobs: $e';
      return false;
    } finally {
      _isJobsLoading = false;
      notifyListeners();
    }
  }

  Future<bool> fetchMyJobs({bool refresh = false, required String userId}) async {
    if (refresh) _myJobsList.clear();

    _isJobsLoading = true;
    _jobsError = null;
    notifyListeners();

    try {
      final field = BuildConfig.isClient ? 'clientId' : 'fundiId';
      final snap = await _col
          .where(field, isEqualTo: userId)
          .limit(50)
          .get();
      final jobs = snap.docs.map((d) => Job.fromFirestore(d)).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _myJobsList
        ..clear()
        ..addAll(jobs);
      return true;
    } catch (e) {
      _jobsError = 'Error fetching my jobs: $e';
      return false;
    } finally {
      _isJobsLoading = false;
      notifyListeners();
    }
  }

  Future<bool> getJobDetails(String jobId) async {
    _isJobsLoading = true;
    _jobsError = null;
    notifyListeners();

    try {
      final cached = getJob(jobId);
      if (cached != null) {
        _selectedJob = cached;
        return true;
      }
      final doc = await _col.doc(jobId).get();
      if (!doc.exists) {
        _jobsError = 'Job not found';
        return false;
      }
      _selectedJob = Job.fromFirestore(doc);
      return true;
    } catch (e) {
      _jobsError = 'Error fetching job: $e';
      return false;
    } finally {
      _isJobsLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchFundis({String? skill}) async {
    _isFundisLoading = true;
    notifyListeners();
    try {
      Query<Map<String, dynamic>> q = _db.collection('users').where('role', isEqualTo: 'fundi');
      final snap = await q.get();
      final all = snap.docs.map((d) {
        final data = d.data();
        return {
          'uid': d.id,
          'name': data['name'] ?? '',
          'email': data['email'] ?? '',
          'rating': (data['rating'] as num?)?.toDouble() ?? 0.0,
          'skills': (data['skills'] as List<dynamic>?)?.cast<String>() ?? <String>[],
          'primarySkill': data['primarySkill'] ?? '',
          'status': data['status'] ?? 'active',
          'jobsCompleted': (data['jobsCompleted'] as int?) ?? 0,
        };
      }).where((f) {
        if (skill == null || skill == 'All') return true;
        final skills = f['skills'] as List<String>;
        return skills.contains(skill);
      }).toList();
      // Sort: highest rated first
      all.sort((a, b) => (b['rating'] as double).compareTo(a['rating'] as double));
      _fundis
        ..clear()
        ..addAll(all);
    } catch (_) {}
    _isFundisLoading = false;
    notifyListeners();
  }

  Future<bool> createJob({
    required String title,
    required String category,
    required String description,
    required double budget,
    required String location,
    required String clientId,
    required String clientName,
    double? latitude,
    double? longitude,
    List<String> photoUrls = const [],
  }) async {
    if (!BuildConfig.isClient) {
      _jobsError = 'Only clients can create jobs';
      notifyListeners();
      return false;
    }

    _isJobsLoading = true;
    _jobsError = null;
    notifyListeners();

    try {
      final ref = _col.doc();
      _lastCreatedJobId = ref.id;
      final now = FieldValue.serverTimestamp();
      await ref.set({
        'id': ref.id,
        'title': title,
        'category': category,
        'description': description,
        'budget': budget,
        'location': location,
        'clientId': clientId,
        'clientName': clientName,
        'status': 'pending',
        'applicantsCount': 0,
        'createdAt': now,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (photoUrls.isNotEmpty) 'photoUrls': photoUrls,
      });
      return true;
    } catch (e) {
      _jobsError = 'Error creating job: $e';
      return false;
    } finally {
      _isJobsLoading = false;
      notifyListeners();
    }
  }

  Future<bool> applyForJob(String jobId, {required String fundiId, required String fundiName, String? clientId}) async {
    if (!BuildConfig.isFundi) {
      _jobsError = 'Only fundis can apply for jobs';
      notifyListeners();
      return false;
    }

    try {
      await _col.doc(jobId).update({
        'fundiId': fundiId,
        'fundiName': fundiName,
        'status': 'accepted',
      });
      final idx = _jobsList.indexWhere((j) => j.id == jobId);
      if (idx != -1) {
        final j = _jobsList[idx];
        _jobsList[idx] = j.copyWith(status: JobStatus.accepted, fundiId: fundiId, fundiName: fundiName);
        notifyListeners();
      }

      // Notify the client
      if (clientId != null) {
        _writeNotif(
          userId: clientId,
          title: 'Fundi Applied',
          body: '$fundiName has accepted your job request.',
          type: 'applied',
          jobId: jobId,
        );
      }
      return true;
    } catch (e) {
      _jobsError = 'Error applying for job: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateJobStatus(String jobId, JobStatus newStatus, {String? clientId, String? title}) async {
    try {
      await _col.doc(jobId).update({'status': newStatus.name});
      _updateLocalStatus(jobId, newStatus);

      // Notify client when job is completed
      if (newStatus == JobStatus.completed && clientId != null) {
        _writeNotif(
          userId: clientId,
          title: 'Job Completed',
          body: '${title ?? 'Your job'} has been marked as complete. Please rate your fundi.',
          type: 'completed',
          jobId: jobId,
        );
      }
      return true;
    } catch (e) {
      _jobsError = 'Error updating status: $e';
      notifyListeners();
      return false;
    }
  }

  void _updateLocalStatus(String jobId, JobStatus newStatus) {
    final idx = _myJobsList.indexWhere((j) => j.id == jobId);
    if (idx != -1) {
      _myJobsList[idx] = _myJobsList[idx].copyWith(status: newStatus);
      notifyListeners();
    }
  }

  void setCategory(String? category) {
    _selectedCategory = category;
    fetchJobs(refresh: true);
  }

  Future<bool> searchJobs(String query) async {
    _searchQuery = query;
    _isJobsLoading = true;
    _jobsError = null;
    notifyListeners();

    try {
      final lower = query.toLowerCase();
      final snap = await _col.where('status', isEqualTo: 'pending').limit(100).get();
      final all = snap.docs.map((d) => Job.fromFirestore(d));
      _jobsList
        ..clear()
        ..addAll(all.where((j) =>
            j.title.toLowerCase().contains(lower) ||
            j.category.toLowerCase().contains(lower) ||
            j.location.toLowerCase().contains(lower)));
      return true;
    } catch (e) {
      _jobsError = 'Search error: $e';
      return false;
    } finally {
      _isJobsLoading = false;
      notifyListeners();
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Payments & Earnings — completed jobs
  // ──────────────────────────────────────────────────────────────────────────

  Future<bool> fetchClientPayments(String userId) async {
    _isJobsLoading = true;
    _jobsError = null;
    notifyListeners();
    try {
      final snap = await _col
          .where('clientId', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .get();
      final jobs = snap.docs.map((d) => Job.fromFirestore(d)).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _paymentList
        ..clear()
        ..addAll(jobs);
      return true;
    } catch (e) {
      _jobsError = 'Error fetching payments: $e';
      return false;
    } finally {
      _isJobsLoading = false;
      notifyListeners();
    }
  }

  Future<bool> fetchFundiEarnings(String userId) async {
    _isJobsLoading = true;
    _jobsError = null;
    notifyListeners();
    try {
      final snap = await _col
          .where('fundiId', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .get();
      final jobs = snap.docs.map((d) => Job.fromFirestore(d)).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _paymentList
        ..clear()
        ..addAll(jobs);
      return true;
    } catch (e) {
      _jobsError = 'Error fetching earnings: $e';
      return false;
    } finally {
      _isJobsLoading = false;
      notifyListeners();
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // User stats (job count, amount, rating)
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> fetchUserStats(String userId, String role) async {
    try {
      final field = role == 'client' ? 'clientId' : 'fundiId';
      final snap = await _col
          .where(field, isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .get();
      final jobs = snap.docs.map((d) => Job.fromFirestore(d)).toList();
      final totalAmount = jobs.fold(0.0, (s, j) => s + j.budget);
      final ratedJobs = jobs.where((j) => j.fundiRating != null).toList();
      final avgRating = ratedJobs.isEmpty
          ? 0.0
          : ratedJobs.fold(0.0, (s, j) => s + j.fundiRating!) / ratedJobs.length;
      _userStats = {
        'jobCount': jobs.length,
        'totalAmount': totalAmount,
        'avgRating': avgRating,
      };
    } catch (_) {
      _userStats = {'jobCount': 0, 'totalAmount': 0.0, 'avgRating': 0.0};
    }
    notifyListeners();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Notifications
  // ──────────────────────────────────────────────────────────────────────────

  Stream<QuerySnapshot<Map<String, dynamic>>> notificationsStream(String userId) {
    return _notif
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots();
  }

  Future<void> markNotificationRead(String notifId) async {
    try {
      await _notif.doc(notifId).update({'read': true});
    } catch (_) {}
  }

  Future<void> markAllNotificationsRead(String userId) async {
    try {
      final snap = await _notif
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();
      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
    } catch (_) {}
  }

  Future<void> _writeNotif({
    required String userId,
    required String title,
    required String body,
    required String type,
    String? jobId,
  }) async {
    try {
      final data = <String, dynamic>{
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      };
      if (jobId != null) data['jobId'] = jobId;
      await _notif.add(data);
    } catch (_) {}
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Rating
  // ──────────────────────────────────────────────────────────────────────────

  Future<bool> submitRating({
    required String jobId,
    required String fundiId,
    required int rating,
    int tip = 0,
    String? review,
  }) async {
    try {
      await _col.doc(jobId).update({
        'fundiRating': rating.toDouble(),
        if (tip > 0) 'tipAmount': tip.toDouble(),
        if (review != null && review.isNotEmpty) 'clientReview': review,
      });

      // Update fundi's running average rating in /users/{fundiId}
      final userRef = _db.collection('users').doc(fundiId);
      await _db.runTransaction((tx) async {
        final snap = await tx.get(userRef);
        if (!snap.exists) return;
        final data = snap.data()!;
        final currentAvg = (data['rating'] as num?)?.toDouble() ?? 0.0;
        final ratingCount = (data['ratingCount'] as num?)?.toInt() ?? 0;
        final newCount = ratingCount + 1;
        final newAvg = ((currentAvg * ratingCount) + rating) / newCount;
        tx.update(userRef, {'rating': newAvg, 'ratingCount': newCount});
      });
      return true;
    } catch (e) {
      debugPrint('Rating error: $e');
      return false;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Misc
  // ──────────────────────────────────────────────────────────────────────────

  void clearSelectedJob() {
    _selectedJob = null;
    notifyListeners();
  }

  void clearError() {
    _jobsError = null;
    notifyListeners();
  }

  void clearJobs() {
    _jobsList.clear();
    _myJobsList.clear();
    _paymentList.clear();
    _selectedJob = null;
    _selectedCategory = null;
    _searchQuery = null;
    _hasMoreJobs = true;
    notifyListeners();
  }
}
