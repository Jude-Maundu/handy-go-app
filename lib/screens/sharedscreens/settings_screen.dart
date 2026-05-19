import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../config/flavor_config.dart';
import '../../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _locationAccess = true;
  bool _emailUpdates = false;
  bool _soundEffects = true;

  @override
  Widget build(BuildContext context) {
    final accent = FlavorConfig.instance.primaryColor;
    final themeProvider = context.watch<ThemeProvider>();
    return Scaffold(
      backgroundColor: AC.bg(context),
      appBar: AppBar(backgroundColor: AC.bg(context), title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('Appearance'),
          const SizedBox(height: 10),
          _section([
            _ThemeTile(accent: accent, current: themeProvider.mode, onChanged: (m) => themeProvider.setMode(m)),
          ]),
          const SizedBox(height: 20),
          _sectionTitle('Preferences'),
          const SizedBox(height: 10),
          _section([
            _ToggleTile(icon: Icons.notifications_outlined, label: 'Push Notifications', value: _notifications, accent: accent, onChanged: (v) => setState(() => _notifications = v)),
            _ToggleTile(icon: Icons.location_on_outlined, label: 'Location Access', value: _locationAccess, accent: accent, onChanged: (v) => setState(() => _locationAccess = v)),
            _ToggleTile(icon: Icons.email_outlined, label: 'Email Updates', value: _emailUpdates, accent: accent, onChanged: (v) => setState(() => _emailUpdates = v)),
            _ToggleTile(icon: Icons.volume_up_outlined, label: 'Sound Effects', value: _soundEffects, accent: accent, onChanged: (v) => setState(() => _soundEffects = v)),
          ]),
          const SizedBox(height: 20),
          _sectionTitle('Account'),
          const SizedBox(height: 10),
          _section([
            _NavTile(icon: Icons.person_outline, label: 'Edit Profile', onTap: () {}),
            _NavTile(icon: Icons.lock_outline, label: 'Change Password', onTap: () {}),
            _NavTile(icon: Icons.language_outlined, label: 'Language', trailing: 'English', onTap: () {}),
          ]),
          const SizedBox(height: 20),
          _sectionTitle('App'),
          const SizedBox(height: 10),
          _section([
            _NavTile(icon: Icons.info_outline, label: 'App Version', trailing: '1.0.0', onTap: null),
            _NavTile(icon: Icons.privacy_tip_outlined, label: 'Privacy Policy', onTap: () {}),
            _NavTile(icon: Icons.description_outlined, label: 'Terms of Service', onTap: () {}),
          ]),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t, style: TextStyle(color: AC.textSec(context), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8));

  Widget _section(List<Widget> tiles) => Container(
    decoration: BoxDecoration(color: AC.surface(context), borderRadius: BorderRadius.circular(18)),
    child: Column(children: tiles),
  );
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final Color accent;
  final ValueChanged<bool> onChanged;
  const _ToggleTile({required this.icon, required this.label, required this.value, required this.accent, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: AC.input(context), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppColors.textSecondary, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: TextStyle(color: AC.text(context), fontSize: 14))),
          Switch(value: value, onChanged: onChanged, activeColor: accent, activeTrackColor: accent.withValues(alpha: 0.3)),
        ],
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final Color accent;
  final ThemeMode current;
  final ValueChanged<ThemeMode> onChanged;
  const _ThemeTile({required this.accent, required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(color: AC.input(context), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.brightness_6_outlined, color: AppColors.textSecondary, size: 18),
              ),
              const SizedBox(width: 14),
              Text('Theme', style: TextStyle(color: AC.text(context), fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _chip(context, 'Light', Icons.light_mode_outlined, ThemeMode.light),
              const SizedBox(width: 8),
              _chip(context, 'Dark', Icons.dark_mode_outlined, ThemeMode.dark),
              const SizedBox(width: 8),
              _chip(context, 'System', Icons.auto_awesome_outlined, ThemeMode.system),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String label, IconData icon, ThemeMode mode) {
    final selected = current == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? accent.withValues(alpha: 0.15) : AC.input(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? accent : AC.div(context), width: 1.5),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: selected ? accent : AC.textSec(context)),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 11, color: selected ? accent : AC.textSec(context), fontWeight: selected ? FontWeight.w700 : FontWeight.normal)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback? onTap;
  const _NavTile({required this.icon, required this.label, this.trailing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(color: AC.input(context), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: AppColors.textSecondary, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: TextStyle(color: AC.text(context), fontSize: 14))),
            if (trailing != null) Text(trailing!, style: TextStyle(color: AC.textSec(context), fontSize: 13)),
            if (onTap != null) ...[const SizedBox(width: 6), const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 18)],
          ],
        ),
      ),
    );
  }
}
