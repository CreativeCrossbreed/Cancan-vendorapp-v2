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
  stats?: {
    totalOrders: number;
    completedOrders: number;
    totalRevenue: number;
    totalCommission: number;
  };
}

export interface Customer {
  id: string;
  name: string;
  phone: string;
  address: string;
  flat_number?: string;
  floor?: string;
  building_name?: string;
  status?: string;
  created_at: string;
  stats?: {
    totalOrders: number;
    completedOrders: number;
    totalSpent: number;
    lastOrderDate?: string;
  };
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
  vendor?: {
    name: string;
    business_name?: string;
  };
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
  customer?: {
    name: string;
    phone: string;
  };
  assigned_vendor?: {
    name: string;
    business_name?: string;
  };
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
  vendor?: {
    name: string;
    business_name?: string;
  };
  order?: {
    order_number: string;
    total_amount: number;
    created_at: string;
  };
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

export interface AdminUser {
  id: string;
  email: string;
  role: 'super_admin' | 'operations' | 'support';
  last_login?: string;
}

export interface Pagination {
  page: number;
  limit: number;
  total: number;
  totalPages: number;
}

export interface ApiResponse<T> {
  data?: T;
  pagination?: Pagination;
  error?: string;
}