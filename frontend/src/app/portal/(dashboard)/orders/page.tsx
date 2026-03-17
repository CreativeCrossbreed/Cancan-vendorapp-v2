'use client';

import React, { useEffect, useState } from 'react';
import {
  CheckCircle,
  Clock,
  CreditCard,
  Eye,
  MoreVertical,
  Package,
  Plus,
  Store,
  Truck,
  User,
  XCircle,
} from 'lucide-react';
import { useDispatch, useSelector } from 'react-redux';
import { RootState, AppDispatch } from '@/store';
import { fetchOrders } from '@/store/orderSlice';
import { Order } from '@/types';
import PortalPageHeader from '@/components/portal/PortalPageHeader';
import StatusChip, { statusToVariant } from '@/components/portal/StatusChip';
import { Button, Card, Input, Modal, Pagination, Select } from '@/components/portal/ui';

const Orders: React.FC = () => {
  const dispatch = useDispatch<AppDispatch>();
  const { orders, pagination, isLoading, error } = useSelector((state: RootState) => state.orders);

  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [paymentFilter, setPaymentFilter] = useState('all');
  const [viewDialogOpen, setViewDialogOpen] = useState(false);
  const [selectedOrder, setSelectedOrder] = useState<Order | null>(null);
  const [actionMenuAnchor, setActionMenuAnchor] = useState<null | HTMLElement>(null);
  const [selectedOrderForAction, setSelectedOrderForAction] = useState<Order | null>(null);
  const [statusDialogOpen, setStatusDialogOpen] = useState(false);
  const [selectedStatus, setSelectedStatus] = useState('');
  const [statusNotes, setStatusNotes] = useState('');

  useEffect(() => {
    dispatch(
      fetchOrders({
        page: page + 1,
        limit: rowsPerPage,
        search: searchTerm || undefined,
        status: statusFilter !== 'all' ? statusFilter : undefined,
        payment_status: paymentFilter !== 'all' ? paymentFilter : undefined,
      }),
    );
  }, [dispatch, page, rowsPerPage, searchTerm, statusFilter, paymentFilter]);

  const handleActionMenuOpen = (event: React.MouseEvent<HTMLElement>, order: Order) => {
    setActionMenuAnchor(event.currentTarget);
    setSelectedOrderForAction(order);
  };

  const handleActionMenuClose = () => {
    setActionMenuAnchor(null);
    setSelectedOrderForAction(null);
  };

  const handleStatusChange = (status: string) => {
    setSelectedStatus(status);
    setStatusDialogOpen(true);
    handleActionMenuClose();
  };

  const handleViewOrder = (order: Order) => {
    setSelectedOrder(order);
    setViewDialogOpen(true);
    handleActionMenuClose();
  };

  const formatDate = (dateString: string) =>
    new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });

  const formatCurrency = (amount: number) =>
    new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR', minimumFractionDigits: 0 }).format(amount);

  const todayOrders = orders.filter((order) => new Date(order.created_at).toDateString() === new Date().toDateString());
  const pendingOrders = orders.filter((order) => order.status === 'pending');
  const deliveredOrders = orders.filter((order) => order.status === 'completed');
  const todayRevenue = todayOrders.reduce((sum, order) => sum + (order.total_amount || 0), 0);

  if (error) {
    return (
      <div>
        <PortalPageHeader title="Orders Management" />
        <div className="rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">{error}</div>
      </div>
    );
  }

  return (
    <div>
      <PortalPageHeader title="Orders Management" subtitle="Manage and track all water can delivery orders" />

      {/* Stats Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        <Card className="p-5 flex items-center justify-between hover:shadow-md transition-shadow">
          <div>
            <p className="text-sm font-medium text-slate-500 mb-1">Today&apos;s Orders</p>
            <p className="text-xl font-bold text-slate-900">{todayOrders.length}</p>
          </div>
          <div className="w-12 h-12 rounded-xl bg-blue-100 flex items-center justify-center text-blue-600">
            <Package className="w-6 h-6" />
          </div>
        </Card>
        <Card className="p-5 flex items-center justify-between hover:shadow-md transition-shadow">
          <div>
            <p className="text-sm font-medium text-slate-500 mb-1">Pending Orders</p>
            <p className="text-xl font-bold text-slate-900">{pendingOrders.length}</p>
          </div>
          <div className="w-12 h-12 rounded-xl bg-amber-100 flex items-center justify-center text-amber-600">
            <Clock className="w-6 h-6" />
          </div>
        </Card>
        <Card className="p-5 flex items-center justify-between hover:shadow-md transition-shadow">
          <div>
            <p className="text-sm font-medium text-slate-500 mb-1">Delivered Today</p>
            <p className="text-xl font-bold text-slate-900">{deliveredOrders.length}</p>
          </div>
          <div className="w-12 h-12 rounded-xl bg-green-100 flex items-center justify-center text-green-600">
            <CheckCircle className="w-6 h-6" />
          </div>
        </Card>
        <Card className="p-5 flex items-center justify-between hover:shadow-md transition-shadow">
          <div>
            <p className="text-sm font-medium text-slate-500 mb-1">Today&apos;s Revenue</p>
            <p className="text-xl font-bold text-slate-900">{formatCurrency(todayRevenue)}</p>
          </div>
          <div className="w-12 h-12 rounded-xl bg-sky-100 flex items-center justify-center text-sky-600">
            <CreditCard className="w-6 h-6" />
          </div>
        </Card>
      </div>

      {/* Filters */}
      <Card className="p-4 mb-4">
        <div className="grid grid-cols-1 md:grid-cols-12 gap-3 items-end">
          <div className="md:col-span-3">
            <Input
              label="Search"
              value={searchTerm}
              onChange={(v) => {
                setSearchTerm(v);
                setPage(0);
              }}
              placeholder="Order #, Customer, Vendor"
            />
          </div>
          <div className="md:col-span-2">
            <Select
              label="Status"
              value={statusFilter}
              onChange={(v) => {
                setStatusFilter(v);
                setPage(0);
              }}
              options={[
                { value: 'all', label: 'All Status' },
                { value: 'pending', label: 'Pending' },
                { value: 'confirmed', label: 'Confirmed' },
                { value: 'assigned', label: 'Assigned' },
                { value: 'picked_up', label: 'Picked Up' },
                { value: 'delivered', label: 'Delivered' },
                { value: 'cancelled', label: 'Cancelled' },
              ]}
            />
          </div>
          <div className="md:col-span-2">
            <Select
              label="Payment"
              value={paymentFilter}
              onChange={(v) => {
                setPaymentFilter(v);
                setPage(0);
              }}
              options={[
                { value: 'all', label: 'All Payment' },
                { value: 'paid', label: 'Paid' },
                { value: 'unpaid', label: 'Unpaid' },
                { value: 'refunded', label: 'Refunded' },
              ]}
            />
          </div>
          <div className="md:col-span-5 flex justify-end">
            <Button className="gap-2">
              <Plus className="w-4 h-4" />
              Create Order
            </Button>
          </div>
        </div>
      </Card>

      {/* Table */}
      <Card className="overflow-hidden">
        <div className="overflow-x-auto">
          <table className="min-w-full text-sm">
            <thead className="bg-slate-50 text-slate-600">
              <tr>
                <th className="text-left font-semibold px-4 py-3">Order #</th>
                <th className="text-left font-semibold px-4 py-3">Customer</th>
                <th className="text-left font-semibold px-4 py-3">Vendor</th>
                <th className="text-left font-semibold px-4 py-3">Delivery Date</th>
                <th className="text-left font-semibold px-4 py-3">Time Slot</th>
                <th className="text-left font-semibold px-4 py-3">Amount</th>
                <th className="text-left font-semibold px-4 py-3">Status</th>
                <th className="text-left font-semibold px-4 py-3">Payment</th>
                <th className="text-left font-semibold px-4 py-3">Created</th>
                <th className="text-right font-semibold px-4 py-3">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {isLoading ? (
                <tr>
                  <td className="px-4 py-8 text-slate-500 text-center" colSpan={10}>
                    Loading…
                  </td>
                </tr>
              ) : orders.length === 0 ? (
                <tr>
                  <td className="px-4 py-8 text-slate-500 text-center" colSpan={10}>
                    No orders found
                  </td>
                </tr>
              ) : (
                orders.map((order) => (
                  <tr key={order.id} className="hover:bg-slate-50/60">
                    <td className="px-4 py-3 font-semibold text-blue-700">#{order.order_number}</td>
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-2">
                        <User className="w-4 h-4 text-slate-400" />
                        <div>
                          <p className="font-medium text-slate-900">{order.customer?.name || 'Customer'}</p>
                          <p className="text-xs text-slate-500">{order.customer?.phone || 'N/A'}</p>
                        </div>
                      </div>
                    </td>
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-2">
                        <Store className="w-4 h-4 text-slate-400" />
                        <span className="font-medium text-slate-900">{order.vendor?.name || 'Unassigned'}</span>
                      </div>
                    </td>
                    <td className="px-4 py-3 text-slate-700">
                      {new Date(order.delivery_date).toLocaleDateString()}
                    </td>
                    <td className="px-4 py-3 text-slate-700">{order.time_slot}</td>
                    <td className="px-4 py-3 font-semibold text-slate-900">{formatCurrency(order.total_amount)}</td>
                    <td className="px-4 py-3">
                      <StatusChip
                        label={order.status.replace('_', ' ').replace(/\b\w/g, (l) => l.toUpperCase())}
                        variant={statusToVariant(order.status)}
                      />
                    </td>
                    <td className="px-4 py-3">
                      <StatusChip
                        label={order.payment_status.replace(/\b\w/g, (l) => l.toUpperCase())}
                        variant={statusToVariant(order.payment_status)}
                      />
                    </td>
                    <td className="px-4 py-3 text-slate-700">{formatDate(order.created_at)}</td>
                    <td className="px-4 py-3 text-right">
                      <button
                        type="button"
                        onClick={(e) => handleActionMenuOpen(e, order)}
                        className="inline-flex items-center justify-center p-2 rounded-lg text-slate-600 hover:bg-slate-100 hover:text-slate-900"
                        aria-label="Actions"
                      >
                        <MoreVertical className="w-4 h-4" />
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
        <Pagination
          count={pagination.total}
          page={page}
          rowsPerPage={rowsPerPage}
          rowsPerPageOptions={[5, 10, 25, 50]}
          onPageChange={setPage}
          onRowsPerPageChange={(n) => {
            setRowsPerPage(n);
            setPage(0);
          }}
        />
      </Card>

      {/* Action Menu */}
      {actionMenuAnchor && (
        <>
          <button
            type="button"
            className="fixed inset-0 z-40"
            onClick={handleActionMenuClose}
            aria-label="Close menu"
          />
          <div
            className="fixed z-50 min-w-[180px] rounded-xl border border-slate-200 bg-white shadow-lg py-1"
            style={{
              top: actionMenuAnchor.getBoundingClientRect().bottom + 4,
              left: actionMenuAnchor.getBoundingClientRect().left,
            }}
          >
            <button
              type="button"
              className="w-full flex items-center gap-2 px-3 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50 text-left"
              onClick={() => selectedOrderForAction && handleViewOrder(selectedOrderForAction)}
            >
              <Eye className="w-4 h-4" />
              View Details
            </button>
            <div className="border-t border-slate-100 my-1" />
            <button
              type="button"
              className="w-full flex items-center gap-2 px-3 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50 text-left"
              onClick={() => handleStatusChange('confirmed')}
            >
              <CheckCircle className="w-4 h-4 text-blue-600" />
              Confirm Order
            </button>
            <button
              type="button"
              className="w-full flex items-center gap-2 px-3 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50 text-left"
              onClick={() => handleStatusChange('assigned')}
            >
              <Truck className="w-4 h-4 text-violet-600" />
              Assign to Vendor
            </button>
            <button
              type="button"
              className="w-full flex items-center gap-2 px-3 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50 text-left"
              onClick={() => handleStatusChange('delivered')}
            >
              <CheckCircle className="w-4 h-4 text-green-600" />
              Mark Delivered
            </button>
            <div className="border-t border-slate-100 my-1" />
            <button
              type="button"
              className="w-full flex items-center gap-2 px-3 py-2 text-sm font-medium text-red-600 hover:bg-red-50 text-left"
              onClick={() => handleStatusChange('cancelled')}
            >
              <XCircle className="w-4 h-4" />
              Cancel Order
            </button>
          </div>
        </>
      )}

      {/* Order Details Modal */}
      <Modal
        open={viewDialogOpen}
        title="Order Details"
        onClose={() => setViewDialogOpen(false)}
        maxWidthClassName="max-w-3xl"
        footer={
          <Button variant="ghost" onClick={() => setViewDialogOpen(false)}>
            Close
          </Button>
        }
      >
        {selectedOrder ? (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <Card className="p-4 bg-slate-50 border-slate-200">
              <h3 className="text-sm font-semibold text-slate-900 mb-3">Order Information</h3>
              <div className="space-y-2 text-sm text-slate-800">
                <div>
                  <span className="font-semibold">Order #:</span> #{selectedOrder.order_number}
                </div>
                <div className="flex items-center gap-2">
                  <span className="font-semibold">Status:</span>
                  <StatusChip
                    label={selectedOrder.status.replace('_', ' ').replace(/\b\w/g, (l) => l.toUpperCase())}
                    variant={statusToVariant(selectedOrder.status)}
                  />
                </div>
                <div className="flex items-center gap-2">
                  <span className="font-semibold">Payment Status:</span>
                  <StatusChip
                    label={selectedOrder.payment_status.replace(/\b\w/g, (l) => l.toUpperCase())}
                    variant={statusToVariant(selectedOrder.payment_status)}
                  />
                </div>
                <div>
                  <span className="font-semibold">Total Amount:</span> {formatCurrency(selectedOrder.total_amount)}
                </div>
                <div>
                  <span className="font-semibold">Created:</span> {formatDate(selectedOrder.created_at)}
                </div>
              </div>
            </Card>

            <Card className="p-4 bg-slate-50 border-slate-200">
              <h3 className="text-sm font-semibold text-slate-900 mb-3">Delivery Information</h3>
              <div className="space-y-2 text-sm text-slate-800">
                <div>
                  <span className="font-semibold">Delivery Date:</span>{' '}
                  {new Date(selectedOrder.delivery_date).toLocaleDateString()}
                </div>
                <div>
                  <span className="font-semibold">Time Slot:</span> {selectedOrder.time_slot}
                </div>
                <div>
                  <span className="font-semibold">Is Delivered:</span> {selectedOrder.is_delivered ? 'Yes' : 'No'}
                </div>
                {selectedOrder.delivered_at && (
                  <div>
                    <span className="font-semibold">Delivered At:</span> {formatDate(selectedOrder.delivered_at)}
                  </div>
                )}
                {selectedOrder.payment_marked_at && (
                  <div>
                    <span className="font-semibold">Payment Marked:</span>{' '}
                    {formatDate(selectedOrder.payment_marked_at)}
                  </div>
                )}
              </div>
            </Card>

            <Card className="p-4 bg-slate-50 border-slate-200">
              <h3 className="text-sm font-semibold text-slate-900 mb-3">Customer Information</h3>
              <div className="space-y-2 text-sm text-slate-800">
                <div>
                  <span className="font-semibold">Name:</span> {selectedOrder.customer?.name || 'N/A'}
                </div>
                <div>
                  <span className="font-semibold">Phone:</span> {selectedOrder.customer?.phone || 'N/A'}
                </div>
                <div>
                  <span className="font-semibold">Address:</span> {selectedOrder.customer?.address || 'N/A'}
                </div>
              </div>
            </Card>

            <Card className="p-4 bg-slate-50 border-slate-200">
              <h3 className="text-sm font-semibold text-slate-900 mb-3">Vendor Information</h3>
              <div className="space-y-2 text-sm text-slate-800">
                <div>
                  <span className="font-semibold">Name:</span> {selectedOrder.vendor?.name || 'Unassigned'}
                </div>
                <div>
                  <span className="font-semibold">Phone:</span> N/A
                </div>
                <div>
                  <span className="font-semibold">Business:</span> {selectedOrder.vendor?.business_name || 'N/A'}
                </div>
              </div>
            </Card>
          </div>
        ) : null}
      </Modal>

      {/* Status Change Modal */}
      <Modal
        open={statusDialogOpen}
        title="Change Order Status"
        onClose={() => setStatusDialogOpen(false)}
        footer={
          <>
            <Button variant="ghost" onClick={() => setStatusDialogOpen(false)}>
              Cancel
            </Button>
            <Button
              onClick={() => {
                setStatusDialogOpen(false);
                setStatusNotes('');
              }}
            >
              Update Status
            </Button>
          </>
        }
      >
        <p className="text-sm text-slate-700 mb-3">
          Change order #{selectedOrderForAction?.order_number} status to{' '}
          <strong>{selectedStatus.replace(/\b\w/g, (l) => l.toUpperCase())}</strong>
        </p>
        <label className="block">
          <span className="block text-sm font-medium text-slate-700 mb-1">Notes (optional)</span>
          <textarea
            value={statusNotes}
            onChange={(e) => setStatusNotes(e.target.value)}
            rows={3}
            className="w-full rounded-xl border border-slate-200 bg-white px-4 py-3 text-slate-900 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-cancan-primary/30"
          />
        </label>
      </Modal>
    </div>
  );
};

export default Orders;
