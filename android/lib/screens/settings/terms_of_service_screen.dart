import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../home/widgets/app_drawer.dart';

/// Terms & Conditions Screen
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms & Conditions',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Effective Date: December 30, 2025',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '1. About Can Can',
              'Can Can is a platform that connects customers with independent water can delivery providers and helps manage water delivery schedules, order tracking, reminders, and usage insights.\n\n'
              'Can Can does not own, supply, manufacture, or transport water cans.',
            ),
            _buildSection(
              context,
              '2. Eligibility',
              'You must be at least 18 years old to use the Platform. By using Can Can, you confirm that you meet this requirement and that the information you provide is accurate.',
            ),
            _buildSection(
              context,
              '3. User Accounts',
              '• You are responsible for maintaining the confidentiality of your account credentials.\n'
              '• You agree to provide accurate and up-to-date information.\n'
              '• Can Can is not responsible for any unauthorized access resulting from your failure to safeguard your account.',
            ),
            _buildSection(
              context,
              '4. Services',
              'Can Can provides:\n'
              '• Order placement and delivery scheduling\n'
              '• Usage tracking and reminders\n'
              '• Communication facilitation between customers and vendors\n'
              '• Rewards, points, or incentives (if applicable)\n\n'
              'All deliveries are fulfilled by third-party vendors, and service availability may vary by location.',
            ),
            _buildSection(
              context,
              '5. Vendor Responsibility',
              '• Vendors listed on Can Can are independent service providers.\n'
              '• Can Can does not guarantee water quality, delivery timelines, pricing accuracy, or vendor performance.\n'
              '• Any disputes regarding delivery, quality, or payment must be resolved directly between the customer and the vendor.\n\n'
              'Can Can may assist in facilitation but is not liable for vendor actions.',
            ),
            _buildSection(
              context,
              '6. Payments',
              '• Payments, if enabled, may be processed through third-party payment gateways.\n'
              '• Can Can does not store sensitive payment information.\n'
              '• Pricing, refunds, and cancellations are governed by the respective vendor\'s policies unless stated otherwise.',
            ),
            _buildSection(
              context,
              '7. Acceptable Use',
              'You agree not to:\n\n'
              '• Misuse the Platform for unlawful or fraudulent purposes\n'
              '• Interfere with platform functionality\n'
              '• Attempt to access systems or data without authorization\n'
              '• Harass, threaten, or abuse vendors or other users\n\n'
              'Violations may result in account suspension or termination.',
            ),
            _buildSection(
              context,
              '8. Rewards & Points (If Applicable)',
              '• Reward points have no cash value unless explicitly stated.\n'
              '• Can Can reserves the right to modify or discontinue reward programs at any time.\n'
              '• Abuse or manipulation of rewards may result in forfeiture.',
            ),
            _buildSection(
              context,
              '9. Intellectual Property',
              'All content, branding, logos, and platform design belong to Can Can unless otherwise stated.\n\n'
              'You may not copy, reproduce, or distribute any content without written permission.',
            ),
            _buildSection(
              context,
              '10. Service Availability',
              'Can Can strives for reliability but does not guarantee uninterrupted access.\n\n'
              'Temporary downtime may occur due to maintenance, updates, or technical issues.',
            ),
            _buildSection(
              context,
              '11. Limitation of Liability',
              'To the maximum extent permitted by law:\n\n'
              '• Can Can shall not be liable for indirect, incidental, or consequential damages\n'
              '• Can Can is not responsible for water quality, health outcomes, or vendor negligence\n\n'
              'Use the Platform at your own discretion.',
            ),
            _buildSection(
              context,
              '12. Termination',
              'Can Can reserves the right to suspend or terminate access to the Platform without notice if these Terms are violated or if required by law.',
            ),
            _buildSection(
              context,
              '13. Changes to Terms',
              'These Terms may be updated periodically. Continued use of the Platform after changes indicates acceptance of the revised Terms.',
            ),
            _buildSection(
              context,
              '14. Governing Law',
              'These Terms are governed by the laws of India.\n\n'
              'Any disputes shall be subject to the jurisdiction of courts in India.',
            ),
            _buildSection(
              context,
              '15. Contact Information',
              'For questions or concerns, contact us at:\n\n'
              '📞 support@cancanindia.com',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}









