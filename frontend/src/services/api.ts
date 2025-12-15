import axios, { AxiosInstance, AxiosResponse } from 'axios';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:5000/api';

class ApiService {
  private api: AxiosInstance;

  constructor() {
    this.api = axios.create({
      baseURL: API_BASE_URL,
      timeout: 10000,
      headers: {
        'Content-Type': 'application/json',
      },
    });

    // Add request interceptor to include auth token
    this.api.interceptors.request.use(
      (config) => {
        const token = localStorage.getItem('token');
        if (token) {
          config.headers.Authorization = `Bearer ${token}`;
        }
        return config;
      },
      (error) => {
        return Promise.reject(error);
      }
    );

    // Add response interceptor to handle errors
    this.api.interceptors.response.use(
      (response: AxiosResponse) => response,
      (error) => {
        if (error.response?.status === 401) {
          // Unauthorized - redirect to login
          localStorage.removeItem('token');
          window.location.href = '/login';
        }
        return Promise.reject(error);
      }
    );
  }

  // Authentication
  async login(email: string, password: string) {
    const response = await this.api.post('/auth/login', { email, password });
    return response.data;
  }

  async getProfile() {
    const response = await this.api.get('/auth/me');
    return response.data;
  }

  async changePassword(currentPassword: string, newPassword: string) {
    const response = await this.api.put('/auth/change-password', {
      currentPassword,
      newPassword,
    });
    return response.data;
  }

  // Dashboard
  async getDashboardStats(): Promise<DashboardStats> {
    const response = await this.api.get('/dashboard/stats');
    return response.data;
  }

  async getRevenueAnalytics(period: number = 7) {
    const response = await this.api.get(`/dashboard/revenue?period=${period}`);
    return response.data;
  }

  async getTopVendors(period: number = 30) {
    const response = await this.api.get(`/dashboard/top-vendors?period=${period}`);
    return response.data;
  }

  async getRecentActivities() {
    const response = await this.api.get('/dashboard/recent-activities');
    return response.data;
  }

  async getOrderDistribution(period: number = 7) {
    const response = await this.api.get(`/dashboard/order-distribution?period=${period}`);
    return response.data;
  }

  // Vendors
  async getVendors(params: {
    page?: number;
    limit?: number;
    status?: string;
    search?: string;
  } = {}) {
    const response = await this.api.get('/vendors', { params });
    return response.data;
  }

  async getVendorById(id: string) {
    const response = await this.api.get(`/vendors/${id}`);
    return response.data;
  }

  async createVendor(vendorData: Partial<Vendor>) {
    const response = await this.api.post('/vendors', vendorData);
    return response.data;
  }

  async updateVendor(id: string, vendorData: Partial<Vendor>) {
    const response = await this.api.put(`/vendors/${id}`, vendorData);
    return response.data;
  }

  async deleteVendor(id: string) {
    const response = await this.api.delete(`/vendors/${id}`);
    return response.data;
  }

  async getVendorStats(id: string, period: number = 30) {
    const response = await this.api.get(`/vendors/${id}/stats?period=${period}`);
    return response.data;
  }

  // Customers
  async getCustomers(params: {
    page?: number;
    limit?: number;
    search?: string;
  } = {}) {
    const response = await this.api.get('/customers', { params });
    return response.data;
  }

  async getCustomerById(id: string) {
    const response = await this.api.get(`/customers/${id}`);
    return response.data;
  }

  async createCustomer(customerData: Partial<Customer>) {
    const response = await this.api.post('/customers', customerData);
    return response.data;
  }

  async updateCustomer(id: string, customerData: Partial<Customer>) {
    const response = await this.api.put(`/customers/${id}`, customerData);
    return response.data;
  }

  async getCustomerAnalytics(id: string, period: number = 30) {
    const response = await this.api.get(`/customers/${id}/analytics?period=${period}`);
    return response.data;
  }

  // Orders
  async getOrders(params: {
    page?: number;
    limit?: number;
    status?: string;
    payment_status?: string;
    vendor_id?: string;
    customer_id?: string;
    date_from?: string;
    date_to?: string;
  } = {}) {
    const response = await this.api.get('/orders', { params });
    return response.data;
  }

  async getOrderById(id: string) {
    const response = await this.api.get(`/orders/${id}`);
    return response.data;
  }

  async updateOrderStatus(id: string, status: string, notes?: string, cancellation_reason?: string) {
    const response = await this.api.put(`/orders/${id}/status`, {
      status,
      notes,
      cancellation_reason,
    });
    return response.data;
  }

  async updatePaymentStatus(id: string, payment_status: string) {
    const response = await this.api.put(`/orders/${id}/payment`, { payment_status });
    return response.data;
  }

  async assignOrder(id: string, vendor_id: string) {
    const response = await this.api.put(`/orders/${id}/assign`, { vendor_id });
    return response.data;
  }

  async createOrder(orderData: any) {
    const response = await this.api.post('/orders', orderData);
    return response.data;
  }

  async getTodayOrders() {
    const response = await this.api.get('/orders/today/all');
    return response.data;
  }

  // WhatsApp
  async getWhatsAppConfig() {
    const response = await this.api.get('/whatsapp/config');
    return response.data;
  }

  async getWhatsAppMessages(params: {
    page?: number;
    limit?: number;
    direction?: string;
  } = {}) {
    const response = await this.api.get('/whatsapp/messages', { params });
    return response.data;
  }

  async getWhatsAppOrders(params: {
    page?: number;
    limit?: number;
    status?: string;
  } = {}) {
    const response = await this.api.get('/whatsapp/orders', { params });
    return response.data;
  }

  async sendWhatsAppMessage(to: string, message: string) {
    const response = await this.api.post('/whatsapp/send', { to, message });
    return response.data;
  }

  // Commissions
  async getCommissions(params: {
    page?: number;
    limit?: number;
    status?: string;
    vendor_id?: string;
    date_from?: string;
    date_to?: string;
  } = {}) {
    const response = await this.api.get('/commissions', { params });
    return response.data;
  }

  async getCommissionStats(period: number = 30) {
    const response = await this.api.get(`/commissions/stats?period=${period}`);
    return response.data;
  }

  async getVendorCommissionBreakdown(period: number = 30) {
    const response = await this.api.get(`/commissions/vendor-breakdown?period=${period}`);
    return response.data;
  }

  async createCommission(commissionData: any) {
    const response = await this.api.post('/commissions', commissionData);
    return response.data;
  }

  async updateCommissionStatus(id: string, status: string) {
    const response = await this.api.put(`/commissions/${id}/status`, { status });
    return response.data;
  }

  async bulkUpdateCommissionStatus(commission_ids: string[], status: string) {
    const response = await this.api.put('/commissions/bulk-status', {
      commission_ids,
      status,
    });
    return response.data;
  }

  async getCommissionTrends(period: number = 30) {
    const response = await this.api.get(`/commissions/trends?period=${period}`);
    return response.data;
  }
}

export const apiService = new ApiService();
export default apiService;