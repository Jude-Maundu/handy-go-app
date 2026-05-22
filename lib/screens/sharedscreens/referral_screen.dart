import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../config/flavor_config.dart';
import '../../providers/auth_provider.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  String? _code;
  List<Map<String, dynamic>> _referrals = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = context.read<AuthProvider>().currentUserId;
    if (uid == null) return;
    final db = FirebaseFirestore.instance;

    final doc = await db.collection('users').doc(uid).get();
    String? code = doc.data()?['referralCode'] as String?;

    // Generate and save a code if none exists
    if (code == null || code.isEmpty) {
      code = _generateCode(uid);
      await db.collection('users').doc(uid).update({'referralCode': code});
    }

    // Fetch users who signed up using this code
    final snap = await db.collection('users').where('referredBy', isEqualTo: code).get();
    final refs = snap.docs.map((d) {
      final ts = d.data()['createdAt'];
      return {
        'name': d.data()['name'] ?? 'Unknown',
        'role': d.data()['role'] ?? '',
        'joinedAt': ts is Timestamp ? ts.toDate() : null,
      };
    }).toList();

    if (mounted) {
      setState(() {
        _code = code;
        _referrals = refs;
        _loading = false;
      });
    }
  }

  String _generateCode(String uid) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random();
    final suffix = List.generate(5, (_) => chars[rng.nextInt(chars.length)]).join();
    return 'HG${uid.substring(0, 3).toUpperCase()}$suffix';
  }

  void _copyCode() {
    if (_code == null) return;
    Clipboard.setData(ClipboardData(text: _code!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Referral code copied!'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = FlavorConfig.instance.primaryColor;

    return Scaffold(
      backgroundColor: AC.bg(context),
      appBar: AppBar(
        backgroundColor: AC.bg(context),
        title: const Text('Refer & Earn'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Hero card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accent, accent.withValues(alpha: 0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.card_giftcard, color: Colors.black, size: 40),
                      const SizedBox(height: 12),
                      const Text(
                        'Invite friends to HandyGo',
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Share your code. When someone signs up using it,\nyou both get priority matching.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black87, fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      // Code box
                      GestureDetector(
                        onTap: _copyCode,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _code ?? '—',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 4,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Icon(Icons.copy, color: Colors.black54, size: 18),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Tap to copy',
                        style: TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Stats
                Row(
                  children: [
                    _StatBox(
                      label: 'Total Referrals',
                      value: '${_referrals.length}',
                      icon: Icons.people_outline,
                      accent: accent,
                    ),
                    const SizedBox(width: 12),
                    _StatBox(
                      label: 'Clients',
                      value: '${_referrals.where((r) => r['role'] == 'client').length}',
                      icon: Icons.person_outline,
                      accent: accent,
                    ),
                    const SizedBox(width: 12),
                    _StatBox(
                      label: 'Fundis',
                      value: '${_referrals.where((r) => r['role'] == 'fundi').length}',
                      icon: Icons.build_outlined,
                      accent: accent,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                if (_referrals.isNotEmpty) ...[
                  Text(
                    'People you referred',
                    style: TextStyle(
                        color: AC.text(context),
                        fontWeight: FontWeight.w700,
                        fontSize: 15),
                  ),
                  const SizedBox(height: 12),
                  ..._referrals.map((r) => _ReferralRow(data: r)),
                ] else ...[
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.group_add_outlined,
                            size: 56, color: AC.textSec(context).withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        Text('No referrals yet',
                            style: TextStyle(color: AC.textSec(context), fontSize: 15)),
                        const SizedBox(height: 6),
                        Text(
                          'Share your code to get started',
                          style: TextStyle(color: AC.textSec(context), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color accent;
  const _StatBox({required this.label, required this.value, required this.icon, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: AC.surface(context), borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            Icon(icon, color: accent, size: 22),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    color: AC.text(context),
                    fontWeight: FontWeight.bold,
                    fontSize: 20)),
            Text(label,
                style: TextStyle(color: AC.textSec(context), fontSize: 11),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ReferralRow extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ReferralRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final name = data['name'] as String;
    final role = (data['role'] as String?) ?? '';
    final joined = data['joinedAt'] as DateTime?;
    final initials = name.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: AC.surface(context), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Center(
              child: Text(initials,
                  style: const TextStyle(
                      color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        color: AC.text(context),
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                if (joined != null)
                  Text(
                    'Joined ${_fmt(joined)}',
                    style: TextStyle(color: AC.textSec(context), fontSize: 12),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20)),
            child: Text(
              role.isEmpty ? 'User' : role[0].toUpperCase() + role.substring(1),
              style: const TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}
