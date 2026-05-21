import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../config/flavor_config.dart';
import '../../providers/auth_provider.dart';
import '../../services/validators.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _nameCtrl = TextEditingController(text: auth.userName ?? '');
    _phoneCtrl = TextEditingController(text: auth.phone ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final ok = await context.read<AuthProvider>().updateProfile(
          name: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Profile updated'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to update profile. Try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = FlavorConfig.instance.primaryColor;
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AC.bg(context),
      appBar: AppBar(
        backgroundColor: AC.bg(context),
        elevation: 0,
        title: const Text('Edit Profile'),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: AC.surface(context),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.arrow_back_ios_new,
                size: 16, color: AppColors.textPrimary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(
              'Save',
              style: TextStyle(
                  color: accent, fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar preview
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      shape: BoxShape.circle),
                  child: Center(
                    child: Text(
                      _initials(_nameCtrl.text),
                      style: TextStyle(
                          color: accent,
                          fontSize: 28,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              _label('Full Name'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameCtrl,
                style: TextStyle(color: AC.text(context)),
                onChanged: (_) => setState(() {}),
                decoration: _dec('Your full name', Icons.person_outline),
                validator: Validators.name,
              ),
              const SizedBox(height: 18),

              _label('Email Address'),
              const SizedBox(height: 8),
              // Email is read-only — Firebase Auth doesn't allow easy email changes
              TextFormField(
                initialValue: auth.userEmail ?? '',
                readOnly: true,
                style: TextStyle(color: AC.textSec(context)),
                decoration: _dec('Email', Icons.mail_outline).copyWith(
                  fillColor: AC.input(context).withValues(alpha: 0.5),
                  suffixIcon: const Icon(Icons.lock_outline,
                      size: 16, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 6),
              Text('Email cannot be changed',
                  style:
                      TextStyle(color: AC.textSec(context), fontSize: 11)),
              const SizedBox(height: 18),

              _label('Phone Number (M-Pesa)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: TextStyle(color: AC.text(context)),
                decoration: _dec('07XX XXX XXX', Icons.phone_outlined),
                validator: Validators.phone,
              ),
              const SizedBox(height: 6),
              Text('Used to receive M-Pesa payments',
                  style:
                      TextStyle(color: AC.textSec(context), fontSize: 11)),
              const SizedBox(height: 36),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black))
                      : const Text('Save Changes',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    return name
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0])
        .join()
        .toUpperCase();
  }

  Widget _label(String text) => Text(text,
      style: TextStyle(
          color: AC.text(context),
          fontSize: 13,
          fontWeight: FontWeight.w600));

  InputDecoration _dec(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AC.textSec(context)),
        prefixIcon: Icon(icon, color: AC.textSec(context), size: 20),
        filled: true,
        fillColor: AC.input(context),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: FlavorConfig.instance.primaryColor, width: 1.5),
        ),
      );
}
