/// Order Model
class Order {
  final String id;
  final String orderNumber;
  final String vendorId;
  final String customerId;
  final DateTime deliveryDate;
  final String timeSlot;
  final double totalAmount;
  final double amountPaid;
  final double remainingAmount;
  final String status;
  final bool isDelivered;
  final DateTime? deliveredAt;
  final String paymentStatus;
  final DateTime? paymentMarkedAt;
  final String? notes;
  final String? cancellationReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Related data
  final Customer? customer;
  final List<OrderItem> items;
  final List<Payment>? payments;

  Order({
    required this.id,
    required this.orderNumber,
    required this.vendorId,
    required this.customerId,
    required this.deliveryDate,
    required this.timeSlot,
    required this.totalAmount,
    required this.amountPaid,
    required this.remainingAmount,
    required this.status,
    required this.isDelivered,
    this.deliveredAt,
    required this.paymentStatus,
    this.paymentMarkedAt,
    this.notes,
    this.cancellationReason,
    required this.createdAt,
    required this.updatedAt,
    this.customer,
    this.items = const [],
    this.payments,
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
      amountPaid: json['amount_paid'] != null
          ? (json['amount_paid'] as num).toDouble()
          : 0.0,
      remainingAmount: json['remaining_amount'] != null
          ? (json['remaining_amount'] as num).toDouble()
          : 0.0,
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
      updatedAt: DateTime.parse(json['updated_at'] as String),
      customer: json['customers'] != null
          ? Customer.fromJson(json['customers'] as Map<String, dynamic>)
          : null,
      items: json['order_items'] != null
          ? (json['order_items'] as List)
              .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
              .toList()
          : [],
      payments: json['payments'] != null
          ? (json['payments'] as List)
              .map((p) => Payment.fromJson(p as Map<String, dynamic>))
              .toList()
          : null,
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
      'amount_paid': amountPaid,
      'remaining_amount': remainingAmount,
      'status': status,
      'is_delivered': isDelivered,
      'delivered_at': deliveredAt?.toIso8601String(),
      'payment_status': paymentStatus,
      'payment_marked_at': paymentMarkedAt?.toIso8601String(),
      'notes': notes,
      'cancellation_reason': cancellationReason,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// Customer Model (simplified for orders)
class Customer {
  final String id;
  final String name;
  final String phone;
  final String address;
  final String? flatNumber;
  final String? floor;
  final String? buildingName;
  final DateTime createdAt;
  final DateTime updatedAt;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    this.flatNumber,
    this.floor,
    this.buildingName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      address: json['address'] as String,
      flatNumber: json['flat_number'] as String?,
      floor: json['floor'] as String?,
      buildingName: json['building_name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
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

/// Payment Model - Tracks individual payment transactions
class Payment {
  final String id;
  final String orderId;
  final double amount;
  final String? paymentMethod;
  final String? notes;
  final DateTime createdAt;

  Payment({
    required this.id,
    required this.orderId,
    required this.amount,
    this.paymentMethod,
    this.notes,
    required this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      paymentMethod: json['payment_method'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'amount': amount,
      'payment_method': paymentMethod,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// VendorProduct Model - Links vendors to products with pricing and inventory
class VendorProduct {
  final String id;
  final String vendorId;
  final String productId;
  final double sellingPrice;
  final double depositAmount;
  final int currentStock;
  final int lowStockThreshold;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Related product info
  final Product? product;

  VendorProduct({
    required this.id,
    required this.vendorId,
    required this.productId,
    required this.sellingPrice,
    required this.depositAmount,
    required this.currentStock,
    required this.lowStockThreshold,
    required this.createdAt,
    required this.updatedAt,
    this.product,
  });

  factory VendorProduct.fromJson(Map<String, dynamic> json) {
    return VendorProduct(
      id: json['id'] as String,
      vendorId: json['vendor_id'] as String,
      productId: json['product_id'] as String,
      sellingPrice: (json['selling_price'] as num).toDouble(),
      depositAmount: (json['deposit_amount'] as num).toDouble(),
      currentStock: json['current_stock'] as int,
      lowStockThreshold: json['low_stock_threshold'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      product: json['products'] != null
          ? Product.fromJson(json['products'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendor_id': vendorId,
      'product_id': productId,
      'selling_price': sellingPrice,
      'deposit_amount': depositAmount,
      'current_stock': currentStock,
      'low_stock_threshold': lowStockThreshold,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Get stock status label
  String get stockStatus {
    if (currentStock == 0) return 'out_of_stock';
    if (currentStock <= lowStockThreshold) return 'low_stock';
    return 'in_stock';
  }

  /// Check if stock is low
  bool get isLowStock => currentStock <= lowStockThreshold;

  /// Check if out of stock
  bool get isOutOfStock => currentStock == 0;
}
