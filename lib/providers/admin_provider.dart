import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/job_model.dart';

class AppUser {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String status;
  final double rating;
  final int ratingCount;
  final DateTime createdAt;
  final String? phone;
  final bool verified;
  final List<String> skills;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    required this.rating,
    required this.ratingCount,
    required this.createdAt,
    this.phone,
    this.verified = false,
    this.skills = const [],
  });

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    final ts = d['createdAt'];
    return AppUser(
      uid: doc.id,
      name: d['name'] as String? ?? 'Unknown',
      email: d['email'] as String? ?? '',
      role: (d['role'] as String? ?? 'client').toLowerCase().trim(),
      status: d['status'] as String? ?? 'active',
      rating: (d['rating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: (d['ratingCount'] as num?)?.toInt() ?? 0,
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
      phone: d['phone'] as String?,
      verified: d['verified'] as bool? ?? false,
      skills: (d['skills'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  AppUser copyWith({String? status, bool? verified}) => AppUser(
        uid: uid,
        name: name,
        email: email,
        role: role,
        status: status ?? this.status,
        rating: rating,
        ratingCount: ratingCount,
        createdAt: createdAt,
        phone: phone,
        verified: verified ?? this.verified,
        skills: skills,
      );

  String get initials =>
      name.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();
  String get joinedDate => DateFormat('MMM yyyy').format(createdAt);
}

class AdminProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Map<String, dynamic> _platformStats = {};
  List<Job> _allJobs = [];
  List<AppUser> _clients = [];
  List<AppUser> _fundis = [];
  List<Map<String, dynamic>> _categoryStats = [];
  List<Map<String, dynamic>> _monthlyRevenue = [];
  List<Map<String, dynamic>> _reports = [];
  List<Job> _transactions = [];
  List<Map<String, dynamic>> _tickets = [];
  List<Map<String, dynamic>> _payouts = [];
  Map<String, dynamic> _settings = {};
  List<String> _categories = [];
  bool _isLoading = false;
  String? _error;
  String? _jobStatusFilter;

  Map<String, dynamic> get platformStats => _platformStats;
  List<Job> get allJobs => _allJobs;
  List<AppUser> get clients => _clients;
  List<AppUser> get fundis => _fundis;
  List<Map<String, dynamic>> get categoryStats => _categoryStats;
  List<Map<String, dynamic>> get monthlyRevenue => _monthlyRevenue;
  List<Map<String, dynamic>> get reports => _reports;
  List<Job> get transactions => _transactions;
  List<Job> get ratedJobs => _transactions.where((j) => j.fundiRating != null).toList();
  List<Map<String, dynamic>> get pendingReports =>
      _reports.where((r) => (r['status'] as String?) == 'pending').toList();
  List<Job> get recentJobs => _allJobs.take(8).toList();
  List<Map<String, dynamic>> get tickets => _tickets;
  List<Map<String, dynamic>> get openTickets =>
      _tickets.where((t) => (t['status'] as String?) == 'open').toList();
  List<Map<String, dynamic>> get payouts => _payouts;
  Map<String, dynamic> get settings => _settings;
  List<String> get categories => _categories;
  double get commissionRate => (_settings['commissionRate'] as num?)?.toDouble() ?? 0.10;
  double get serviceFeeRate => (_settings['serviceFee'] as num?)?.toDouble() ?? 0.05;
  double get minJobValue => (_settings['minJobValue'] as num?)?.toDouble() ?? 100.0;
  double get maxJobValue => (_settings['maxJobValue'] as num?)?.toDouble() ?? 100000.0;
  Map<String, dynamic> get featureToggles =>
      (_settings['features'] as Map<String, dynamic>?) ?? {};
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get jobStatusFilter => _jobStatusFilter;

  CollectionReference<Map<String, dynamic>> get _jobsCol => _db.collection('jobs');
  CollectionReference<Map<String, dynamic>> get _usersCol => _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _reportsCol => _db.collection('reports');
  CollectionReference<Map<String, dynamic>> get _notifCol => _db.collection('notifications');
  CollectionReference<Map<String, dynamic>> get _ticketsCol =>
      _db.collection('support_tickets');

  // ── Dashboard Stats ────────────────────────────────────────────────────────

  Future<void> fetchPlatformStats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait<QuerySnapshot<Map<String, dynamic>>>([
        _jobsCol.get(),
        _usersCol.where('role', isEqualTo: 'client').get(),
        _usersCol.where('role', isEqualTo: 'fundi').get(),
      ]);

      final jobsSnap = results[0];
      final clientsSnap = results[1];
      final fundisSnap = results[2];

      final allJobs = jobsSnap.docs.map((d) => Job.fromFirestore(d)).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _allJobs = allJobs;

      final pending = allJobs.where((j) => j.status == JobStatus.pending).length;
      final active = allJobs
          .where((j) => j.status == JobStatus.accepted || j.status == JobStatus.inProgress)
          .length;
      final completed = allJobs.where((j) => j.status == JobStatus.completed).length;
      final cancelled = allJobs.where((j) => j.status == JobStatus.cancelled).length;
      final completedJobs = allJobs.where((j) => j.status == JobStatus.completed).toList();

      // Use serviceFee if available (actual revenue), else estimate as 10% of budget
      final totalRevenue = completedJobs.fold(
        0.0,
        (s, j) => s + (j.serviceFee ?? j.budget * 0.10),
      );
      final totalGMV = completedJobs.fold(0.0, (s, j) => s + j.budget);
      final completionRate = allJobs.isNotEmpty ? completed / allJobs.length : 0.0;

      // Avg platform rating from all rated jobs
      final ratedJobs = completedJobs.where((j) => j.fundiRating != null).toList();
      final avgRating = ratedJobs.isEmpty
          ? 0.0
          : ratedJobs.fold(0.0, (s, j) => s + j.fundiRating!) / ratedJobs.length;

      // New users this week (approximate from job data — real DAU needs server-side)
      final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
      final newJobsThisWeek = allJobs.where((j) => j.createdAt.isAfter(oneWeekAgo)).length;

      // Revenue growth: compare last 30 days vs previous 30 days
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      final sixtyDaysAgo = now.subtract(const Duration(days: 60));
      final recentRevenue = completedJobs
          .where((j) => j.createdAt.isAfter(thirtyDaysAgo))
          .fold(0.0, (s, j) => s + (j.serviceFee ?? j.budget * 0.10));
      final prevRevenue = completedJobs
          .where((j) => j.createdAt.isAfter(sixtyDaysAgo) && j.createdAt.isBefore(thirtyDaysAgo))
          .fold(0.0, (s, j) => s + (j.serviceFee ?? j.budget * 0.10));
      final revenueGrowth = prevRevenue > 0 ? (recentRevenue - prevRevenue) / prevRevenue : 0.0;

      _platformStats = {
        'totalJobs': allJobs.length,
        'pendingJobs': pending,
        'activeJobs': active,
        'completedJobs': completed,
        'cancelledJobs': cancelled,
        'totalClients': clientsSnap.size,
        'totalFundis': fundisSnap.size,
        'totalRevenue': totalRevenue,
        'totalGMV': totalGMV,
        'completionRate': completionRate,
        'paidJobs': completedJobs.where((j) => j.paymentStatus == 'paid').length,
        'avgPlatformRating': avgRating,
        'totalRatings': ratedJobs.length,
        'newJobsThisWeek': newJobsThisWeek,
        'revenueGrowth': revenueGrowth,
        'recentRevenue': recentRevenue,
      };

      _buildCategoryStats(completedJobs);
      _monthlyRevenue = _buildMonthlyRevenue(allJobs);
    } catch (e) {
      _error = 'Error loading stats: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _buildCategoryStats(List<Job> completedJobs) {
    final catMap = <String, Map<String, dynamic>>{};
    for (final j in completedJobs) {
      final prev = catMap[j.category];
      catMap[j.category] = {
        'name': j.category,
        'jobs': ((prev?['jobs'] as int?) ?? 0) + 1,
        'revenue': ((prev?['revenue'] as double?) ?? 0.0) + j.budget,
      };
    }
    final totalCatJobs = catMap.values.fold(0, (s, c) => s + (c['jobs'] as int));
    _categoryStats = catMap.values
        .map((c) => {
              ...c,
              'pct': totalCatJobs > 0 ? (c['jobs'] as int) / totalCatJobs : 0.0,
            })
        .toList()
      ..sort((a, b) => (b['jobs'] as int).compareTo(a['jobs'] as int));
  }

  List<Map<String, dynamic>> _buildMonthlyRevenue(List<Job> jobs) {
    final now = DateTime.now();
    final months = List.generate(6, (i) {
      final dt = DateTime(now.year, now.month - (5 - i), 1);
      return <String, dynamic>{
        'label': DateFormat('MMM').format(dt),
        'year': dt.year,
        'month': dt.month,
        'revenue': 0.0,
        'jobs': 0,
      };
    });
    for (final j in jobs.where((j) => j.status == JobStatus.completed)) {
      for (final m in months) {
        if (j.createdAt.year == m['year'] && j.createdAt.month == m['month']) {
          m['revenue'] = (m['revenue'] as double) + (j.serviceFee ?? j.budget * 0.10);
          m['jobs'] = (m['jobs'] as int) + 1;
        }
      }
    }
    final maxRev =
        months.fold(0.0, (mx, m) => (m['revenue'] as double) > mx ? m['revenue'] as double : mx);
    for (final m in months) {
      m['pct'] = maxRev > 0 ? (m['revenue'] as double) / maxRev : 0.0;
    }
    return months;
  }

  // ── All Jobs ───────────────────────────────────────────────────────────────

  Future<void> fetchAllJobs({String? statusFilter}) async {
    _jobStatusFilter = statusFilter;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // No .orderBy() to avoid composite index requirement — sort in-memory
      Query<Map<String, dynamic>> q = _jobsCol.limit(200);
      if (statusFilter != null) q = q.where('status', isEqualTo: statusFilter);
      final snap = await q.get();
      _allJobs = snap.docs.map((d) => Job.fromFirestore(d)).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      _error = 'Error loading jobs: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> adminUpdateJobStatus(String jobId, String status) async {
    try {
      await _jobsCol.doc(jobId).update({'status': status});
      final idx = _allJobs.indexWhere((j) => j.id == jobId);
      if (idx != -1) {
        final parsed =
            JobStatus.values.firstWhere((e) => e.name == status, orElse: () => JobStatus.pending);
        _allJobs[idx] = _allJobs[idx].copyWith(status: parsed);
        notifyListeners();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteJob(String jobId) async {
    try {
      await _jobsCol.doc(jobId).delete();
      _allJobs.removeWhere((j) => j.id == jobId);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── All Users ──────────────────────────────────────────────────────────────

  Future<void> fetchAllUsers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // No .orderBy() to avoid composite index requirement — sort in-memory
      final results = await Future.wait<QuerySnapshot<Map<String, dynamic>>>([
        _usersCol.where('role', isEqualTo: 'client').get(),
        _usersCol.where('role', isEqualTo: 'fundi').get(),
      ]);
      _clients = results[0].docs.map((d) => AppUser.fromDoc(d)).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _fundis = results[1].docs.map((d) => AppUser.fromDoc(d)).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      _error = 'Error loading users: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateUserStatus(String uid, String status) async {
    try {
      await _usersCol.doc(uid).update({'status': status});
      _patchUser(_clients, uid, (u) => u.copyWith(status: status));
      _patchUser(_fundis, uid, (u) => u.copyWith(status: status));
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> toggleFundiVerification(String uid, bool verified) async {
    try {
      await _usersCol.doc(uid).update({'verified': verified});
      _patchUser(_fundis, uid, (u) => u.copyWith(verified: verified));
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteUser(String uid) async {
    try {
      await _usersCol.doc(uid).delete();
      _clients.removeWhere((u) => u.uid == uid);
      _fundis.removeWhere((u) => u.uid == uid);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<int> getUserJobCount(String uid, {bool isClient = true}) async {
    try {
      final field = isClient ? 'clientId' : 'fundiId';
      final snap = await _jobsCol.where(field, isEqualTo: uid).get();
      return snap.size;
    } catch (_) {
      return 0;
    }
  }

  void _patchUser(List<AppUser> list, String uid, AppUser Function(AppUser) patch) {
    final i = list.indexWhere((u) => u.uid == uid);
    if (i != -1) list[i] = patch(list[i]);
  }

  // ── Reports / Flags ────────────────────────────────────────────────────────

  Future<void> fetchReports() async {
    try {
      final snap = await _reportsCol.get();
      _reports = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList()
        ..sort((a, b) {
          final ta = a['createdAt'];
          final tb = b['createdAt'];
          final da = ta is Timestamp ? ta.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
          final db2 = tb is Timestamp ? tb.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
          return db2.compareTo(da);
        });
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> resolveReport(String reportId, {bool dismiss = false}) async {
    try {
      final newStatus = dismiss ? 'dismissed' : 'resolved';
      await _reportsCol.doc(reportId).update({'status': newStatus});
      final i = _reports.indexWhere((r) => r['id'] == reportId);
      if (i != -1) {
        _reports[i] = {..._reports[i], 'status': newStatus};
        notifyListeners();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Settings ──────────────────────────────────────────────────────────────

  static const _defaultCategories = [
    'Plumbing', 'Electrical', 'Painting', 'Cleaning',
    'Carpentry', 'Gardening', 'Security', 'Masonry', 'Roofing', 'Moving',
  ];

  Future<void> fetchSettings() async {
    try {
      final doc = await _db.collection('settings').doc('platform').get();
      if (doc.exists) {
        _settings = Map<String, dynamic>.from(doc.data()!);
      } else {
        _settings = {
          'commissionRate': 0.10,
          'serviceFee': 0.05,
          'minJobValue': 100.0,
          'maxJobValue': 100000.0,
          'categories': _defaultCategories,
          'features': {
            'newRegistrations': true,
            'requireRatingAfterJob': false,
            'maintenanceMode': false,
            'chatEnabled': true,
          },
        };
      }
      _categories = List<String>.from(_settings['categories'] as List? ?? _defaultCategories);
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> updateSettings(Map<String, dynamic> updates) async {
    try {
      await _db.collection('settings').doc('platform').set(updates, SetOptions(merge: true));
      _settings.addAll(updates);
      if (updates.containsKey('categories')) {
        _categories = List<String>.from(updates['categories'] as List);
      }
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> addCategory(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || _categories.contains(trimmed)) return false;
    _categories = [..._categories, trimmed];
    return updateSettings({'categories': _categories});
  }

  Future<bool> removeCategory(String name) async {
    _categories = _categories.where((c) => c != name).toList();
    return updateSettings({'categories': _categories});
  }

  Future<bool> setFeatureToggle(String key, bool value) async {
    final features = Map<String, dynamic>.from(featureToggles);
    features[key] = value;
    return updateSettings({'features': features});
  }

  // ── Support Tickets ────────────────────────────────────────────────────────

  Future<void> fetchSupportTickets() async {
    try {
      final snap = await _ticketsCol.get();
      _tickets = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList()
        ..sort((a, b) {
          final ta = a['createdAt'];
          final tb = b['createdAt'];
          final da = ta is Timestamp ? ta.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
          final db2 = tb is Timestamp ? tb.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
          return db2.compareTo(da);
        });
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> updateTicketStatus(String id, String status, {String? adminNote}) async {
    try {
      final data = <String, dynamic>{
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (adminNote != null && adminNote.isNotEmpty) data['adminNote'] = adminNote;
      await _ticketsCol.doc(id).update(data);
      final i = _tickets.indexWhere((t) => t['id'] == id);
      if (i != -1) {
        _tickets[i] = {
          ..._tickets[i],
          'status': status,
          if (adminNote != null && adminNote.isNotEmpty) 'adminNote': adminNote,
        };
        notifyListeners();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Payouts ────────────────────────────────────────────────────────────────

  Future<void> computePayouts() async {
    try {
      final snap = await _jobsCol.where('status', isEqualTo: 'completed').get();
      final fundiMap = <String, Map<String, dynamic>>{};
      for (final doc in snap.docs) {
        final j = Job.fromFirestore(doc);
        if (j.fundiId == null) continue;
        final earnings = j.fundiEarnings ?? j.budget * 0.9;
        final isPaid = j.paymentStatus == 'paid';
        final prev = fundiMap[j.fundiId!];
        fundiMap[j.fundiId!] = {
          'fundiId': j.fundiId,
          'fundiName': j.fundiName ?? 'Unknown',
          'totalEarnings': ((prev?['totalEarnings'] as double?) ?? 0.0) + earnings,
          'paidEarnings': ((prev?['paidEarnings'] as double?) ?? 0.0) + (isPaid ? earnings : 0.0),
          'pendingEarnings': ((prev?['pendingEarnings'] as double?) ?? 0.0) + (isPaid ? 0.0 : earnings),
          'jobCount': ((prev?['jobCount'] as int?) ?? 0) + 1,
          'jobIds': [...((prev?['jobIds'] as List<String>?) ?? <String>[]), j.id],
        };
      }
      _payouts = fundiMap.values.toList()
        ..sort((a, b) =>
            (b['paidEarnings'] as double).compareTo(a['paidEarnings'] as double));
      notifyListeners();
    } catch (_) {}
  }

  // ── Per-User Data ──────────────────────────────────────────────────────────

  Future<List<Job>> getUserJobs(String uid, {bool isClient = true}) async {
    try {
      final field = isClient ? 'clientId' : 'fundiId';
      final snap = await _jobsCol.where(field, isEqualTo: uid).get();
      return snap.docs.map((d) => Job.fromFirestore(d)).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (_) {
      return [];
    }
  }

  // ── Finance / Transactions ─────────────────────────────────────────────────

  Future<void> fetchAllTransactions() async {
    try {
      final snap = await _jobsCol.where('status', isEqualTo: 'completed').get();
      _transactions = snap.docs.map((d) => Job.fromFirestore(d)).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      notifyListeners();
    } catch (_) {}
  }

  // ── Notifications ──────────────────────────────────────────────────────────

  Future<bool> sendNotificationToUser(String userId, String title, String body) async {
    try {
      await _notifCol.add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': 'admin',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> broadcastNotification(String role, String title, String body) async {
    try {
      final snap = await _usersCol.where('role', isEqualTo: role).get();
      if (snap.docs.isEmpty) return false;
      final batch = _db.batch();
      for (final doc in snap.docs) {
        final ref = _notifCol.doc();
        batch.set(ref, {
          'userId': doc.id,
          'title': title,
          'body': body,
          'type': 'admin_broadcast',
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      return true;
    } catch (_) {
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
