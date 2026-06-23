import axios from 'axios';

// In Next.js, we use relative paths — same origin, no separate server needed
const API_BASE_URL = '/api';

class ApiService {
    private readonly api = axios.create({
        baseURL: API_BASE_URL,
        timeout: 10000,
        headers: { 'Content-Type': 'application/json' },
    });

    constructor() {
        // Add auth token to requests
        this.api.interceptors.request.use((config) => {
            if (typeof window !== 'undefined') {
                const token = localStorage.getItem('token');
                if (token) {
                    config.headers.Authorization = `Bearer ${token}`;
                }
            }
            return config;
        });

        // Handle 401 — redirect to portal login
        this.api.interceptors.response.use(
            (response) => response,
            (error) => {
                if (error.response?.status === 401 && typeof window !== 'undefined') {
                    localStorage.removeItem('token');
                    window.location.href = '/portal/login';
                }
                return Promise.reject(error);
            }
        );
    }

    // Auth
    async login(email: string, password: string) {
        const res = await this.api.post('/auth/admin/login', { email, password });
        return res.data;
    }

    async getProfile() {
        const res = await this.api.get('/auth/me');
        return res.data;
    }

    async changePassword(currentPassword: string, newPassword: string) {
        const res = await this.api.put('/auth/change-password', { currentPassword, newPassword });
        return res.data;
    }

    // Dashboard
    async getDashboardStats() {
        const res = await this.api.get('/dashboard/stats');
        return res.data;
    }

    async getRevenueAnalytics(period = 7) {
        const res = await this.api.get(`/dashboard/revenue?period=${period}`);
        return res.data;
    }

    async getTopVendors(period = 30) {
        const res = await this.api.get(`/dashboard/top-vendors?period=${period}`);
        return res.data;
    }

    async getRecentActivities() {
        const res = await this.api.get('/dashboard/recent-activities');
        return res.data;
    }

    async getOrderDistribution(period = 7) {
        const res = await this.api.get(`/dashboard/order-distribution?period=${period}`);
        return res.data;
    }

    // Vendors
    async getVendors(params: Record<string, unknown> = {}) {
        const res = await this.api.get('/vendors', { params });
        return res.data;
    }

    async getVendorById(id: string) {
        const res = await this.api.get(`/vendors/${id}`);
        return res.data;
    }

    async createVendor(data: Record<string, unknown>) {
        const res = await this.api.post('/vendors', data);
        return res.data;
    }

    async updateVendor(id: string, data: Record<string, unknown>) {
        const res = await this.api.put(`/vendors/${id}`, data);
        return res.data;
    }

    async deleteVendor(id: string) {
        const res = await this.api.delete(`/vendors/${id}`);
        return res.data;
    }

    async getVendorStats(id: string, period = 30) {
        const res = await this.api.get(`/vendors/${id}/stats?period=${period}`);
        return res.data;
    }

    // Customers
    async getCustomers(params: Record<string, unknown> = {}) {
        const res = await this.api.get('/customers', { params });
        return res.data;
    }

    async getCustomerById(id: string) {
        const res = await this.api.get(`/customers/${id}`);
        return res.data;
    }

    async createCustomer(data: Record<string, unknown>) {
        const res = await this.api.post('/customers', data);
        return res.data;
    }

    async updateCustomer(id: string, data: Record<string, unknown>) {
        const res = await this.api.put(`/customers/${id}`, data);
        return res.data;
    }

    async getCustomerAnalytics(id: string, period = 30) {
        const res = await this.api.get(`/customers/${id}/analytics?period=${period}`);
        return res.data;
    }

    // Orders
    async getOrders(params: Record<string, unknown> = {}) {
        const res = await this.api.get('/orders', { params });
        return res.data;
    }

    async getOrderById(id: string) {
        const res = await this.api.get(`/orders/${id}`);
        return res.data;
    }

    async updateOrderStatus(id: string, status: string, notes?: string, cancellation_reason?: string) {
        const res = await this.api.put(`/orders/${id}/status`, { status, notes, cancellation_reason });
        return res.data;
    }

    async updatePaymentStatus(id: string, payment_status: string) {
        const res = await this.api.put(`/orders/${id}/payment`, { payment_status });
        return res.data;
    }

    async createPaymentIntent(order_id: string, provider: 'razorpay' | 'cashfree' = 'razorpay') {
        const res = await this.api.post('/payments/create-intent', { order_id, provider });
        return res.data;
    }

    async recordCashCollection(order_id: string, amount: number, payment_method = 'cash', notes?: string) {
        const res = await this.api.post('/payments/cash-collect', {
            order_id,
            amount,
            payment_method,
            notes,
        });
        return res.data;
    }

    async assignOrder(id: string, vendor_id: string) {
        const res = await this.api.put(`/orders/${id}/assign`, { vendor_id });
        return res.data;
    }

    async createOrder(data: Record<string, unknown>) {
        const res = await this.api.post('/orders', data);
        return res.data;
    }

    async getTodayOrders() {
        const res = await this.api.get('/orders/today/all');
        return res.data;
    }

    // WhatsApp
    async getWhatsAppConfig() {
        const res = await this.api.get('/whatsapp/config');
        return res.data;
    }

    async getWhatsAppMessages(params: Record<string, unknown> = {}) {
        const res = await this.api.get('/whatsapp/messages', { params });
        return res.data;
    }

    async getWhatsAppOrders(params: Record<string, unknown> = {}) {
        const res = await this.api.get('/whatsapp/orders', { params });
        return res.data;
    }

    async sendWhatsAppMessage(to: string, message: string) {
        const res = await this.api.post('/whatsapp/send', { to, message });
        return res.data;
    }

    // Commissions
    async getCommissions(params: Record<string, unknown> = {}) {
        const res = await this.api.get('/commissions', { params });
        return res.data;
    }

    async getCommissionStats(period = 30) {
        const res = await this.api.get(`/commissions/stats?period=${period}`);
        return res.data;
    }

    async getVendorCommissionBreakdown(period = 30) {
        const res = await this.api.get(`/commissions/vendor-breakdown?period=${period}`);
        return res.data;
    }

    async createCommission(data: Record<string, unknown>) {
        const res = await this.api.post('/commissions', data);
        return res.data;
    }

    async updateCommissionStatus(id: string, status: string) {
        const res = await this.api.put(`/commissions/${id}/status`, { status });
        return res.data;
    }

    async bulkUpdateCommissionStatus(ids: string[], status: string) {
        const res = await this.api.put('/commissions/bulk-status', { commission_ids: ids, status });
        return res.data;
    }

    async getCommissionTrends(period = 30) {
        const res = await this.api.get(`/commissions/trends?period=${period}`);
        return res.data;
    }

    async runPayoutBatch(settlement_date?: string) {
        const res = await this.api.post('/payouts/run', settlement_date ? { settlement_date } : {});
        return res.data;
    }

    async getPayoutBatches(params: Record<string, unknown> = {}) {
        const res = await this.api.get('/payouts', { params });
        return res.data;
    }

    // Settings
    async getSettings() {
        const res = await this.api.get('/settings');
        return res.data;
    }

    async updateSettings(settings: Record<string, string>) {
        const res = await this.api.put('/settings', { settings });
        return res.data;
    }
}

export const apiService = new ApiService();
export default apiService;
