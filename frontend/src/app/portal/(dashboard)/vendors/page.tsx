'use client';

import React, { useEffect, useState } from 'react';
import {
  Ban,
  Eye,
  Pencil,
  Plus,
  Store,
  Trash2,
  TrendingDown,
  UserCheck,
} from 'lucide-react';
import { useDispatch, useSelector } from 'react-redux';
import { RootState, AppDispatch } from '@/store';
import { fetchVendors } from '@/store/vendorSlice';
import { Vendor } from '@/types';
import PortalPageHeader from '@/components/portal/PortalPageHeader';
import StatusChip, { statusToVariant } from '@/components/portal/StatusChip';
import { Button, Card, Input, Modal, Pagination, Select } from '@/components/portal/ui';

const Vendors: React.FC = () => {
  const dispatch = useDispatch<AppDispatch>();
  const { vendors, pagination, isLoading, error } = useSelector((state: RootState) => state.vendors);

  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [addDialogOpen, setAddDialogOpen] = useState(false);
  const [editDialogOpen, setEditDialogOpen] = useState(false);
  const [viewDialogOpen, setViewDialogOpen] = useState(false);
  const [selectedVendor, setSelectedVendor] = useState<Vendor | null>(null);
  const [formData, setFormData] = useState({
    phone: '',
    name: '',
    business_name: '',
    address: '',
    commission_rate: 10,
    status: 'active' as 'active' | 'inactive' | 'suspended',
  });

  useEffect(() => {
    dispatch(
      fetchVendors({
        page: page + 1,
        limit: rowsPerPage,
        search: searchTerm || undefined,
        status: statusFilter !== 'all' ? statusFilter : undefined,
      }),
    );
  }, [dispatch, page, rowsPerPage, searchTerm, statusFilter]);

  const handleAddVendor = () => {
    setAddDialogOpen(true);
    setFormData({
      phone: '',
      name: '',
      business_name: '',
      address: '',
      commission_rate: 10,
      status: 'active',
    });
  };

  const handleEditVendor = (vendor: Vendor) => {
    setFormData({
      phone: vendor.phone,
      name: vendor.name,
      business_name: vendor.business_name || '',
      address: vendor.address || '',
      commission_rate: vendor.commission_rate || 10,
      status: vendor.status,
    });
    setEditDialogOpen(true);
  };

  const handleViewVendor = (vendor: Vendor) => {
    setSelectedVendor(vendor);
    setViewDialogOpen(true);
  };

  const formatDate = (dateString: string) =>
    new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
    });

  const formatCurrency = (amount: number) =>
    new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR', minimumFractionDigits: 0 }).format(amount);

  const activeCount = vendors.filter((v) => v.status === 'active').length;
  const inactiveCount = vendors.filter((v) => v.status === 'inactive').length;
  const suspendedCount = vendors.filter((v) => v.status === 'suspended').length;

  if (error) {
    return (
      <div>
        <PortalPageHeader title="Vendors Management" />
        <div className="rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">{error}</div>
      </div>
    );
  }

  const formFields = (
    <>
      <Input
        label="Phone Number"
        value={formData.phone}
        onChange={(v) => setFormData({ ...formData, phone: v })}
      />
      <Input label="Name" value={formData.name} onChange={(v) => setFormData({ ...formData, name: v })} />
      <Input
        label="Business Name"
        value={formData.business_name}
        onChange={(v) => setFormData({ ...formData, business_name: v })}
      />
      <label className="block">
        <span className="block text-sm font-medium text-slate-700 mb-1">Address</span>
        <textarea
          value={formData.address}
          onChange={(e) => setFormData({ ...formData, address: e.target.value })}
          rows={2}
          className="w-full rounded-xl border border-slate-200 bg-white px-4 py-3 text-slate-900 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-cancan-primary/30"
        />
      </label>
      <Input
        label="Commission Rate (%)"
        type="number"
        value={String(formData.commission_rate)}
        onChange={(v) => setFormData({ ...formData, commission_rate: parseFloat(v) || 0 })}
      />
      <Select
        label="Status"
        value={formData.status}
        onChange={(v) => setFormData({ ...formData, status: v as 'active' | 'inactive' | 'suspended' })}
        options={[
          { value: 'active', label: 'Active' },
          { value: 'inactive', label: 'Inactive' },
          { value: 'suspended', label: 'Suspended' },
        ]}
      />
    </>
  );

  return (
    <div>
      <PortalPageHeader title="Vendors Management" subtitle="Manage your water can delivery vendors" />

      {/* Stats Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        <Card className="p-5 flex items-center justify-between hover:shadow-md transition-shadow">
          <div>
            <p className="text-sm font-medium text-slate-500 mb-1">Total Vendors</p>
            <p className="text-xl font-bold text-slate-900">{pagination.total}</p>
          </div>
          <div className="w-12 h-12 rounded-xl bg-blue-100 flex items-center justify-center text-blue-600">
            <Store className="w-6 h-6" />
          </div>
        </Card>
        <Card className="p-5 flex items-center justify-between hover:shadow-md transition-shadow">
          <div>
            <p className="text-sm font-medium text-slate-500 mb-1">Active Vendors</p>
            <p className="text-xl font-bold text-slate-900">{activeCount}</p>
          </div>
          <div className="w-12 h-12 rounded-xl bg-green-100 flex items-center justify-center text-green-600">
            <UserCheck className="w-6 h-6" />
          </div>
        </Card>
        <Card className="p-5 flex items-center justify-between hover:shadow-md transition-shadow">
          <div>
            <p className="text-sm font-medium text-slate-500 mb-1">Inactive</p>
            <p className="text-xl font-bold text-slate-900">{inactiveCount}</p>
          </div>
          <div className="w-12 h-12 rounded-xl bg-amber-100 flex items-center justify-center text-amber-600">
            <TrendingDown className="w-6 h-6" />
          </div>
        </Card>
        <Card className="p-5 flex items-center justify-between hover:shadow-md transition-shadow">
          <div>
            <p className="text-sm font-medium text-slate-500 mb-1">Suspended</p>
            <p className="text-xl font-bold text-slate-900">{suspendedCount}</p>
          </div>
          <div className="w-12 h-12 rounded-xl bg-red-100 flex items-center justify-center text-red-600">
            <Ban className="w-6 h-6" />
          </div>
        </Card>
      </div>

      {/* Filters */}
      <Card className="p-4 mb-4">
        <div className="grid grid-cols-1 md:grid-cols-12 gap-3 items-end">
          <div className="md:col-span-4">
            <Input
              label="Search"
              value={searchTerm}
              onChange={(v) => {
                setSearchTerm(v);
                setPage(0);
              }}
              placeholder="Name, phone, business..."
            />
          </div>
          <div className="md:col-span-3">
            <Select
              label="Status"
              value={statusFilter}
              onChange={(v) => {
                setStatusFilter(v);
                setPage(0);
              }}
              options={[
                { value: 'all', label: 'All Status' },
                { value: 'active', label: 'Active' },
                { value: 'inactive', label: 'Inactive' },
                { value: 'suspended', label: 'Suspended' },
              ]}
            />
          </div>
          <div className="md:col-span-5 flex justify-end">
            <Button onClick={handleAddVendor} className="gap-2">
              <Plus className="w-4 h-4" />
              Add Vendor
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
                <th className="text-left font-semibold px-4 py-3">Vendor</th>
                <th className="text-left font-semibold px-4 py-3">Business</th>
                <th className="text-left font-semibold px-4 py-3">Status</th>
                <th className="text-left font-semibold px-4 py-3">Commission</th>
                <th className="text-left font-semibold px-4 py-3">Orders</th>
                <th className="text-left font-semibold px-4 py-3">Revenue</th>
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
              ) : vendors.length === 0 ? (
                <tr>
                  <td className="px-4 py-8 text-slate-500 text-center" colSpan={8}>
                    No vendors found
                  </td>
                </tr>
              ) : (
                vendors.map((vendor) => (
                  <tr key={vendor.id} className="hover:bg-slate-50/60">
                    <td className="px-4 py-3">
                      <p className="font-semibold text-slate-900">{vendor.name}</p>
                      <p className="text-slate-500">{vendor.phone}</p>
                    </td>
                    <td className="px-4 py-3 font-medium text-slate-700">{vendor.business_name || '-'}</td>
                    <td className="px-4 py-3">
                      <StatusChip
                        label={vendor.status.replace(/\b\w/g, (l) => l.toUpperCase())}
                        variant={statusToVariant(vendor.status)}
                      />
                    </td>
                    <td className="px-4 py-3 font-semibold text-slate-900">{vendor.commission_rate}%</td>
                    <td className="px-4 py-3 text-slate-700">{vendor.stats?.totalOrders || 0}</td>
                    <td className="px-4 py-3 font-semibold text-slate-900">
                      {formatCurrency(vendor.stats?.totalRevenue || 0)}
                    </td>
                    <td className="px-4 py-3 text-slate-600">{formatDate(vendor.created_at)}</td>
                    <td className="px-4 py-3 text-right flex items-center justify-end gap-0">
                      <button
                        type="button"
                        onClick={() => handleEditVendor(vendor)}
                        className="p-2 rounded-lg text-slate-600 hover:bg-slate-100 hover:text-slate-900"
                        aria-label="Edit"
                        title="Edit"
                      >
                        <Pencil className="w-4 h-4" />
                      </button>
                      <button
                        type="button"
                        onClick={() => handleViewVendor(vendor)}
                        className="p-2 rounded-lg text-slate-600 hover:bg-slate-100 hover:text-slate-900"
                        aria-label="View details"
                        title="View Details"
                      >
                        <Eye className="w-4 h-4" />
                      </button>
                      <button
                        type="button"
                        className="p-2 rounded-lg text-slate-600 hover:bg-red-50 hover:text-red-600"
                        aria-label="Delete"
                        title="Delete"
                      >
                        <Trash2 className="w-4 h-4" />
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

      {/* Add Vendor Modal */}
      <Modal
        open={addDialogOpen}
        title="Add New Vendor"
        onClose={() => setAddDialogOpen(false)}
        footer={
          <>
            <Button variant="ghost" onClick={() => setAddDialogOpen(false)}>
              Cancel
            </Button>
            <Button onClick={() => setAddDialogOpen(false)}>Add Vendor</Button>
          </>
        }
      >
        <div className="grid grid-cols-1 md:grid-cols-2 gap-3">{formFields}</div>
      </Modal>

      {/* Edit Vendor Modal */}
      <Modal
        open={editDialogOpen}
        title="Edit Vendor"
        onClose={() => setEditDialogOpen(false)}
        footer={
          <>
            <Button variant="ghost" onClick={() => setEditDialogOpen(false)}>
              Cancel
            </Button>
            <Button onClick={() => setEditDialogOpen(false)}>Update Vendor</Button>
          </>
        }
      >
        <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
          <label className="block md:col-span-2">
            <span className="block text-sm font-medium text-slate-700 mb-1">Phone Number</span>
            <input
              value={formData.phone}
              readOnly
              disabled
              className="w-full h-11 rounded-xl border border-slate-200 bg-slate-100 px-4 text-slate-500 cursor-not-allowed"
            />
          </label>
          <Input label="Name" value={formData.name} onChange={(v) => setFormData({ ...formData, name: v })} />
          <Input
            label="Business Name"
            value={formData.business_name}
            onChange={(v) => setFormData({ ...formData, business_name: v })}
          />
          <label className="block md:col-span-2">
            <span className="block text-sm font-medium text-slate-700 mb-1">Address</span>
            <textarea
              value={formData.address}
              onChange={(e) => setFormData({ ...formData, address: e.target.value })}
              rows={2}
              className="w-full rounded-xl border border-slate-200 bg-white px-4 py-3 text-slate-900 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-cancan-primary/30"
            />
          </label>
          <Input
            label="Commission Rate (%)"
            type="number"
            value={String(formData.commission_rate)}
            onChange={(v) => setFormData({ ...formData, commission_rate: parseFloat(v) || 0 })}
          />
          <Select
            label="Status"
            value={formData.status}
            onChange={(v) => setFormData({ ...formData, status: v as 'active' | 'inactive' | 'suspended' })}
            options={[
              { value: 'active', label: 'Active' },
              { value: 'inactive', label: 'Inactive' },
              { value: 'suspended', label: 'Suspended' },
            ]}
          />
        </div>
      </Modal>

      {/* View Vendor Modal */}
      <Modal
        open={viewDialogOpen}
        title="Vendor Details"
        onClose={() => setViewDialogOpen(false)}
        footer={
          <>
            <Button variant="ghost" onClick={() => setViewDialogOpen(false)}>
              Close
            </Button>
            {selectedVendor && (
              <Button onClick={() => { handleEditVendor(selectedVendor); setViewDialogOpen(false); setEditDialogOpen(true); }}>
                Edit
              </Button>
            )}
          </>
        }
      >
        {selectedVendor ? (
          <div className="space-y-4">
            <Card className="p-4 bg-slate-50 border-slate-200">
              <div className="space-y-2 text-sm text-slate-800">
                <div><span className="font-semibold">Name:</span> {selectedVendor.name}</div>
                <div><span className="font-semibold">Phone:</span> {selectedVendor.phone}</div>
                <div><span className="font-semibold">Business:</span> {selectedVendor.business_name || '-'}</div>
                <div><span className="font-semibold">Address:</span> {selectedVendor.address || '-'}</div>
                <div className="flex items-center gap-2">
                  <span className="font-semibold">Status:</span>
                  <StatusChip
                    label={selectedVendor.status.replace(/\b\w/g, (l) => l.toUpperCase())}
                    variant={statusToVariant(selectedVendor.status)}
                  />
                </div>
                <div><span className="font-semibold">Commission Rate:</span> {selectedVendor.commission_rate}%</div>
                <div><span className="font-semibold">Joined:</span> {formatDate(selectedVendor.created_at)}</div>
                <div><span className="font-semibold">Total Orders:</span> {selectedVendor.stats?.totalOrders ?? 0}</div>
                <div><span className="font-semibold">Total Revenue:</span> {formatCurrency(selectedVendor.stats?.totalRevenue ?? 0)}</div>
              </div>
            </Card>
          </div>
        ) : null}
      </Modal>
    </div>
  );
};

export default Vendors;
