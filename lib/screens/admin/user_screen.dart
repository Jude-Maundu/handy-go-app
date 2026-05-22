import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../models/job_model.dart';
import '../../providers/admin_provider.dart';

class AdminUserScreen extends StatefulWidget {
  const AdminUserScreen({super.key});

  @override
  State<AdminUserScreen> createState() => _AdminUserScreenState();
}

class _AdminUserScreenState extends State<AdminUserScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchAllUsers();
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AC.bg(context),
      appBar: AppBar(
        backgroundColor: AC.bg(context),
        title: const Text('Users'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<AdminProvider>().fetchAllUsers(),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          indicatorColor: Colors.blue,
          labelColor: Colors.blue,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [Tab(text: 'Clients'), Tab(text: 'Fundis')],
        ),
      ),
      body: Consumer<AdminProvider>(
        builder: (context, admin, _) {
          if (admin.isLoading && admin.clients.isEmpty && admin.fundis.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final clients = admin.clients
              .where((u) =>
                  u.name.toLowerCase().contains(_query) ||
                  u.email.toLowerCase().contains(_query) ||
                  (u.phone?.contains(_query) ?? false))
              .toList();
          final fundis = admin.fundis
              .where((u) =>
                  u.name.toLowerCase().contains(_query) ||
                  u.email.toLowerCase().contains(_query) ||
                  (u.phone?.contains(_query) ?? false))
              .toList();

          return Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration:
                      BoxDecoration(color: AC.input(context), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: AppColors.textSecondary, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (v) => setState(() => _query = v.toLowerCase()),
                          style: TextStyle(color: AC.text(context), fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: 'Search by name, email or phone...',
                            hintStyle: TextStyle(color: AppColors.textSecondary),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      if (_query.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                          child: const Icon(Icons.close, color: AppColors.textSecondary, size: 16),
                        ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Text('${clients.length} clients · ${fundis.length} fundis',
                        style: TextStyle(color: AC.textSec(context), fontSize: 12)),
                    const Spacer(),
                    _chip('Active',
                        admin.clients.where((u) => u.status == 'active').length +
                            admin.fundis.where((u) => u.status == 'active').length,
                        Colors.green),
                    const SizedBox(width: 6),
                    _chip('Suspended',
                        admin.clients.where((u) => u.status != 'active').length +
                            admin.fundis.where((u) => u.status != 'active').length,
                        Colors.red),
                  ],
                ),
              ),

              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => admin.fetchAllUsers(),
                  child: TabBarView(
                    controller: _tab,
                    children: [
                      _UserList(users: clients, emptyMsg: 'No clients found', isFundi: false),
                      _UserList(users: fundis, emptyMsg: 'No fundis found', isFundi: true),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _chip(String label, int count, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
        child: Text('$label: $count',
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      );
}

// ── User list ─────────────────────────────────────────────────────────────────

class _UserList extends StatelessWidget {
  final List<AppUser> users;
  final String emptyMsg;
  final bool isFundi;
  const _UserList({required this.users, required this.emptyMsg, required this.isFundi});

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return Center(child: Text(emptyMsg, style: TextStyle(color: AC.textSec(context))));
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: users.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) => _UserCard(user: users[i], isFundi: isFundi),
    );
  }
}

// ── User card ─────────────────────────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  final AppUser user;
  final bool isFundi;
  const _UserCard({required this.user, required this.isFundi});

  bool get _isActive => user.status == 'active';
  Color get _statusColor => _isActive ? Colors.green : Colors.red;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AC.surface(context), borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration:
                      BoxDecoration(color: Colors.blue.withValues(alpha: 0.12), shape: BoxShape.circle),
                  child: Center(
                    child: Text(user.initials,
                        style: const TextStyle(
                            color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                if (isFundi && user.verified)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                      child: const Icon(Icons.check, size: 10, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(user.name,
                            style: TextStyle(
                                color: AC.text(context), fontWeight: FontWeight.w700, fontSize: 14)),
                      ),
                      if (isFundi && user.verified)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(Icons.verified, size: 14, color: Colors.green),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(user.email,
                      style: TextStyle(color: AC.textSec(context), fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (user.phone != null && user.phone!.isNotEmpty) ...[
                        const Icon(Icons.phone_outlined, size: 11, color: AppColors.textSecondary),
                        const SizedBox(width: 3),
                        Text(user.phone!,
                            style: TextStyle(color: AC.textSec(context), fontSize: 11)),
                        const SizedBox(width: 8),
                      ],
                      if (user.rating > 0) ...[
                        const Icon(Icons.star, size: 11, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(user.rating.toStringAsFixed(1),
                            style: TextStyle(color: AC.textSec(context), fontSize: 11)),
                        const SizedBox(width: 8),
                      ],
                      Text('Joined ${user.joinedDate}',
                          style: TextStyle(color: AC.textSec(context), fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),

            // Status + action
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    _isActive ? 'Active' : 'Suspended',
                    style: TextStyle(color: _statusColor, fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => _toggleStatus(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (_isActive ? Colors.red : Colors.green).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _isActive ? 'Suspend' : 'Activate',
                      style: TextStyle(
                          color: _isActive ? Colors.red : Colors.green,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleStatus(BuildContext context) async {
    final newStatus = _isActive ? 'suspended' : 'active';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_isActive ? 'Suspend User' : 'Activate User'),
        content: Text(_isActive
            ? 'Suspend ${user.name}? They will not be able to use the app.'
            : 'Reactivate ${user.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _isActive ? Colors.red : Colors.green),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_isActive ? 'Suspend' : 'Activate'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    final ok = await context.read<AdminProvider>().updateUserStatus(user.uid, newStatus);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'User ${_isActive ? 'suspended' : 'activated'}' : 'Failed to update'),
          backgroundColor: ok ? (_isActive ? Colors.orange : Colors.green) : Colors.red,
        ),
      );
    }
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _UserDetailSheet(user: user, isFundi: isFundi),
    );
  }
}

// ── User detail bottom sheet ──────────────────────────────────────────────────

class _UserDetailSheet extends StatefulWidget {
  final AppUser user;
  final bool isFundi;
  const _UserDetailSheet({required this.user, required this.isFundi});

  @override
  State<_UserDetailSheet> createState() => _UserDetailSheetState();
}

class _UserDetailSheetState extends State<_UserDetailSheet> {
  int? _jobCount;
  bool _loadingCount = true;
  List<Job> _jobs = [];
  bool _loadingJobs = true;
  bool _showJobs = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final admin = context.read<AdminProvider>();
    final isClient = !widget.isFundi;
    final results = await Future.wait([
      admin.getUserJobCount(widget.user.uid, isClient: isClient),
      admin.getUserJobs(widget.user.uid, isClient: isClient),
    ]);
    if (mounted) {
      setState(() {
        _jobCount = results[0] as int;
        _jobs = results[1] as List<Job>;
        _loadingCount = false;
        _loadingJobs = false;
      });
    }
  }

  Future<void> _sendNotification(BuildContext context) async {
    // Capture context-dependent objects before any async gap
    final admin = context.read<AdminProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    String? captured;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Notify ${widget.user.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                  labelText: 'Title', border: OutlineInputBorder(), isDense: true),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bodyCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: 'Message', border: OutlineInputBorder(), isDense: true),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              // Capture text inside dialog before closing
              captured = '${titleCtrl.text.trim()}|||${bodyCtrl.text.trim()}';
              Navigator.pop(ctx);
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );

    titleCtrl.dispose();
    bodyCtrl.dispose();

    if (!mounted || captured == null) return;
    final parts = captured!.split('|||');
    final t = parts[0];
    final b = parts.length > 1 ? parts[1] : '';
    if (t.isEmpty || b.isEmpty) return;

    final ok = await admin.sendNotificationToUser(widget.user.uid, t, b);
    if (mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(ok ? 'Notification sent' : 'Failed to send'),
          backgroundColor: ok ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleVerification() async {
    final newVal = !widget.user.verified;
    final ok = await context.read<AdminProvider>().toggleFundiVerification(widget.user.uid, newVal);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok
              ? 'Fundi ${newVal ? 'verified' : 'unverified'}'
              : 'Failed to update verification'),
          backgroundColor: ok ? Colors.green : Colors.red,
        ),
      );
      if (ok) Navigator.pop(context);
    }
  }

  Future<void> _deleteUser() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
            'Permanently delete ${widget.user.name}? Their account data will be removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final ok = await context.read<AdminProvider>().deleteUser(widget.user.uid);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'User deleted' : 'Failed to delete'),
          backgroundColor: ok ? Colors.red : Colors.grey,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      maxChildSize: 0.85,
      minChildSize: 0.4,
      expand: false,
      builder: (_, ctrl) => ListView(
        controller: ctrl,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration:
                  BoxDecoration(color: AC.div(context), borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),

          // Avatar + name
          Center(
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.12), shape: BoxShape.circle),
                      child: Center(
                        child: Text(u.initials,
                            style: const TextStyle(
                                color: Colors.blue, fontSize: 24, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    if (widget.isFundi && u.verified)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration:
                              const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                          child: const Icon(Icons.check, size: 13, color: Colors.white),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(u.name,
                        style: TextStyle(
                            color: AC.text(context),
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    if (widget.isFundi && u.verified) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.verified, size: 16, color: Colors.green),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(u.role.toUpperCase(),
                    style: const TextStyle(color: Colors.blue, fontSize: 11, letterSpacing: 1)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Details
          _row(context, Icons.email_outlined, 'Email', u.email),
          if (u.phone != null && u.phone!.isNotEmpty)
            _row(context, Icons.phone_outlined, 'Phone', u.phone!),
          _row(context, Icons.calendar_today_outlined, 'Joined', u.joinedDate),
          _row(context, Icons.work_outline, 'Total Jobs',
              _loadingCount ? 'Loading...' : '${_jobCount ?? 0} jobs'),
          if (u.rating > 0)
            _row(context, Icons.star_outlined, 'Rating',
                '${u.rating.toStringAsFixed(1)} (${u.ratingCount} reviews)'),
          _row(context, Icons.circle, 'Status', u.status == 'active' ? 'Active' : 'Suspended',
              valueColor: u.status == 'active' ? Colors.green : Colors.red),
          if (widget.isFundi && u.skills.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Skills', style: TextStyle(color: AC.textSec(context), fontSize: 12)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: u.skills
                  .map((s) => Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(s,
                            style: const TextStyle(color: Colors.blue, fontSize: 12)),
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 20),

          // Job history
          GestureDetector(
            onTap: () => setState(() => _showJobs = !_showJobs),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AC.input(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.work_history_outlined,
                      size: 16, color: AC.textSec(context)),
                  const SizedBox(width: 10),
                  Text(
                    _loadingJobs
                        ? 'Loading job history...'
                        : '${_jobs.length} job${_jobs.length != 1 ? 's' : ''} — tap to ${_showJobs ? 'hide' : 'view'}',
                    style: TextStyle(
                        color: AC.text(context),
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                  ),
                  const Spacer(),
                  if (!_loadingJobs && _jobs.isNotEmpty) ...[
                    // spending/earnings summary
                    Text(
                      widget.isFundi
                          ? 'KES ${_jobs.where((j) => j.status == JobStatus.completed).fold(0.0, (s, j) => s + (j.fundiEarnings ?? j.budget * 0.9)).toStringAsFixed(0)} earned'
                          : 'KES ${_jobs.where((j) => j.status == JobStatus.completed).fold(0.0, (s, j) => s + j.budget).toStringAsFixed(0)} spent',
                      style: TextStyle(
                          color: widget.isFundi ? Colors.green : Colors.blue,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Icon(
                    _showJobs
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 18,
                    color: AC.textSec(context),
                  ),
                ],
              ),
            ),
          ),
          if (_showJobs && _jobs.isNotEmpty) ...[
            const SizedBox(height: 10),
            ..._jobs.map((j) => _JobHistoryRow(job: j)),
          ],

          const SizedBox(height: 24),

          // Actions
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.notifications_outlined, color: Colors.blue, size: 18),
              label: const Text('Send Notification', style: TextStyle(color: Colors.blue)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.blue)),
              onPressed: () => _sendNotification(context),
            ),
          ),
          const SizedBox(height: 10),
          if (widget.isFundi)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: Icon(
                    u.verified ? Icons.verified_outlined : Icons.verified,
                    color: u.verified ? Colors.orange : Colors.green,
                    size: 18),
                label: Text(
                    u.verified ? 'Remove Verification' : 'Verify Fundi',
                    style: TextStyle(color: u.verified ? Colors.orange : Colors.green)),
                style: OutlinedButton.styleFrom(
                    side: BorderSide(color: u.verified ? Colors.orange : Colors.green)),
                onPressed: _toggleVerification,
              ),
            ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
              label: const Text('Delete Account', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
              onPressed: _deleteUser,
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, IconData icon, String label, String value,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Text('$label: ', style: TextStyle(color: AC.textSec(context), fontSize: 13)),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    color: valueColor ?? AC.text(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ── Job history row ───────────────────────────────────────────────────────────

class _JobHistoryRow extends StatelessWidget {
  final Job job;
  const _JobHistoryRow({required this.job});

  Color get _statusColor {
    switch (job.status) {
      case JobStatus.pending:
        return Colors.orange;
      case JobStatus.accepted:
        return Colors.blue;
      case JobStatus.inProgress:
        return Colors.teal;
      case JobStatus.completed:
        return Colors.green;
      case JobStatus.cancelled:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AC.input(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(Icons.work_outline, color: _statusColor, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(job.title,
                    style: TextStyle(
                        color: AC.text(context),
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  '${job.category} · ${DateFormat('MMM d, y').format(job.createdAt)}',
                  style: TextStyle(color: AC.textSec(context), fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'KES ${job.budget.toStringAsFixed(0)}',
                style: TextStyle(
                    color: AC.text(context),
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
              const SizedBox(height: 3),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(job.statusText,
                    style: TextStyle(
                        color: _statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
