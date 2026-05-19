import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../config/flavor_config.dart';
import '../../providers/job_provider.dart';

class RateFundiScreen extends StatefulWidget {
  final String jobId;
  final String fundiName;
  final String fundiId;
  const RateFundiScreen({super.key, required this.jobId, required this.fundiName, required this.fundiId});

  @override
  State<RateFundiScreen> createState() => _RateFundiScreenState();
}

class _RateFundiScreenState extends State<RateFundiScreen> {
  int _rating = 5;
  int _selectedTip = 0;
  final List<int> _tipOptions = [0, 50, 100, 200];
  final _reviewController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final ok = await context.read<JobProvider>().submitRating(
      jobId: widget.jobId,
      fundiId: widget.fundiId,
      rating: _rating,
      tip: _selectedTip,
      review: _reviewController.text.trim().isEmpty ? null : _reviewController.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rating submitted. Thank you!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } else {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit rating. Please try again.'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = FlavorConfig.instance.primaryColor;

    return Scaffold(
      backgroundColor: AC.bg(context),
      appBar: AppBar(
        backgroundColor: AC.bg(context),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('How was your service?'),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(18),
          child: Text('Rate your experience', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 32),

                  // Avatar
                  Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      color: AC.surface(context),
                      shape: BoxShape.circle,
                      border: Border.all(color: AC.div(context), width: 2),
                    ),
                    child: const Icon(Icons.person, size: 50, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  Text(widget.fundiName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  const Text('Professional Fundi', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 28),

                  // Stars
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) => GestureDetector(
                      onTap: () => setState(() => _rating = i + 1),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          i < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: Colors.amber,
                          size: 44,
                        ),
                      ),
                    )),
                  ),
                  const SizedBox(height: 20),

                  // Written review
                  TextField(
                    controller: _reviewController,
                    maxLines: 3,
                    style: TextStyle(color: AC.text(context)),
                    decoration: InputDecoration(
                      hintText: 'Write a review (optional)...',
                      hintStyle: const TextStyle(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AC.input(context),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tip section
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Would you like to leave a tip?', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: _tipOptions.map((tip) {
                      final selected = _selectedTip == tip;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTip = tip),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selected ? accent : AppColors.inputFill,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              tip == 0 ? 'No tip' : 'KES $tip',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: selected ? Colors.black : AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  const Text('The fundi receives 100% of tips.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),

                  if (_selectedTip > 0) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AC.surface(context), borderRadius: BorderRadius.circular(14)),
                      child: Row(
                        children: [
                          Container(
                            width: 36, height: 24,
                            decoration: BoxDecoration(color: AC.input(context), borderRadius: BorderRadius.circular(4)),
                            child: const Icon(Icons.phone_android, size: 16, color: AppColors.textSecondary),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(child: Text('M-Pesa tip', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))),
                          Text(
                            'KES $_selectedTip',
                            style: TextStyle(color: AC.text(context), fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Bottom buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _submitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : const Text('Submit Rating', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Skip for Now', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
