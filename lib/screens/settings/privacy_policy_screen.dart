import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../home/widgets/app_drawer.dart';

/// Privacy Policy Screen
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Privacy Policy'),
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
              'Privacy Policy – Can Can',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Effective Date: December, 2025',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '1. Information We Collect',
              'We may collect the following information:\n\n'
              'From Customers [WhatsApp users]:\n'
              '• Name\n'
              '• Mobile number\n'
              '• Delivery address\n'
              '• Order details\n'
              '• Communication messages sent via WhatsApp\n'
              '• Vendor-related operational data [for registered vendors]\n\n'
              'From Vendors [Mobile app]:\n'
              '• Name\n'
              '• Mobile number\n'
              '• Business Address\n'
              '• Order Details, Delivery History, Payment History',
            ),
            _buildSection(
              context,
              '2. How We Use Your Information',
              'We use the collected information to:\n\n'
              '• Process and fulfill water delivery orders\n'
              '• Communicate order updates via WhatsApp\n'
              '• Assign and manage deliveries with vendors\n'
              '• Improve our services and operational efficiency\n'
              '• Respond to customer support requests',
            ),
            _buildSection(
              context,
              '3. WhatsApp Communication',
              'Customers may contact Can Can via WhatsApp to place orders or receive updates. By initiating communication, you consent to receive transactional and service-related messages from us on WhatsApp. We do not send unsolicited promotional messages without user consent.',
            ),
            _buildSection(
              context,
              '4. Information Sharing',
              'We do not sell or rent your personal information. Information may be shared only with:\n\n'
              '• Delivery vendors for order fulfillment\n'
              '• Service providers involved in operating our platform\n'
              '• Legal authorities if required by law',
            ),
            _buildSection(
              context,
              '5. Data Security',
              'We take reasonable measures to protect personal information against unauthorized access, misuse, or disclosure.',
            ),
            _buildSection(
              context,
              '6. Data Retention',
              'We retain personal data only for as long as necessary to fulfill the purposes outlined in this policy or as required by law.',
            ),
            _buildSection(
              context,
              '7. Your Rights',
              'You may request access, correction, or deletion of your personal data by contacting us using the details below.',
            ),
            _buildSection(
              context,
              '8. Contact Information',
              'For any privacy-related concerns, please contact us at:\n\n'
              'Phone: +91- 90253 20535\n'
              '+91- 900801 26534\n\n'
              'Email: admin@cancanindia.com\n'
              'support@cancanindia.com',
            ),
            _buildSection(
              context,
              '9. Changes to This Policy',
              'We may update this Privacy Policy from time to time. Any changes will be posted on this page.',
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









