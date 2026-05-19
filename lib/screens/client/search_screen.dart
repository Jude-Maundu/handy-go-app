import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../config/flavor_config.dart';
import '../../providers/job_provider.dart';
import 'request_fundi_screen.dart';

class ClientSearchScreen extends StatefulWidget {
  const ClientSearchScreen({super.key});

  @override
  State<ClientSearchScreen> createState() => _ClientSearchScreenState();
}

class _ClientSearchScreenState extends State<ClientSearchScreen> {
  final _searchController = TextEditingController();
  String _selectedSkill = 'All';
  String _query = '';

  static const _skills = [
    'All', 'Plumbing', 'Electrical', 'Painting',
    'Cleaning', 'Carpentry', 'Gardening', 'Roofing', 'Masonry',
  ];

  static const _skillIcons = {
    'Plumbing': Icons.plumbing,
    'Electrical': Icons.electrical_services,
    'Painting': Icons.format_paint,
    'Cleaning': Icons.cleaning_services,
    'Carpentry': Icons.carpenter,
    'Gardening': Icons.grass,
    'Roofing': Icons.roofing,
    'Masonry': Icons.construction,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JobProvider>().fetchFundis();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSkillSelected(String skill) {
    setState(() => _selectedSkill = skill);
    context.read<JobProvider>().fetchFundis(skill: skill == 'All' ? null : skill);
  }

  @override
  Widget build(BuildContext context) {
    final accent = FlavorConfig.instance.primaryColor;
    return Scaffold(
      backgroundColor: AC.bg(context),
      appBar: AppBar(
        backgroundColor: AC.bg(context),
        title: const Text('Find a Fundi'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(color: AC.input(context), borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _query = v.toLowerCase()),
                      style: TextStyle(color: AC.text(context), fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Search by name...',
                        hintStyle: TextStyle(color: AppColors.textSecondary),
                        border: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  if (_query.isNotEmpty)
                    GestureDetector(
                      onTap: () { _searchController.clear(); setState(() => _query = ''); },
                      child: const Icon(Icons.close, color: AppColors.textSecondary, size: 18),
                    ),
                ],
              ),
            ),
          ),

          // Skill filter chips
          SizedBox(
            height: 36,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _skills.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final skill = _skills[i];
                final active = _selectedSkill == skill;
                return GestureDetector(
                  onTap: () => _onSkillSelected(skill),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? accent : AC.surface(context),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      skill,
                      style: TextStyle(
                        color: active ? Colors.black : AC.textSec(context),
                        fontSize: 13,
                        fontWeight: active ? FontWeight.w700 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Results
          Expanded(
            child: Consumer<JobProvider>(
              builder: (context, jobs, _) {
                if (jobs.isFundisLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final fundis = jobs.fundis.where((f) {
                  if (_query.isEmpty) return true;
                  return (f['name'] as String).toLowerCase().contains(_query);
                }).toList();

                if (fundis.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_search, size: 64, color: AC.textSec(context)),
                        const SizedBox(height: 12),
                        Text(
                          _query.isNotEmpty
                              ? 'No fundis match "$_query"'
                              : _selectedSkill == 'All'
                                  ? 'No fundis registered yet'
                                  : 'No $_selectedSkill fundis available',
                          style: TextStyle(color: AC.textSec(context), fontSize: 15),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try a different skill or search term',
                          style: TextStyle(color: AC.textSec(context), fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => jobs.fetchFundis(skill: _selectedSkill == 'All' ? null : _selectedSkill),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: fundis.length,
                    itemBuilder: (context, i) => _FundiCard(
                      fundi: fundis[i],
                      accent: accent,
                      skillIcons: _skillIcons,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FundiCard extends StatelessWidget {
  final Map<String, dynamic> fundi;
  final Color accent;
  final Map<String, IconData> skillIcons;
  const _FundiCard({required this.fundi, required this.accent, required this.skillIcons});

  @override
  Widget build(BuildContext context) {
    final name = fundi['name'] as String;
    final rating = fundi['rating'] as double;
    final skills = fundi['skills'] as List<String>;
    final primarySkill = fundi['primarySkill'] as String;
    final jobsCompleted = fundi['jobsCompleted'] as int;
    final status = fundi['status'] as String;
    final initials = name.trim().split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase();
    final isActive = status == 'active';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AC.surface(context), borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(color: accent.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: Center(
                  child: Text(initials, style: TextStyle(color: accent, fontWeight: FontWeight.bold, fontSize: 18)),
                ),
              ),
              const SizedBox(width: 14),

              // Name + status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(name, style: TextStyle(color: AC.text(context), fontWeight: FontWeight.w700, fontSize: 15)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: (isActive ? Colors.green : Colors.grey).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isActive ? 'Available' : 'Busy',
                            style: TextStyle(color: isActive ? Colors.green : Colors.grey, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(primarySkill.isNotEmpty ? primarySkill : (skills.isNotEmpty ? skills.first : 'General'), style: TextStyle(color: AC.textSec(context), fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Stats row
          Row(
            children: [
              _stat(Icons.star_rounded, rating > 0 ? rating.toStringAsFixed(1) : 'New', Colors.amber, context),
              const SizedBox(width: 16),
              _stat(Icons.check_circle_outline, '$jobsCompleted jobs', Colors.green, context),
            ],
          ),

          // Skills chips
          if (skills.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: skills.map((s) {
                final icon = skillIcons[s] ?? Icons.handyman_outlined;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 12, color: accent),
                      const SizedBox(width: 4),
                      Text(s, style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 12),

          // Hire button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.work_outline, size: 16),
              label: const Text('Post a Job for This Category'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RequestFundiScreen()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String label, Color color, BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(color: AC.textSec(context), fontSize: 12)),
    ],
  );
}
