import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../home/widgets/app_drawer.dart';

/// Terms of Service Screen
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Terms of Service'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms of Service',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: December 2025',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '1. Acceptance of Terms',
              'By accessing and using the Can Can Vendor App, you accept and agree to be bound by these Terms of Service.',
            ),
            _buildSection(
              context,
              '2. Vendor Responsibilities',
              'As a vendor, you agree to:\n\n'
              '• Provide accurate business information\n'
              '• Maintain product quality and availability\n'
              '• Fulfill orders in a timely manner\n'
              '• Handle customer data responsibly\n'
              '• Comply with all applicable laws and regulations',
            ),
            _buildSection(
              context,
              '3. Service Availability',
              'We strive to provide reliable service but do not guarantee uninterrupted access. The service may be temporarily unavailable due to maintenance or technical issues.',
            ),
            _buildSection(
              context,
              '4. Payment Terms',
              'Payment processing is handled securely. Vendors are responsible for accurate pricing and payment collection from customers.',
            ),
            _buildSection(
              context,
              '5. Prohibited Activities',
              'You agree not to:\n\n'
              '• Use the service for illegal purposes\n'
              '• Misrepresent products or services\n'
              '• Interfere with the app\'s functionality\n'
              '• Violate any third-party rights',
            ),
            _buildSection(
              context,
              '6. Termination',
              'We reserve the right to suspend or terminate your account if you violate these terms or engage in fraudulent activity.',
            ),
            _buildSection(
              context,
              '7. Contact Us',
              'For questions about these Terms, contact us at:\n\n'
              'Email: legal@cancan.app\n'
              'Phone: +91 98765 43210',
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





