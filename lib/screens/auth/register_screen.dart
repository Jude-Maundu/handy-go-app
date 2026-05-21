import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../config/flavor_config.dart';
import '../../providers/auth_provider.dart';
import 'auth_widgets.dart';
import '../../services/validators.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  final Set<String> _selectedSkills = {};

  static const _skillOptions = [
    {'name': 'Plumbing', 'icon': Icons.plumbing},
    {'name': 'Electrical', 'icon': Icons.electrical_services},
    {'name': 'Painting', 'icon': Icons.format_paint},
    {'name': 'Cleaning', 'icon': Icons.cleaning_services},
    {'name': 'Carpentry', 'icon': Icons.carpenter},
    {'name': 'Gardening', 'icon': Icons.grass},
    {'name': 'Roofing', 'icon': Icons.roofing},
    {'name': 'Masonry', 'icon': Icons.construction},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _isFundi => FlavorConfig.instance.isFundi;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isFundi && _selectedSkills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select at least one skill'),
            backgroundColor: Colors.orange),
      );
      return;
    }
    final auth = context.read<AuthProvider>();
    final role = _isFundi ? 'fundi' : 'client';
    final skills = _selectedSkills.toList();
    final ok = await auth.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      phone: _phoneController.text.trim(),
      role: role,
      skills: skills,
      primarySkill: skills.isNotEmpty ? skills.first : null,
    );
    if (ok && mounted) {
      final homeRoute =
          FlavorConfig.instance.isClient ? '/client/home' : '/fundi/home';
      Navigator.pushNamedAndRemoveUntil(context, homeRoute, (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = FlavorConfig.instance.primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AC.bg(context),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) => Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // ── Header ────────────────────────────────────────────────────
                Stack(
                  children: [
                    AuthHeader(accent: accent, isDark: isDark),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AC.surface(context).withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.arrow_back_ios_new,
                                color: AC.text(context), size: 15),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // ── Card ──────────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AC.surface(context),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: isDark ? 0.3 : 0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create account',
                          style: TextStyle(
                            color: AC.text(context),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isFundi
                              ? 'Join as a service provider'
                              : 'Join HandyGo today',
                          style:
                              TextStyle(color: AC.textSec(context), fontSize: 14),
                        ),
                        const SizedBox(height: 28),

                        // Full name
                        _label('Full Name'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          style: TextStyle(color: AC.text(context)),
                          decoration: _dec('John Doe', Icons.person_outline),
                          validator: Validators.name,
                        ),
                        const SizedBox(height: 16),

                        // Email
                        _label('Email'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(color: AC.text(context)),
                          decoration: _dec('you@example.com', Icons.mail_outline),
                          validator: Validators.email,
                        ),
                        const SizedBox(height: 16),

                        // Phone
                        _label('Phone Number (M-Pesa)'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: TextStyle(color: AC.text(context)),
                          decoration: _dec('07XX XXX XXX', Icons.phone_outlined),
                          validator: Validators.phone,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Used to receive payments via M-Pesa',
                          style: TextStyle(color: AC.textSec(context), fontSize: 11),
                        ),
                        const SizedBox(height: 16),

                        // Password
                        _label('Password'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscure,
                          style: TextStyle(color: AC.text(context)),
                          decoration:
                              _dec('Min 6 characters', Icons.lock_outline)
                                  .copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AC.textSec(context),
                                size: 20,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: Validators.password,
                        ),

                        // Skills — fundi only
                        if (_isFundi) ...[
                          const SizedBox(height: 24),
                          _label('Your Skills'),
                          const SizedBox(height: 4),
                          Text(
                            'Select all services you offer (required)',
                            style: TextStyle(
                                color: AC.textSec(context), fontSize: 12),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _skillOptions.map((skill) {
                              final name = skill['name'] as String;
                              final icon = skill['icon'] as IconData;
                              final selected = _selectedSkills.contains(name);
                              return GestureDetector(
                                onTap: () => setState(() => selected
                                    ? _selectedSkills.remove(name)
                                    : _selectedSkills.add(name)),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? accent.withValues(alpha: 0.15)
                                        : AC.input(context),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: selected
                                          ? accent
                                          : AC.div(context),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(icon,
                                          size: 15,
                                          color: selected
                                              ? accent
                                              : AC.textSec(context)),
                                      const SizedBox(width: 6),
                                      Text(
                                        name,
                                        style: TextStyle(
                                          color: selected
                                              ? accent
                                              : AC.text(context),
                                          fontWeight: selected
                                              ? FontWeight.w700
                                              : FontWeight.normal,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],

                        // Error
                        if (auth.errorMessage != null) ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: Colors.red.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: Colors.red, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(auth.errorMessage!,
                                      style: const TextStyle(
                                          color: Colors.red, fontSize: 13)),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: auth.isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            child: auth.isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.black),
                                  )
                                : const Text('Create Account',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Already have an account? ',
                                style: TextStyle(
                                    color: AC.textSec(context), fontSize: 14)),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Text('Sign in',
                                  style: TextStyle(
                                      color: accent,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: TextStyle(
          color: AC.textSec(context),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      );

  InputDecoration _dec(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AC.textSec(context), size: 20),
      );
}
