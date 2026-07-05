import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme.dart';
import '../../services/vendor_service.dart';
import '../../services/vendor_data_service.dart';

/// Collects the vendor's payout destination (bank account OR UPI) — required
/// for Cashfree payouts. Used both as an onboarding step (pass [isOnboarding]
/// + [onComplete]) and standalone from Settings for editing.
class PayoutDetailsScreen extends StatefulWidget {
  final bool isOnboarding;
  final VoidCallback? onComplete;

  const PayoutDetailsScreen({
    super.key,
    this.isOnboarding = false,
    this.onComplete,
  });

  @override
  State<PayoutDetailsScreen> createState() => _PayoutDetailsScreenState();
}

class _PayoutDetailsScreenState extends State<PayoutDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vendorService = VendorService();

  final _holderController = TextEditingController();
  final _accountController = TextEditingController();
  final _ifscController = TextEditingController();
  final _vpaController = TextEditingController();

  String _method = 'bank'; // 'bank' | 'upi'
  bool _isLoading = false;
  bool _isPrefilling = true;

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  Future<void> _prefill() async {
    final data = await VendorDataService.getVendorProfile();
    if (!mounted) return;
    setState(() {
      _holderController.text = (data?['bank_account_holder_name'] ?? '') as String;
      _accountController.text = (data?['bank_account_number'] ?? '') as String;
      _ifscController.text = (data?['bank_ifsc'] ?? '') as String;
      _vpaController.text = (data?['payout_vpa'] ?? '') as String;
      final vpa = (data?['payout_vpa'] ?? '') as String;
      _method = vpa.isNotEmpty ? 'upi' : 'bank';
      _isPrefilling = false;
    });
  }

  @override
  void dispose() {
    _holderController.dispose();
    _accountController.dispose();
    _ifscController.dispose();
    _vpaController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final result = await _vendorService.updatePayoutDetails(
        method: _method,
        holderName: _holderController.text,
        accountNumber: _accountController.text,
        ifsc: _ifscController.text,
        vpa: _vpaController.text,
      );
      if (!mounted) return;
      if (result['success'] == true) {
        if (widget.isOnboarding) {
          widget.onComplete?.call();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payout details saved'),
              backgroundColor: AppTheme.successGreen,
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        _showError(result['message'] ?? 'Failed to save payout details');
      }
    } catch (e) {
      _showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.errorRed),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        title: Text(widget.isOnboarding ? 'Payout Details' : 'Bank / UPI Details'),
        automaticallyImplyLeading: !widget.isOnboarding,
      ),
      body: SafeArea(
        child: _isPrefilling
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'How should we pay you?',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Add a bank account or UPI to receive your collected payments.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 20),

                      // Method toggle
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'bank', label: Text('Bank Account'), icon: Icon(Icons.account_balance_outlined)),
                          ButtonSegment(value: 'upi', label: Text('UPI'), icon: Icon(Icons.qr_code_rounded)),
                        ],
                        selected: {_method},
                        onSelectionChanged: (s) => setState(() => _method = s.first),
                      ),
                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _holderController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Account Holder Name',
                          hintText: 'As per bank / UPI records',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Please enter the account holder name' : null,
                      ),
                      const SizedBox(height: 16),

                      if (_method == 'bank') ...[
                        TextFormField(
                          controller: _accountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(
                            labelText: 'Account Number',
                            prefixIcon: Icon(Icons.numbers_rounded),
                          ),
                          validator: (v) {
                            if (_method != 'bank') return null;
                            final t = v?.trim() ?? '';
                            if (t.length < 8 || t.length > 18) return 'Enter a valid account number';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _ifscController,
                          textCapitalization: TextCapitalization.characters,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]')),
                            LengthLimitingTextInputFormatter(11),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'IFSC Code',
                            hintText: 'e.g., HDFC0001234',
                            prefixIcon: Icon(Icons.account_balance_outlined),
                          ),
                          validator: (v) {
                            if (_method != 'bank') return null;
                            final t = (v?.trim() ?? '').toUpperCase();
                            if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(t)) return 'Enter a valid IFSC code';
                            return null;
                          },
                        ),
                      ] else ...[
                        TextFormField(
                          controller: _vpaController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'UPI ID (VPA)',
                            hintText: 'e.g., name@okhdfcbank',
                            prefixIcon: Icon(Icons.alternate_email_rounded),
                          ),
                          validator: (v) {
                            if (_method != 'upi') return null;
                            final t = v?.trim() ?? '';
                            if (!RegExp(r'^[\w.\-]{2,}@[a-zA-Z]{2,}$').hasMatch(t)) return 'Enter a valid UPI ID';
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.lightGray,
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.lock_outline, size: 18, color: AppTheme.textSecondary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Used only to transfer your earnings. You can change this anytime in Settings.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      ElevatedButton(
                        onPressed: _isLoading ? null : _save,
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20, width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.textPrimary),
                              )
                            : Text(widget.isOnboarding ? 'Finish Setup' : 'Save'),
                      ),
                      if (widget.isOnboarding) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _isLoading ? null : widget.onComplete,
                          child: const Text('Skip for now'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
