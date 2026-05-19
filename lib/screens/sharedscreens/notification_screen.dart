import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../config/flavor_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = FlavorConfig.instance.primaryColor;
    final uid = context.read<AuthProvider>().currentUserId;
    final jobs = context.read<JobProvider>();

    if (uid == null) {
      return Scaffold(
        backgroundColor: AC.bg(context),
        appBar: AppBar(backgroundColor: AC.bg(context), title: const Text('Notifications')),
        body: const Center(child: Text('Not logged in', style: TextStyle(color: AppColors.textSecondary))),
      );
    }

    return Scaffold(
      backgroundColor: AC.bg(context),
      appBar: AppBar(
        backgroundColor: AC.bg(context),
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => jobs.markAllNotificationsRead(uid),
            child: Text('Mark all read', style: TextStyle(color: accent, fontSize: 13)),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: jobs.notificationsStream(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}', style: const TextStyle(color: AppColors.textSecondary)));
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none_outlined, size: 64, color: AppColors.textSecondary),
                  SizedBox(height: 12),
                  Text('No notifications yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: docs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final doc = docs[i];
              final data = doc.data();
              final unread = !(data['read'] as bool? ?? false);
              final type = data['type'] as String? ?? '';
              final title = data['title'] as String? ?? '';
              final body = data['body'] as String? ?? '';
              final ts = data['createdAt'];
              final time = ts is Timestamp ? _timeAgo(ts.toDate()) : '';

              return GestureDetector(
                onTap: () => jobs.markNotificationRead(doc.id),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: unread ? AC.surface(context) : AC.card(context),
                    borderRadius: BorderRadius.circular(16),
                    border: unread ? Border.all(color: accent.withValues(alpha: 0.2)) : null,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: _iconColor(type).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_iconFor(type), color: _iconColor(type), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: TextStyle(color: AC.text(context), fontWeight: FontWeight.w600, fontSize: 14),
                                  ),
                                ),
                                Text(time, style: TextStyle(color: AC.textSec(context), fontSize: 11)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(body, style: TextStyle(color: AC.textSec(context), fontSize: 13)),
                          ],
                        ),
                      ),
                      if (unread) ...[
                        const SizedBox(width: 8),
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'applied': return Icons.check_circle_outline;
      case 'completed': return Icons.star_outline;
      case 'paid': return Icons.account_balance_wallet_outlined;
      case 'job_created': return Icons.work_outline;
      default: return Icons.notifications_outlined;
    }
  }

  Color _iconColor(String type) {
    switch (type) {
      case 'applied': return Colors.blue;
      case 'completed': return Colors.amber;
      case 'paid': return Colors.purple;
      case 'job_created': return Colors.green;
      default: return Colors.grey;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays} days ago';
  }
}
