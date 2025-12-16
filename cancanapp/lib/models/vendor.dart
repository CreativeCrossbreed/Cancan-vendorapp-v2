/// Vendor model representing a water can delivery vendor
class Vendor {
  final String id;
  final String userId;
  final String businessName;
  final String ownerName;
  final String phone;
  final String address;
  final String? email;
  final String businessType;
  final String? gstNumber;
  final String? fssaiLicense;
  final double? latitude;
  final double? longitude;
  final Map<String, dynamic> businessHours;
  final List<String> serviceAreas;
  final bool isActive;
  final bool isVerified;
  final bool isOnVacation;
  final String? vacationReason;
  final DateTime? vacationEndDate;
  final double rating;
  final int totalOrders;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Vendor({
    required this.id,
    required this.userId,
    required this.businessName,
    required this.ownerName,
    required this.phone,
    required this.address,
    this.email,
    required this.businessType,
    this.gstNumber,
    this.fssaiLicense,
    this.latitude,
    this.longitude,
    required this.businessHours,
    required this.serviceAreas,
    required this.isActive,
    required this.isVerified,
    this.isOnVacation = false,
    this.vacationReason,
    this.vacationEndDate,
    required this.rating,
    required this.totalOrders,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create vendor from JSON
  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      businessName: json['business_name'] as String,
      ownerName: json['owner_name'] as String,
      phone: json['phone'] as String,
      address: json['address'] as String,
      email: json['email'] as String?,
      businessType: json['business_type'] as String? ?? 'water_can_delivery',
      gstNumber: json['gst_number'] as String?,
      fssaiLicense: json['fssai_license'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      businessHours: json['business_hours'] as Map<String, dynamic>? ?? {},
      serviceAreas: (json['service_areas'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      isActive: json['is_active'] as bool? ?? true,
      isVerified: json['is_verified'] as bool? ?? false,
      isOnVacation: json['is_on_vacation'] as bool? ?? false,
      vacationReason: json['vacation_reason'] as String?,
      vacationEndDate: json['vacation_end_date'] != null
          ? DateTime.parse(json['vacation_end_date'] as String)
          : null,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalOrders: json['total_orders'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert vendor to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'business_name': businessName,
      'owner_name': ownerName,
      'phone': phone,
      'address': address,
      'email': email,
      'business_type': businessType,
      'gst_number': gstNumber,
      'fssai_license': fssaiLicense,
      'latitude': latitude,
      'longitude': longitude,
      'business_hours': businessHours,
      'service_areas': serviceAreas,
      'is_active': isActive,
      'is_verified': isVerified,
      'is_on_vacation': isOnVacation,
      'vacation_reason': vacationReason,
      'vacation_end_date': vacationEndDate?.toIso8601String(),
      'rating': rating,
      'total_orders': totalOrders,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy of vendor with updated fields
  Vendor copyWith({
    String? id,
    String? userId,
    String? businessName,
    String? ownerName,
    String? phone,
    String? address,
    String? email,
    String? businessType,
    String? gstNumber,
    String? fssaiLicense,
    double? latitude,
    double? longitude,
    Map<String, dynamic>? businessHours,
    List<String>? serviceAreas,
    bool? isActive,
    bool? isVerified,
    bool? isOnVacation,
    String? vacationReason,
    DateTime? vacationEndDate,
    double? rating,
    int? totalOrders,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Vendor(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      businessName: businessName ?? this.businessName,
      ownerName: ownerName ?? this.ownerName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      email: email ?? this.email,
      businessType: businessType ?? this.businessType,
      gstNumber: gstNumber ?? this.gstNumber,
      fssaiLicense: fssaiLicense ?? this.fssaiLicense,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      businessHours: businessHours ?? this.businessHours,
      serviceAreas: serviceAreas ?? this.serviceAreas,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      isOnVacation: isOnVacation ?? this.isOnVacation,
      vacationReason: vacationReason ?? this.vacationReason,
      vacationEndDate: vacationEndDate ?? this.vacationEndDate,
      rating: rating ?? this.rating,
      totalOrders: totalOrders ?? this.totalOrders,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if vendor is currently on vacation
  bool get isCurrentlyOnVacation {
    if (!isOnVacation || vacationEndDate == null) return isOnVacation;
    return DateTime.now().isBefore(vacationEndDate!);
  }

  /// Check if vendor is open for business at current time
  bool isOpenNow() {
    if (!isActive || isCurrentlyOnVacation) return false;

    final now = DateTime.now();
    final dayName = _getDayName(now.weekday);

    final dayHours = businessHours[dayName] as Map<String, dynamic>?;
    if (dayHours == null) return false;

    final isClosed = dayHours['closed'] as bool? ?? false;
    if (isClosed) return false;

    final openTime = dayHours['open'] as String?;
    final closeTime = dayHours['close'] as String?;

    if (openTime == null || closeTime == null) return false;

    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return currentTime.compareTo(openTime) >= 0 && currentTime.compareTo(closeTime) <= 0;
  }

  /// Get formatted rating string
  String get formattedRating {
    return rating.toStringAsFixed(1);
  }

  /// Get service areas as formatted string
  String get serviceAreasFormatted {
    if (serviceAreas.isEmpty) return 'Not specified';
    if (serviceAreas.length <= 3) return serviceAreas.join(', ');
    return '${serviceAreas.take(3).join(', ')} +${serviceAreas.length - 3} more';
  }

  /// Get day name from weekday number
  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'monday';
      case 2: return 'tuesday';
      case 3: return 'wednesday';
      case 4: return 'thursday';
      case 5: return 'friday';
      case 6: return 'saturday';
      case 7: return 'sunday';
      default: return 'monday';
    }
  }

  @override
  String toString() {
    return 'Vendor(id: $id, businessName: $businessName, ownerName: $ownerName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Vendor && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}