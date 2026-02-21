export interface Vendor {
  id: string;
  phone: string;
  name: string;
  business_name?: string;
  address?: string;
  is_on_vacation: boolean;
  commission_rate?: number;
  status: 'active' | 'inactive' | 'suspended';
  created_at: string;
  updated_at: string;
}

export interface Customer {
  id: string;
  name: string;
  phone: string;
  address: string;
  flat_number?: string;
  floor?: string;
  building_name?: string;
  created_at: string;
}

export interface Order {
  id: string;
  order_number: string;
  vendor_id: string;
  customer_id: string;
  delivery_date: string;
  time_slot: string;
  total_amount: number;
  status: 'pending' | 'completed' | 'cancelled';
  is_delivered: boolean;
  delivered_at?: string;
  payment_status: 'unpaid' | 'paid';
  payment_marked_at?: string;
  notes?: string;
  cancellation_reason?: string;
  created_at: string;
  customer?: Customer;
  vendor?: Vendor;
  order_items?: OrderItem[];
}

export interface OrderItem {
  id: string;
  order_id: string;
  product_id: string;
  quantity: number;
  unit_price: number;
  subtotal: number;
  product?: {
    name: string;
  };
}

export interface Product {
  id: string;
  name: string;
  description?: string;
  created_at: string;
}

export interface VendorProduct {
  id: string;
  vendor_id: string;
  product_id: string;
  selling_price: number;
  current_stock: number;
  is_available: boolean;
  product?: Product;
}

export interface WhatsAppMessage {
  id: string;
  message_id: string;
  customer_phone: string;
  message_type: string;
  message_content: string;
  direction: 'inbound' | 'outbound';
  status: string;
  created_at: string;
}

export interface WhatsAppOrder {
  id: string;
  message_id: string;
  customer_id: string;
  parsed_quantity?: number;
  parsed_product?: string;
  status: string;
  assigned_vendor_id?: string;
  created_at: string;
  customer?: Customer;
  assigned_vendor?: Vendor;
}

export interface AdminUser {
  id: string;
  email: string;
  password: string;
  role: 'super_admin' | 'operations' | 'support';
  created_at: string;
  last_login?: string;
}

export interface CommissionRecord {
  id: string;
  order_id: string;
  vendor_id: string;
  commission_amount: number;
  order_amount: number;
  commission_rate: number;
  status: 'pending' | 'paid';
  created_at: string;
  paid_at?: string;
}

export interface DashboardStats {
  totalVendors: number;
  activeVendors: number;
  totalCustomers: number;
  todayOrders: number;
  todayRevenue: number;
  commissionEarned: number;
  whatsappOrdersProcessed: number;
  pendingPayments: number;
}