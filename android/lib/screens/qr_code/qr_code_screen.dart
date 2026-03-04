import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';
import '../../config/theme.dart';
import '../../config/supabase_config.dart';
import '../../services/app_settings_service.dart';
import '../../widgets/screen_with_nav.dart';
import '../home/widgets/app_drawer.dart';
import '../../utils/logger.dart';

/// QR Code Screen - Generate and display vendor QR code for customer onboarding
///
/// Flow:
/// 1. Fetches vendor name/business from `vendors` table
/// 2. Fetches central WhatsApp Business number from `app_config` table
/// 3. Generates QR code: `https://wa.me/<number>?text=ref-<vendorId>`
/// 4. Customer scans → WhatsApp opens → webhook identifies vendor via ref code
class QRCodeScreen extends StatefulWidget {
  const QRCodeScreen({super.key});

  @override
  State<QRCodeScreen> createState() => _QRCodeScreenState();
}

class _QRCodeScreenState extends State<QRCodeScreen> {
  final _supabase = SupabaseConfig.client;
  bool _isLoading = true;
  String? _vendorName;
  String? _businessName;
  String? _qrData;
  String? _errorMessage;

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
        setState(() {
          _errorMessage = 'No vendor session found. Please log in again.';
          _isLoading = false;
        });
        return;
      }

      // Fetch vendor info
      final data =
          await _supabase.from('vendors').select().eq('id', vendorId).single();

      // Fetch WhatsApp Business number from app_config table
      final businessNumber =
          await AppSettingsService.getWhatsAppBusinessNumber();

      final name = data['name'] as String? ?? 'Vendor';
      final business = data['business_name'] as String? ?? 'Business';

      if (businessNumber.isEmpty) {
        setState(() {
          _vendorName = name;
          _businessName = business;
          _errorMessage =
              'WhatsApp Business number not configured. Please contact support.';
          _isLoading = false;
        });
        return;
      }

      // Message format the webhook expects: "ref-{vendorId}"
      final message = Uri.encodeComponent('ref-$vendorId');
      final whatsappLink = 'https://wa.me/$businessNumber?text=$message';

      setState(() {
        _vendorName = name;
        _businessName = business;
        _qrData = whatsappLink;
        _isLoading = false;
      });

      AppLogger.i('QR code generated for vendor $vendorId');
    } catch (e) {
      AppLogger.e('Error loading vendor data for QR: $e');
      setState(() {
        _errorMessage = 'Failed to load QR code data. Pull down to retry.';
        _isLoading = false;
      });
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
                'When customers scan the QR code, it opens WhatsApp with your vendor code pre-filled.',
              ),
              _buildInstructionStep(
                3,
                'Automatic Onboarding',
                'The system automatically links the customer to your account via the vendor code.',
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
          : _errorMessage != null && _qrData == null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _loadVendorData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Header
                        Text(
                          'Your Business QR Code',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Customers scan this to join your network via WhatsApp',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppTheme.textSecondary),
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
                                            color: AppTheme.white
                                                .withValues(alpha: 0.9),
                                          ),
                                    ),
                                  ],
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
                                      color: AppTheme.primaryBlue
                                          .withValues(alpha: 0.3),
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

                              Text(
                                'Scan with phone camera',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppTheme.textSecondary),
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
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
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
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
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
                                        ?.copyWith(fontWeight: FontWeight.bold),
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
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppTheme.errorRed,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadVendorData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
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
