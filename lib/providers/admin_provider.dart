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
  });

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    final ts = d['createdAt'];
    return AppUser(
      uid: doc.id,
      name: d['name'] as String? ?? 'Unknown',
      email: d['email'] as String? ?? '',
      role: d['role'] as String? ?? 'client',
      status: d['status'] as String? ?? 'active',
      rating: (d['rating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: (d['ratingCount'] as num?)?.toInt() ?? 0,
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
      phone: d['phone'] as String?,
    );
  }

  String get initials => name.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();
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
  bool _isLoading = false;
  String? _error;
  String? _jobStatusFilter;

  Map<String, dynamic> get platformStats => _platformStats;
  List<Job> get allJobs => _allJobs;
  List<AppUser> get clients => _clients;
  List<AppUser> get fundis => _fundis;
  List<Map<String, dynamic>> get categoryStats => _categoryStats;
  List<Map<String, dynamic>> get monthlyRevenue => _monthlyRevenue;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get jobStatusFilter => _jobStatusFilter;

  CollectionReference<Map<String, dynamic>> get _jobsCol => _db.collection('jobs');
  CollectionReference<Map<String, dynamic>> get _usersCol => _db.collection('users');

  // ── Dashboard Stats ────────────────────────────────────────────────────────

  Future<void> fetchPlatformStats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final jobsSnap = await _jobsCol.get();
      final clientsSnap = await _usersCol.where('role', isEqualTo: 'client').get();
      final fundisSnap = await _usersCol.where('role', isEqualTo: 'fundi').get();

      final allJobs = jobsSnap.docs.map((d) => Job.fromFirestore(d)).toList();

      final pending = allJobs.where((j) => j.status == JobStatus.pending).length;
      final active = allJobs.where((j) => j.status == JobStatus.accepted || j.status == JobStatus.inProgress).length;
      final completed = allJobs.where((j) => j.status == JobStatus.completed).length;
      final completedJobs = allJobs.where((j) => j.status == JobStatus.completed);
      final totalGMV = completedJobs.fold(0.0, (s, j) => s + j.budget);

      _platformStats = {
        'totalJobs': allJobs.length,
        'pendingJobs': pending,
        'activeJobs': active,
        'completedJobs': completed,
        'totalClients': clientsSnap.size,
        'totalFundis': fundisSnap.size,
        'totalRevenue': totalGMV * 0.10,
        'totalGMV': totalGMV,
      };

      // Category breakdown
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
      _categoryStats = catMap.values.map((c) => {
        ...c,
        'pct': totalCatJobs > 0 ? (c['jobs'] as int) / totalCatJobs : 0.0,
      }).toList()..sort((a, b) => (b['jobs'] as int).compareTo(a['jobs'] as int));

      _monthlyRevenue = _buildMonthlyRevenue(allJobs);
    } catch (e) {
      _error = 'Error loading stats: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> _buildMonthlyRevenue(List<Job> jobs) {
    final now = DateTime.now();
    final months = List.generate(6, (i) {
      final dt = DateTime(now.year, now.month - (5 - i), 1);
      return <String, dynamic>{'label': DateFormat('MMM').format(dt), 'year': dt.year, 'month': dt.month, 'revenue': 0.0};
    });
    for (final j in jobs.where((j) => j.status == JobStatus.completed)) {
      for (final m in months) {
        if (j.createdAt.year == m['year'] && j.createdAt.month == m['month']) {
          m['revenue'] = (m['revenue'] as double) + j.budget * 0.10;
        }
      }
    }
    final maxRev = months.fold(0.0, (mx, m) => (m['revenue'] as double) > mx ? m['revenue'] as double : mx);
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
      Query<Map<String, dynamic>> q = _jobsCol.orderBy('createdAt', descending: true).limit(100);
      if (statusFilter != null) q = q.where('status', isEqualTo: statusFilter);
      final snap = await q.get();
      _allJobs = snap.docs.map((d) => Job.fromFirestore(d)).toList();
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
        final parsed = JobStatus.values.firstWhere((e) => e.name == status, orElse: () => JobStatus.pending);
        _allJobs[idx] = _allJobs[idx].copyWith(status: parsed);
        notifyListeners();
      }
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
      final clientsSnap = await _usersCol.where('role', isEqualTo: 'client').orderBy('createdAt', descending: true).get();
      final fundisSnap = await _usersCol.where('role', isEqualTo: 'fundi').orderBy('createdAt', descending: true).get();
      _clients = clientsSnap.docs.map((d) => AppUser.fromDoc(d)).toList();
      _fundis = fundisSnap.docs.map((d) => AppUser.fromDoc(d)).toList();
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
      _patchUser(_clients, uid, status);
      _patchUser(_fundis, uid, status);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  void _patchUser(List<AppUser> list, String uid, String status) {
    final i = list.indexWhere((u) => u.uid == uid);
    if (i == -1) return;
    final u = list[i];
    list[i] = AppUser(uid: u.uid, name: u.name, email: u.email, role: u.role, status: status, rating: u.rating, ratingCount: u.ratingCount, createdAt: u.createdAt, phone: u.phone);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
