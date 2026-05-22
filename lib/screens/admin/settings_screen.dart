import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/admin_provider.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final _commissionCtrl = TextEditingController();
  final _serviceFeeCtrl = TextEditingController();
  final _minJobCtrl = TextEditingController();
  final _maxJobCtrl = TextEditingController();
  bool _saving = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final admin = context.read<AdminProvider>();
      await admin.fetchSettings();
      if (mounted) {
        _commissionCtrl.text = (admin.commissionRate * 100).toStringAsFixed(1);
        _serviceFeeCtrl.text = (admin.serviceFeeRate * 100).toStringAsFixed(1);
        _minJobCtrl.text = admin.minJobValue.toStringAsFixed(0);
        _maxJobCtrl.text = admin.maxJobValue.toStringAsFixed(0);
        setState(() => _loaded = true);
      }
    });
  }

  @override
  void dispose() {
    _commissionCtrl.dispose();
    _serviceFeeCtrl.dispose();
    _minJobCtrl.dispose();
    _maxJobCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveRates() async {
    final commission = double.tryParse(_commissionCtrl.text);
    final serviceFee = double.tryParse(_serviceFeeCtrl.text);
    final minJob = double.tryParse(_minJobCtrl.text);
    final maxJob = double.tryParse(_maxJobCtrl.text);

    if (commission == null || serviceFee == null || minJob == null || maxJob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid numbers'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _saving = true);
    final admin = context.read<AdminProvider>();
    final ok = await admin.updateSettings({
      'commissionRate': commission / 100,
      'serviceFee': serviceFee / 100,
      'minJobValue': minJob,
      'maxJobValue': maxJob,
    });
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Settings saved' : 'Failed to save'),
          backgroundColor: ok ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AC.bg(context),
      appBar: AppBar(
        backgroundColor: AC.bg(context),
        title: const Text('Platform Settings'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _saveRates,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save',
                    style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : Consumer<AdminProvider>(
              builder: (context, admin, _) {
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _sectionTitle('Financial Settings', context),
                    const SizedBox(height: 12),
                    _inputField(
                      context,
                      'Platform Commission (%)',
                      _commissionCtrl,
                      hint: 'e.g. 10 for 10%',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    _inputField(
                      context,
                      'Service Fee (%)',
                      _serviceFeeCtrl,
                      hint: 'e.g. 5 for 5%',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _inputField(
                            context,
                            'Min Job (KES)',
                            _minJobCtrl,
                            hint: '100',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _inputField(
                            context,
                            'Max Job (KES)',
                            _maxJobCtrl,
                            hint: '100000',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    _sectionTitle('Feature Toggles', context),
                    const SizedBox(height: 12),
                    _FeatureToggle(
                      label: 'New Registrations',
                      subtitle: 'Allow new users to create accounts',
                      featureKey: 'newRegistrations',
                      value: (admin.featureToggles['newRegistrations'] as bool?) ?? true,
                    ),
                    _FeatureToggle(
                      label: 'Require Rating After Job',
                      subtitle: 'Prompt users to rate before closing a job',
                      featureKey: 'requireRatingAfterJob',
                      value: (admin.featureToggles['requireRatingAfterJob'] as bool?) ?? false,
                    ),
                    _FeatureToggle(
                      label: 'Chat Enabled',
                      subtitle: 'Allow in-app messaging between users',
                      featureKey: 'chatEnabled',
                      value: (admin.featureToggles['chatEnabled'] as bool?) ?? true,
                    ),
                    _FeatureToggle(
                      label: 'Maintenance Mode',
                      subtitle: 'Take the platform offline for maintenance',
                      featureKey: 'maintenanceMode',
                      value: (admin.featureToggles['maintenanceMode'] as bool?) ?? false,
                      dangerColor: Colors.red,
                    ),
                    const SizedBox(height: 28),

                    _sectionTitle('Job Categories', context),
                    const SizedBox(height: 12),
                    _CategoriesEditor(categories: admin.categories),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
    );
  }

  Widget _sectionTitle(String text, BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(text,
            style: TextStyle(
                color: AC.text(context), fontWeight: FontWeight.w700, fontSize: 15)),
      );

  Widget _inputField(
    BuildContext context,
    String label,
    TextEditingController ctrl, {
    String? hint,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: AC.textSec(context), fontSize: 12)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          style: TextStyle(color: AC.text(context)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AC.textSec(context)),
            filled: true,
            fillColor: AC.input(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}

// ── Feature toggle row ────────────────────────────────────────────────────────

class _FeatureToggle extends StatelessWidget {
  final String label;
  final String subtitle;
  final String featureKey;
  final bool value;
  final Color? dangerColor;
  const _FeatureToggle({
    required this.label,
    required this.subtitle,
    required this.featureKey,
    required this.value,
    this.dangerColor,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = value;
    final color = dangerColor;
    final highlight = color != null && isActive;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AC.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: highlight ? Border.all(color: color.withValues(alpha: 0.4)) : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: highlight ? color : AC.text(context),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: AC.textSec(context), fontSize: 12)),
              ],
            ),
          ),
          Switch.adaptive(
            value: isActive,
            activeThumbColor: color ?? Colors.blue,
            activeTrackColor: (color ?? Colors.blue).withValues(alpha: 0.4),
            onChanged: (v) => context.read<AdminProvider>().setFeatureToggle(featureKey, v),
          ),
        ],
      ),
    );
  }
}

// ── Categories editor ─────────────────────────────────────────────────────────

class _CategoriesEditor extends StatefulWidget {
  final List<String> categories;
  const _CategoriesEditor({required this.categories});

  @override
  State<_CategoriesEditor> createState() => _CategoriesEditorState();
}

class _CategoriesEditorState extends State<_CategoriesEditor> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final name = _ctrl.text.trim();
    if (name.isEmpty) return;
    final ok = await context.read<AdminProvider>().addCategory(name);
    if (mounted) {
      if (ok) _ctrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Category "$name" added' : '"$name" already exists'),
          backgroundColor: ok ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  Future<void> _remove(String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Category'),
        content: Text('Remove "$name" from the list?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await context.read<AdminProvider>().removeCategory(name);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                style: TextStyle(color: AC.text(context)),
                onSubmitted: (_) => _add(),
                decoration: InputDecoration(
                  hintText: 'New category name...',
                  hintStyle: TextStyle(color: AC.textSec(context)),
                  filled: true,
                  fillColor: AC.input(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: _add,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              ),
              child: const Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (widget.categories.isEmpty)
          Text('No categories yet',
              style: TextStyle(color: AC.textSec(context), fontSize: 13))
        else ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.categories
                .map((c) => _Chip(name: c, onRemove: () => _remove(c)))
                .toList(),
          ),
          const SizedBox(height: 10),
          Text('${widget.categories.length} categories total',
              style: TextStyle(color: AC.textSec(context), fontSize: 12)),
        ],
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String name;
  final VoidCallback onRemove;
  const _Chip({required this.name, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 6, top: 6, bottom: 6),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(name, style: const TextStyle(color: Colors.blue, fontSize: 13)),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 14, color: Colors.blue),
          ),
        ],
      ),
    );
  }
}
