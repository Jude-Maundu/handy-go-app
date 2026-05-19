import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../config/flavor_config.dart';
import '../../providers/auth_provider.dart';
import '../../services/notification_service.dart';
import 'settings_screen.dart';
import 'help_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final accent = FlavorConfig.instance.primaryColor;
    final isClient = FlavorConfig.instance.isClient;
    final name = auth.userName ?? 'User';
    final email = auth.userEmail ?? '';
    final initials = name
        .trim()
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return Drawer(
      backgroundColor: AC.surface(context),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: accent,
                    child: Text(
                      initials,
                      style: const TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                              color: AC.text(context),
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                        if (email.isNotEmpty)
                          Text(
                            email,
                            style: TextStyle(
                                color: AC.textSec(context), fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isClient ? 'Client' : 'Fundi',
                            style: TextStyle(
                                color: accent,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: AC.div(context), height: 1),
            const SizedBox(height: 8),

            // Client nav items
            if (isClient) ...[
              _DrawerItem(
                icon: Icons.home_outlined,
                label: 'Home',
                onTap: () => Navigator.pop(context),
              ),
              _DrawerItem(
                icon: Icons.receipt_long_outlined,
                label: 'My Bookings',
                onTap: () => Navigator.pop(context),
              ),
              _DrawerItem(
                icon: Icons.search_outlined,
                label: 'Search Services',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/search');
                },
              ),
            ] else ...[
              // Fundi nav items
              _DrawerItem(
                icon: Icons.explore_outlined,
                label: 'Discover',
                onTap: () => Navigator.pop(context),
              ),
              _DrawerItem(
                icon: Icons.work_outline,
                label: 'My Jobs',
                onTap: () => Navigator.pop(context),
              ),
              _DrawerItem(
                icon: Icons.payment_outlined,
                label: 'Payments',
                onTap: () => Navigator.pop(context),
              ),
              _DrawerItem(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Earnings',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/fundi/earnings');
                },
              ),
            ],

            _DrawerItem(
              icon: Icons.settings_outlined,
              label: 'Settings',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SettingsScreen()),
                );
              },
            ),
            _DrawerItem(
              icon: Icons.help_outline,
              label: 'Help & Support',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HelpScreen()),
                );
              },
            ),

            const Spacer(),
            Divider(color: AC.div(context), height: 1),

            // Sign out
            _DrawerItem(
              icon: Icons.logout,
              label: 'Sign Out',
              color: Colors.red,
              onTap: () async {
                Navigator.pop(context);
                final uid =
                    context.read<AuthProvider>().currentUserId;
                if (uid != null) {
                  await NotificationService.removeToken(uid);
                }
                if (context.mounted) {
                  await context.read<AuthProvider>().logout();
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AC.text(context);
    return ListTile(
      leading: Icon(icon, color: c, size: 22),
      title: Text(
        label,
        style: TextStyle(
            color: c, fontSize: 14, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    );
  }
}
