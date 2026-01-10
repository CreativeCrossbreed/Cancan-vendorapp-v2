/// App-wide constants for Can Can Vendor App
class AppConstants {
  // App Info
  static const String appName = 'Can Can';
  static const String appVersion = '1.0.0';

  // Time Slots
  static const List<String> timeSlots = [
    '9am - 12pm',
    '12pm - 3pm',
    '3pm - 8pm',
  ];

  // Order Status
  static const String statusPending = 'pending';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';

  // Payment Status
  static const String paymentUnpaid = 'unpaid';
  static const String paymentPaid = 'paid';

  // Payment Methods
  static const String paymentCash = 'cash';
  static const String paymentUPI = 'upi';

  // Transaction Types
  static const String transactionOrderPlaced = 'order_placed';
  static const String transactionPaymentReceived = 'payment_received';
  static const String transactionDepositPaid = 'deposit_paid';
  static const String transactionDepositRefunded = 'deposit_refunded';

  // Inventory Change Types
  static const String inventoryStockAdded = 'stock_added';
  static const String inventoryStockReduced = 'stock_reduced';
  static const String inventoryOrderDelivered = 'order_delivered';
  static const String inventoryManualAdjustment = 'manual_adjustment';

  // Default Values
  static const int defaultMaxDailyDeliveries = 100;
  static const int defaultMaxDailyCans = 120;
  static const int defaultLowStockThreshold = 10;

  // Date Formats
  static const String dateFormatDisplay = 'dd MMM yyyy'; // 20 Sep 2025
  static const String dateFormatFull =
      'EEEE, dd MMM yyyy'; // Monday, 20 Sep 2025
  static const String timeFormat = 'hh:mm a'; // 09:00 AM

  // Validation
  static const int phoneNumberLength = 10; // Indian phone numbers
  static const String phonePrefix = '+91';

  // Regex Patterns
  static final Pattern phoneRegex =
      RegExp(r'^[6-9]\d{9}$'); // Indian mobile numbers

  // WhatsApp
  static const String whatsappBusinessNumber =
      '919876543210'; // Replace with your support number

  static String getWhatsAppLink(String phone, String message) {
    return 'https://wa.me/$phone?text=${Uri.encodeComponent(message)}';
  }

  // Customer Order Link (for QR code)
  static String getCustomerOrderLink(String vendorId, String vendorPhone) {
    const message = 'Hi! I want to order water cans.';
    return getWhatsAppLink(vendorPhone, message);
  }

  // Support Contact
  static const String supportEmail = 'support@cancanindia.com';
  static const String supportPhone = '9025320535';

  // Legal Links (placeholder - update with actual URLs)
  static const String termsOfServiceUrl = 'https://cancan.app/terms';
  static const String privacyPolicyUrl = 'https://cancan.app/privacy';

  // Storage Buckets
  static const String bucketVendorProfiles = 'vendor-profiles';
  static const String bucketQRCodes = 'qr-codes';
  static const String bucketCertificates = 'certificates';

  // Notification Types
  static const String notificationNewOrder = 'new_order';
  static const String notificationLowStock = 'low_stock';
  static const String notificationPaymentReminder = 'payment_reminder';
  static const String notificationVacationReminder = 'vacation_reminder';

  // Working Days
  static const List<String> weekDays = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  static const Map<String, String> weekDayLabels = {
    'monday': 'Mon',
    'tuesday': 'Tue',
    'wednesday': 'Wed',
    'thursday': 'Thu',
    'friday': 'Fri',
    'saturday': 'Sat',
    'sunday': 'Sun',
  };
}
