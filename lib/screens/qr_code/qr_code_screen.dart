import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../config/supabase_config.dart';
import '../../services/vendor_data_service.dart';
import '../../widgets/screen_with_nav.dart';
import '../home/widgets/app_drawer.dart';

/// QR Code Screen - Generate and display vendor QR code for customer orders
class QRCodeScreen extends StatefulWidget {
  const QRCodeScreen({super.key});

  @override
  State<QRCodeScreen> createState() => _QRCodeScreenState();
}

class _QRCodeScreenState extends State<QRCodeScreen> {
  bool _isLoading = true;
  String? _vendorId;
  String? _vendorPhone;
  String? _vendorName;
  String? _businessName;
  String? _qrData;

  @override
  void initState() {
    super.initState();
    _loadVendorData();
  }

  Future<void> _loadVendorData() async {
    setState(() => _isLoading = true);

    try {
      final vendorId = SupabaseConfig.currentVendorId;

      if (vendorId == null) {
        throw Exception('No vendor ID found. Please login again.');
      }
      _vendorId = vendorId;

      // Use VendorDataService for consistent data loading
      final data = await VendorDataService.getVendorProfile(forceRefresh: true);

      if (data == null) {
        throw Exception('Failed to load vendor data');
      }

      final phone = data['phone'] as String;
      final name = data['name'] as String;
      final business = data['business_name'] as String;

      // Route customers to Can Can business number with vendor context.
      final whatsappLink = AppConstants.getCustomerOrderLink(vendorId);

      setState(() {
        _vendorPhone = phone;
        _vendorName = name;
        _businessName = business;
        _qrData = whatsappLink;
        _isLoading = false;
      });

      debugPrint('✅ QR code generated for $_vendorName');
    } catch (e) {
      debugPrint('❌ Error loading vendor data: $e');

      setState(() {
        _isLoading = false;
        _vendorPhone = null;
        _vendorName = null;
        _businessName = null;
        _qrData = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load vendor data. Please try again.'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  void _copyLink() {
    if (_qrData != null) {
      Clipboard.setData(ClipboardData(text: _qrData!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('WhatsApp link copied to clipboard!'),
          backgroundColor: AppTheme.successGreen,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _shareInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to Use'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInstructionStep(
                1,
                'Print Your QR Code',
                'Take a screenshot or print this QR code and display it at your shop.',
              ),
              _buildInstructionStep(
                2,
                'Customers Scan',
                          'When customers scan the QR code with their phone camera, it opens Can Can WhatsApp.',
              ),
              _buildInstructionStep(
                3,
                          'Can Can Handles Flow',
                          'Can Can bot handles onboarding and order flow first, then shares your contact when needed.',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      color: AppTheme.primaryBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tip: Place the QR code at your shop entrance or on delivery cans!',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(int step, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: AppTheme.primaryBlue,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$step',
                style: const TextStyle(
                  color: AppTheme.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScreenWithNav(
      title: 'My QR Code',
      drawer: const AppDrawer(),
      currentNavIndex: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.help_outline_rounded),
          onPressed: _shareInstructions,
          tooltip: 'How to Use',
        ),
      ],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _qrData == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: AppTheme.errorRed),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load QR code',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text('Please try again or contact support'),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadVendorData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Header
                  Text(
                    'Your Business QR Code',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Customers can scan this to order via WhatsApp',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // QR Code Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Business Info
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.water_drop_rounded,
                                size: 40,
                                color: AppTheme.white,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _businessName ?? 'Business Name',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      color: AppTheme.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _vendorName ?? 'Vendor',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color:
                                          AppTheme.white.withValues(alpha: 0.9),
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.phone,
                                      size: 14,
                                      color: AppTheme.white,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _vendorPhone ?? '',
                                      style: const TextStyle(
                                        color: AppTheme.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_vendorId != null)
                          Text(
                            'Vendor Ref: ref-$_vendorId',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        const SizedBox(height: 24),

                        // QR Code
                        if (_qrData != null)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color:
                                    AppTheme.primaryBlue.withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                            child: QrImageView(
                              data: _qrData!,
                              version: QrVersions.auto,
                              size: 200,
                              backgroundColor: AppTheme.white,
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: AppTheme.primaryBlue,
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),

                        // Scan instruction
                        Text(
                          'Scan with phone camera',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _copyLink,
                          icon: const Icon(Icons.copy),
                          label: const Text('Copy WhatsApp Link'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.successGreen,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Take a screenshot to save the QR code!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.download),
                          label: const Text('Save QR Code'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Usage Tips
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.lightGray,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.tips_and_updates,
                              color: AppTheme.primaryBlue,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Usage Tips',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildTip('Display at your shop entrance'),
                        _buildTip('Print on delivery receipts'),
                        _buildTip('Stick on water cans'),
                        _buildTip('Share on social media'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            size: 16,
            color: AppTheme.successGreen,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
