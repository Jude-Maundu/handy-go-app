import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/admin_provider.dart';

class AdminUserScreen extends StatefulWidget {
  const AdminUserScreen({super.key});

  @override
  State<AdminUserScreen> createState() => _AdminUserScreenState();
}

class _AdminUserScreenState extends State<AdminUserScreen> with SingleTickerProviderStateMixin {
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

          final clients = admin.clients.where((u) =>
              u.name.toLowerCase().contains(_query) || u.email.toLowerCase().contains(_query)).toList();
          final fundis = admin.fundis.where((u) =>
              u.name.toLowerCase().contains(_query) || u.email.toLowerCase().contains(_query)).toList();

          return Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(color: AC.input(context), borderRadius: BorderRadius.circular(12)),
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
                            hintText: 'Search by name or email...',
                            hintStyle: TextStyle(color: AppColors.textSecondary),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      if (_query.isNotEmpty)
                        GestureDetector(
                          onTap: () { _searchCtrl.clear(); setState(() => _query = ''); },
                          child: const Icon(Icons.close, color: AppColors.textSecondary, size: 16),
                        ),
                    ],
                  ),
                ),
              ),

              // Tab counts
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Text('${clients.length} clients · ${fundis.length} fundis',
                        style: TextStyle(color: AC.textSec(context), fontSize: 12)),
                  ],
                ),
              ),

              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => admin.fetchAllUsers(),
                  child: TabBarView(
                    controller: _tab,
                    children: [
                      _UserList(users: clients, emptyMsg: 'No clients found'),
                      _UserList(users: fundis, emptyMsg: 'No fundis found'),
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
}

class _UserList extends StatelessWidget {
  final List<AppUser> users;
  final String emptyMsg;
  const _UserList({required this.users, required this.emptyMsg});

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return Center(child: Text(emptyMsg, style: TextStyle(color: AC.textSec(context))));
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: users.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) => _UserCard(user: users[i]),
    );
  }
}

class _UserCard extends StatelessWidget {
  final AppUser user;
  const _UserCard({required this.user});

  bool get _isActive => user.status == 'active';
  Color get _statusColor => _isActive ? Colors.green : Colors.red;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AC.surface(context), borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Center(
              child: Text(user.initials, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name, style: TextStyle(color: AC.text(context), fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 2),
                Text(user.email, style: TextStyle(color: AC.textSec(context), fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (user.rating > 0) ...[
                      const Icon(Icons.star, size: 12, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(user.rating.toStringAsFixed(1), style: TextStyle(color: AC.textSec(context), fontSize: 11)),
                      const SizedBox(width: 8),
                    ],
                    Text('Joined ${user.joinedDate}', style: TextStyle(color: AC.textSec(context), fontSize: 11)),
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
                decoration: BoxDecoration(color: _statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                child: Text(
                  _isActive ? 'Active' : 'Suspended',
                  style: TextStyle(color: _statusColor, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 8),
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
                    style: TextStyle(color: _isActive ? Colors.red : Colors.green, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
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
    if (confirm != true) return;
    if (!context.mounted) return;
    final ok = await context.read<AdminProvider>().updateUserStatus(user.uid, newStatus);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'User ${newStatus}d' : 'Failed to update'), backgroundColor: ok ? Colors.green : Colors.red),
      );
    }
  }
}
