'use client';
import React, { useEffect, useState } from 'react';
import { IndianRupee, Pencil, Phone, Plus, ShoppingCart, TrendingUp, Users, Eye } from 'lucide-react';
import { useDispatch, useSelector } from 'react-redux';
import { RootState, AppDispatch } from '@/store';
import { fetchCustomers } from '@/store/customerSlice';
import { Customer } from '@/types';
import PortalPageHeader from '@/components/portal/PortalPageHeader';
import StatusChip, { statusToVariant } from '@/components/portal/StatusChip';
import { Button, Card, Input, Modal, Pagination } from '@/components/portal/ui';

const Customers: React.FC = () => {
  const dispatch = useDispatch<AppDispatch>();
  const { customers, pagination, isLoading, error } = useSelector((state: RootState) => state.customers);

  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);
  const [searchTerm, setSearchTerm] = useState('');
  const [addDialogOpen, setAddDialogOpen] = useState(false);
  const [viewDialogOpen, setViewDialogOpen] = useState(false);
  const [selectedCustomer, setSelectedCustomer] = useState<Customer | null>(null);
  const [formData, setFormData] = useState({
    name: '',
    phone: '',
    address: '',
    flat_number: '',
    floor: '',
    building_name: '',
  });

  useEffect(() => {
    dispatch(fetchCustomers({
      page: page + 1,
      limit: rowsPerPage,
      search: searchTerm || undefined,
    }));
  }, [dispatch, page, rowsPerPage, searchTerm]);

  const handleAddCustomer = () => {
    setAddDialogOpen(true);
    setFormData({
      name: '',
      phone: '',
      address: '',
      flat_number: '',
      floor: '',
      building_name: '',
    });
  };

  const handleViewCustomer = (customer: Customer) => {
    setSelectedCustomer(customer);
    setViewDialogOpen(true);
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
    });
  };

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-IN', {
      style: 'currency',
      currency: 'INR',
      minimumFractionDigits: 0,
    }).format(amount);
  };

  const formatAddress = (customer: Customer) => {
    const parts = [];
    if (customer.flat_number) parts.push(customer.flat_number);
    if (customer.floor) parts.push(`Floor ${customer.floor}`);
    if (customer.building_name) parts.push(customer.building_name);
    if (customer.address) parts.push(customer.address);
    return parts.join(', ') || 'No address';
  };

  if (error) {
    return (
      <div>
        <PortalPageHeader title="Customers Management" />
        <div className="rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">{error}</div>
      </div>
    );
  }

  const totalSpent = customers.reduce((sum, customer) => sum + (customer.stats?.totalSpent || 0), 0);
  const totalOrders = customers.reduce((sum, customer) => sum + (customer.stats?.totalOrders || 0), 0);
  const avgOrderValue = totalOrders > 0 ? totalSpent / customers.reduce((sum, customer) => sum + (customer.stats?.completedOrders || 0), 1) : 0;

  return (
    <div>
      <PortalPageHeader title="Customers Management" subtitle="Manage your water can delivery customers" />

      {/* Stats Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        <Card className="p-5 flex items-center justify-between hover:shadow-md transition-shadow">
          <div>
            <p className="text-sm font-medium text-slate-500 mb-1">Total Customers</p>
            <p className="text-xl font-bold text-slate-900">{pagination.total}</p>
          </div>
          <div className="w-12 h-12 rounded-xl bg-blue-100 flex items-center justify-center text-blue-600">
            <Users className="w-6 h-6" />
          </div>
        </Card>
        <Card className="p-5 flex items-center justify-between hover:shadow-md transition-shadow">
          <div>
            <p className="text-sm font-medium text-slate-500 mb-1">Active Orders</p>
            <p className="text-xl font-bold text-slate-900">{customers.reduce((sum, customer) => sum + (customer.stats?.totalOrders || 0), 0)}</p>
          </div>
          <div className="w-12 h-12 rounded-xl bg-green-100 flex items-center justify-center text-green-600">
            <ShoppingCart className="w-6 h-6" />
          </div>
        </Card>
        <Card className="p-5 flex items-center justify-between hover:shadow-md transition-shadow">
          <div>
            <p className="text-sm font-medium text-slate-500 mb-1">Total Spent</p>
            <p className="text-xl font-bold text-slate-900">{formatCurrency(totalSpent)}</p>
          </div>
          <div className="w-12 h-12 rounded-xl bg-amber-100 flex items-center justify-center text-amber-600">
            <IndianRupee className="w-6 h-6" />
          </div>
        </Card>
        <Card className="p-5 flex items-center justify-between hover:shadow-md transition-shadow">
          <div>
            <p className="text-sm font-medium text-slate-500 mb-1">Avg Order Value</p>
            <p className="text-xl font-bold text-slate-900">{formatCurrency(avgOrderValue)}</p>
          </div>
          <div className="w-12 h-12 rounded-xl bg-sky-100 flex items-center justify-center text-sky-600">
            <TrendingUp className="w-6 h-6" />
          </div>
        </Card>
      </div>

      {/* Filters */}
      <Card className="p-4 mb-4">
        <div className="grid grid-cols-1 md:grid-cols-12 gap-3 items-end">
          <div className="md:col-span-8">
            <Input
              label="Search"
              value={searchTerm}
              onChange={(v) => {
                setSearchTerm(v);
                setPage(0);
              }}
              placeholder="Search customers by name, phone, or address..."
            />
          </div>
          <div className="md:col-span-4 flex justify-end">
            <Button onClick={handleAddCustomer} className="gap-2">
              <Plus className="w-4 h-4" />
              Add Customer
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
                <th className="text-left font-semibold px-4 py-3">Customer</th>
                <th className="text-left font-semibold px-4 py-3">Contact</th>
                <th className="text-left font-semibold px-4 py-3">Address</th>
                <th className="text-left font-semibold px-4 py-3">Orders</th>
                <th className="text-left font-semibold px-4 py-3">Total Spent</th>
                <th className="text-left font-semibold px-4 py-3">Last Order</th>
                <th className="text-left font-semibold px-4 py-3">Joined</th>
                <th className="text-right font-semibold px-4 py-3">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {isLoading ? (
                <tr>
                  <td className="px-4 py-8 text-slate-500 text-center" colSpan={8}>
                    Loading…
                  </td>
                </tr>
              ) : customers.length === 0 ? (
                <tr>
                  <td className="px-4 py-8 text-slate-500 text-center" colSpan={8}>
                    No customers found
                  </td>
                </tr>
              ) : (
                customers.map((customer) => (
                  <tr key={customer.id} className="hover:bg-slate-50/60">
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-xl bg-blue-100 text-blue-700 flex items-center justify-center">
                          <Users className="w-5 h-5" />
                        </div>
                        <div>
                          <p className="font-semibold text-slate-900">{customer.name}</p>
                          <p className="text-xs text-slate-500 font-mono">ID: {customer.id.slice(0, 8)}…</p>
                        </div>
                      </div>
                    </td>
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-2 text-slate-700">
                        <Phone className="w-4 h-4 text-slate-400" />
                        <span className="font-medium">{customer.phone}</span>
                      </div>
                    </td>
                    <td className="px-4 py-3">
                      <span className="text-slate-600 line-clamp-2" title={formatAddress(customer)}>
                        {formatAddress(customer)}
                      </span>
                    </td>
                    <td className="px-4 py-3">
                      <div className="font-semibold text-slate-900">{customer.stats?.totalOrders || 0}</div>
                      <div className="text-xs text-slate-500">{customer.stats?.completedOrders || 0} completed</div>
                    </td>
                    <td className="px-4 py-3 font-semibold text-slate-900">
                      {formatCurrency(customer.stats?.totalSpent || 0)}
                    </td>
                    <td className="px-4 py-3 text-slate-700">
                      {customer.stats?.lastOrderDate ? formatDate(customer.stats.lastOrderDate) : 'No orders'}
                    </td>
                    <td className="px-4 py-3 text-slate-700">{formatDate(customer.created_at)}</td>
                    <td className="px-4 py-3 text-right">
                      <button
                        type="button"
                        onClick={() => handleViewCustomer(customer)}
                        className="inline-flex items-center justify-center p-2 rounded-lg text-slate-600 hover:bg-slate-100 hover:text-slate-900"
                        aria-label="View details"
                        title="View Details"
                      >
                        <Eye className="w-4 h-4" />
                      </button>
                      <button
                        type="button"
                        className="inline-flex items-center justify-center p-2 rounded-lg text-slate-600 hover:bg-slate-100 hover:text-slate-900"
                        aria-label="Edit customer"
                        title="Edit"
                      >
                        <Pencil className="w-4 h-4" />
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

      {/* Add Customer Dialog */}
      <Modal
        open={addDialogOpen}
        title="Add New Customer"
        onClose={() => setAddDialogOpen(false)}
        footer={
          <>
            <Button variant="ghost" onClick={() => setAddDialogOpen(false)}>
              Cancel
            </Button>
            <Button onClick={() => setAddDialogOpen(false)}>Add Customer</Button>
          </>
        }
      >
        <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
          <Input
            label="Full Name"
            value={formData.name}
            onChange={(v) => setFormData({ ...formData, name: v })}
          />
          <Input
            label="Phone Number"
            value={formData.phone}
            onChange={(v) => setFormData({ ...formData, phone: v })}
          />
          <label className="block md:col-span-2">
            <span className="block text-sm font-medium text-slate-700 mb-1">Street Address</span>
            <textarea
              value={formData.address}
              onChange={(e) => setFormData({ ...formData, address: e.target.value })}
              rows={2}
              className="w-full rounded-xl border border-slate-200 bg-white px-4 py-3 text-slate-900 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-cancan-primary/30"
            />
          </label>
          <Input
            label="Flat/Door Number"
            value={formData.flat_number}
            onChange={(v) => setFormData({ ...formData, flat_number: v })}
          />
          <Input label="Floor" value={formData.floor} onChange={(v) => setFormData({ ...formData, floor: v })} />
          <div className="md:col-span-2">
            <Input
              label="Building Name"
              value={formData.building_name}
              onChange={(v) => setFormData({ ...formData, building_name: v })}
            />
          </div>
        </div>
      </Modal>

      {/* View Customer Dialog */}
      <Modal
        open={viewDialogOpen}
        title="Customer Details"
        onClose={() => setViewDialogOpen(false)}
        maxWidthClassName="max-w-3xl"
        footer={
          <Button variant="ghost" onClick={() => setViewDialogOpen(false)}>
            Close
          </Button>
        }
      >
        {selectedCustomer ? (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <Card className="p-4 bg-slate-50 border-slate-200">
              <h3 className="text-sm font-semibold text-slate-900 mb-3">Personal Information</h3>
              <div className="space-y-2 text-sm text-slate-800">
                <div>
                  <span className="font-semibold">Name:</span> {selectedCustomer.name}
                </div>
                <div>
                  <span className="font-semibold">Phone:</span> {selectedCustomer.phone}
                </div>
                <div className="flex items-center gap-2">
                  <span className="font-semibold">Status:</span>
                  <StatusChip
                    label={(selectedCustomer.status || 'Active').replace(/\b\w/g, (l) => l.toUpperCase())}
                    variant={statusToVariant(selectedCustomer.status || 'active')}
                  />
                </div>
                <div>
                  <span className="font-semibold">Customer ID:</span> {selectedCustomer.id}
                </div>
                <div>
                  <span className="font-semibold">Joined:</span> {formatDate(selectedCustomer.created_at)}
                </div>
              </div>
            </Card>

            <Card className="p-4 bg-slate-50 border-slate-200">
              <h3 className="text-sm font-semibold text-slate-900 mb-3">Address Information</h3>
              <div className="space-y-2 text-sm text-slate-800">
                <div>
                  <span className="font-semibold">Building:</span> {selectedCustomer.building_name || '-'}
                </div>
                <div>
                  <span className="font-semibold">Flat/Door:</span> {selectedCustomer.flat_number || '-'}
                </div>
                <div>
                  <span className="font-semibold">Floor:</span> {selectedCustomer.floor || '-'}
                </div>
                <div>
                  <span className="font-semibold">Street:</span> {selectedCustomer.address}
                </div>
              </div>
            </Card>

            <Card className="p-4 bg-slate-50 border-slate-200 md:col-span-2">
              <h3 className="text-sm font-semibold text-slate-900 mb-3">Order Statistics</h3>
              <div className="grid grid-cols-2 md:grid-cols-4 gap-3 text-sm text-slate-800">
                <div>
                  <div className="text-slate-500">Total Orders</div>
                  <div className="font-semibold">{selectedCustomer.stats?.totalOrders || 0}</div>
                </div>
                <div>
                  <div className="text-slate-500">Completed</div>
                  <div className="font-semibold">{selectedCustomer.stats?.completedOrders || 0}</div>
                </div>
                <div>
                  <div className="text-slate-500">Total Spent</div>
                  <div className="font-semibold">{formatCurrency(selectedCustomer.stats?.totalSpent || 0)}</div>
                </div>
                <div>
                  <div className="text-slate-500">Last Order</div>
                  <div className="font-semibold">
                    {selectedCustomer.stats?.lastOrderDate ? formatDate(selectedCustomer.stats.lastOrderDate) : 'Never'}
                  </div>
                </div>
              </div>
            </Card>
          </div>
        ) : null}
      </Modal>
    </div>
  );
};

export default Customers;

