/// Order Model
class Order {
  final String id;
  final String orderNumber;
  final String vendorId;
  final String customerId;
  final DateTime deliveryDate;
  final String timeSlot;
  final double totalAmount;
  final String status;
  final bool isDelivered;
  final DateTime? deliveredAt;
  final String paymentStatus;
  final DateTime? paymentMarkedAt;
  final String? notes;
  final String? cancellationReason;
  final DateTime createdAt;

  // Related data
  final Customer? customer;
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.orderNumber,
    required this.vendorId,
    required this.customerId,
    required this.deliveryDate,
    required this.timeSlot,
    required this.totalAmount,
    required this.status,
    required this.isDelivered,
    this.deliveredAt,
    required this.paymentStatus,
    this.paymentMarkedAt,
    this.notes,
    this.cancellationReason,
    required this.createdAt,
    this.customer,
    this.items = const [],
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      orderNumber: json['order_number'] as String,
      vendorId: json['vendor_id'] as String,
      customerId: json['customer_id'] as String,
      deliveryDate: DateTime.parse(json['delivery_date'] as String),
      timeSlot: json['time_slot'] as String,
      totalAmount: (json['total_amount'] as num).toDouble(),
      status: json['status'] as String,
      isDelivered: json['is_delivered'] as bool,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'] as String)
          : null,
      paymentStatus: json['payment_status'] as String,
      paymentMarkedAt: json['payment_marked_at'] != null
          ? DateTime.parse(json['payment_marked_at'] as String)
          : null,
      notes: json['notes'] as String?,
      cancellationReason: json['cancellation_reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      customer: json['customers'] != null
          ? Customer.fromJson(json['customers'] as Map<String, dynamic>)
          : null,
      items: json['order_items'] != null
          ? (json['order_items'] as List)
              .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'vendor_id': vendorId,
      'customer_id': customerId,
      'delivery_date': deliveryDate.toIso8601String(),
      'time_slot': timeSlot,
      'total_amount': totalAmount,
      'status': status,
      'is_delivered': isDelivered,
      'delivered_at': deliveredAt?.toIso8601String(),
      'payment_status': paymentStatus,
      'payment_marked_at': paymentMarkedAt?.toIso8601String(),
      'notes': notes,
      'cancellation_reason': cancellationReason,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Customer Model (simplified for orders)
class Customer {
  final String id;
  final String vendorId;
  final String name;
  final String phone;
  final String address;
  final String? flatNumber;
  final String? floor;
  final String? buildingName;

  Customer({
    required this.id,
    this.vendorId = '',
    required this.name,
    required this.phone,
    required this.address,
    this.flatNumber,
    this.floor,
    this.buildingName,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String,
      vendorId: json['vendor_id'] as String? ?? '',
      name: json['name'] as String,
      phone: json['phone'] as String,
      address: json['address'] as String,
      flatNumber: json['flat_number'] as String?,
      floor: json['floor'] as String?,
      buildingName: json['building_name'] as String?,
    );
  }

  String get fullAddress {
    final parts = <String>[];
    if (flatNumber != null && flatNumber!.isNotEmpty) {
      parts.add('Flat $flatNumber');
    }
    if (floor != null && floor!.isNotEmpty) {
      parts.add('Floor $floor');
    }
    if (buildingName != null && buildingName!.isNotEmpty) {
      parts.add(buildingName!);
    }
    if (parts.isEmpty) {
      return address;
    }
    return '${parts.join(', ')}\n$address';
  }
}

/// Order Item Model
class OrderItem {
  final String id;
  final String orderId;
  final String productId;
  final int quantity;
  final double unitPrice;
  final double subtotal;
  final Product? product;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.product,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String,
      orderId: json['order_id'] as String? ?? '',
      productId: json['product_id'] as String? ?? '',
      quantity: json['quantity'] as int,
      unitPrice: (json['unit_price'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
      product: json['products'] != null
          ? Product.fromJson(json['products'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Product Model (simplified)
class Product {
  final String id;
  final String name;

  Product({
    required this.id,
    required this.name,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }
}
