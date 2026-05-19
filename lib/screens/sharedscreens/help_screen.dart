import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _faqs = [
    ('How do I post a job?', 'Tap the "Post a Job" button on the home screen, fill in the job details, and submit. Fundis near you will receive the request.'),
    ('How do I pay for a service?', 'Payments are handled within the app after a job is completed. You can use M-Pesa or card.'),
    ('How are fundis verified?', 'All fundis go through an ID verification and skill assessment before they can accept jobs.'),
    ('Can I cancel a booking?', 'You can cancel before the fundi accepts. After acceptance, cancellation fees may apply.'),
    ('How do I rate a fundi?', 'After a job is marked complete, you will be prompted to leave a rating and review.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.support_agent, size: 40, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Contact Support', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text('Available Mon-Fri, 8am–6pm', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                        const SizedBox(height: 8),
                        OutlinedButton(onPressed: () {}, child: const Text('Chat with us')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Frequently Asked Questions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ..._faqs.map((faq) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ExpansionTile(
              title: Text(faq.$1, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(faq.$2, style: TextStyle(color: Colors.grey[700])),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
