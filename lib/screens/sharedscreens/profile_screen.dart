import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../config/flavor_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final uid = auth.currentUserId;
      final role = auth.role ?? (FlavorConfig.instance.isClient ? 'client' : 'fundi');
      if (uid != null) context.read<JobProvider>().fetchUserStats(uid, role);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final jobs = context.watch<JobProvider>();
    final accent = FlavorConfig.instance.primaryColor;
    final name = auth.userName ?? 'User';
    final initials = name.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();
    final stats = jobs.userStats;
    final isClient = FlavorConfig.instance.isClient;

    final jobCount = stats['jobCount'] as int? ?? 0;
    final totalAmount = stats['totalAmount'] as double? ?? 0.0;
    final avgRating = stats['avgRating'] as double? ?? 0.0;

    return Scaffold(
      backgroundColor: AC.bg(context),
      appBar: AppBar(
        backgroundColor: AC.bg(context),
        title: const Text('Profile'),
        actions: [
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              width: 36, height: 36,
              decoration: BoxDecoration(color: AC.surface(context), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.settings_outlined, color: AppColors.textPrimary, size: 18),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 24),

            // Avatar
            Container(
              width: 90, height: 90,
              decoration: BoxDecoration(color: accent.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Center(
                child: Text(initials, style: TextStyle(color: accent, fontSize: 32, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 14),
            Text(name, style: TextStyle(color: AC.text(context), fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(auth.userEmail ?? '', style: TextStyle(color: AC.textSec(context), fontSize: 13)),
            if (auth.phone != null && auth.phone!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(auth.phone!, style: TextStyle(color: AC.textSec(context), fontSize: 13)),
            ],
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
              child: Text(
                auth.role?.toUpperCase() ?? 'USER',
                style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1),
              ),
            ),
            const SizedBox(height: 32),

            // Stats row — real data from Firestore
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AC.surface(context), borderRadius: BorderRadius.circular(18)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _stat(context, '$jobCount', 'Jobs'),
                  Container(width: 1, height: 36, color: AC.div(context)),
                  _stat(context, avgRating > 0 ? avgRating.toStringAsFixed(1) : '—', 'Rating'),
                  Container(width: 1, height: 36, color: AC.div(context)),
                  _stat(context, 'KES ${_formatAmount(totalAmount)}', isClient ? 'Spent' : 'Earned'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Menu tiles
            _section(context, [
              _MenuTile(icon: Icons.notifications_outlined, label: 'Notifications', onTap: () => Navigator.pushNamed(context, '/notifications')),
              _MenuTile(icon: Icons.receipt_long_outlined, label: isClient ? 'Payment History' : 'Earnings', onTap: () => Navigator.pushNamed(context, isClient ? '/payments' : '/earnings')),
              _MenuTile(icon: Icons.help_outline, label: 'Help & Support', onTap: () => Navigator.pushNamed(context, '/help')),
              _MenuTile(icon: Icons.privacy_tip_outlined, label: 'Privacy Policy', onTap: null),
            ]),
            const SizedBox(height: 16),

            _section(context, [
              _MenuTile(
                icon: Icons.logout,
                label: 'Log Out',
                iconColor: Colors.red,
                labelColor: Colors.red,
                showChevron: false,
                onTap: () async {
                  await context.read<AuthProvider>().logout();
                  if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
                },
              ),
            ]),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}k';
    return amount.toStringAsFixed(0);
  }

  Widget _stat(BuildContext ctx, String value, String label) => Column(
    children: [
      Text(value, style: TextStyle(color: AC.text(ctx), fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(color: AC.textSec(ctx), fontSize: 12)),
    ],
  );

  Widget _section(BuildContext ctx, List<Widget> tiles) => Container(
    decoration: BoxDecoration(color: AC.surface(ctx), borderRadius: BorderRadius.circular(18)),
    child: Column(children: tiles),
  );
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? labelColor;
  final bool showChevron;

  const _MenuTile({required this.icon, required this.label, required this.onTap, this.iconColor, this.labelColor, this.showChevron = true});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(color: (iconColor ?? AppColors.textSecondary).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: iconColor ?? AppColors.textSecondary, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(child: Text(label, style: TextStyle(color: labelColor ?? AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))),
              if (showChevron) const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
