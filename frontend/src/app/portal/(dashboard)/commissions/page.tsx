'use client';

import React, { useEffect, useState } from 'react';
import { TrendingUp, CheckCircle, Clock, Wallet, Eye } from 'lucide-react';
import { useDispatch, useSelector } from 'react-redux';
import { RootState, AppDispatch } from '@/store';
import { fetchCommissions, fetchCommissionStats } from '@/store/commissionSlice';
import type { CommissionRecord } from '@/types';
import PortalPageHeader from '@/components/portal/PortalPageHeader';
import StatusChip, { statusToVariant } from '@/components/portal/StatusChip';
import { Button, Card, Modal, Pagination, Select } from '@/components/portal/ui';
import apiService from '@/services/api';

const Commissions: React.FC = () => {
  const dispatch = useDispatch<AppDispatch>();
  const { commissions, pagination, stats, isLoading, error } = useSelector((state: RootState) => state.commissions);

  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);
  const [statusFilter, setStatusFilter] = useState('all');
  const [vendorFilter, setVendorFilter] = useState('all');
  const [dateFilter, setDateFilter] = useState('all');
  const [selectedCommission, setSelectedCommission] = useState<CommissionRecord | null>(null);
  const [viewDialogOpen, setViewDialogOpen] = useState(false);
  const [isProcessingPayouts, setIsProcessingPayouts] = useState(false);

  useEffect(() => {
    dispatch(
      fetchCommissions({
        page: page + 1,
        limit: rowsPerPage,
        status: statusFilter !== 'all' ? statusFilter : undefined,
        vendor_id: vendorFilter !== 'all' ? vendorFilter : undefined,
      }),
    );
    dispatch(fetchCommissionStats(30));
  }, [dispatch, page, rowsPerPage, statusFilter, vendorFilter]);

  const formatDate = (dateString: string) =>
    new Date(dateString).toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' });

  const formatCurrency = (amount: number) =>
    new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR', minimumFractionDigits: 0 }).format(amount);

  const vendorOptions = [
    { value: 'all', label: 'All Vendors' },
    ...Array.from(
      new Map(
        commissions
          .filter((c) => c.vendor?.id)
          .map((c) => [c.vendor!.id, c.vendor!.name || c.vendor!.id]),
      ).entries(),
    ).map(([value, label]) => ({ value, label })),
  ];

  const refreshData = () => {
    dispatch(
      fetchCommissions({
        page: page + 1,
        limit: rowsPerPage,
        status: statusFilter !== 'all' ? statusFilter : undefined,
        vendor_id: vendorFilter !== 'all' ? vendorFilter : undefined,
      }),
    );
    dispatch(fetchCommissionStats(30));
  };

  const handleProcessPayouts = async () => {
    setIsProcessingPayouts(true);
    try {
      await apiService.runPayoutBatch();
      refreshData();
    } catch (e) {
      console.error('Failed to process payouts', e);
    } finally {
      setIsProcessingPayouts(false);
    }
  };

  const handleMarkAsPaid = async (commissionId: string) => {
    try {
      await apiService.updateCommissionStatus(commissionId, 'paid');
      setViewDialogOpen(false);
      refreshData();
    } catch (e) {
      console.error('Failed to mark commission as paid', e);
    }
  };

  const totalPending = stats?.totalPending || 0;
  const totalPaid = stats?.totalPaid || 0;
  const totalUnpaid = stats?.totalUnpaid || 0;
  const totalEarnings = stats?.totalEarnings || 0;
  const payoutPercentage = totalEarnings > 0 ? Math.round((totalPaid / totalEarnings) * 100) : 0;

  if (error) {
    return (
      <div>
        <PortalPageHeader title="Commission Tracking" />
        <div className="rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">{error}</div>
      </div>
    );
  }

  return (
    <div>
      <PortalPageHeader title="Commission Tracking" subtitle="Track and manage vendor commissions" />

      {/* Stats Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        <Card className="p-5 flex items-center justify-between hover:shadow-md transition-shadow">
          <div>
            <p className="text-sm font-medium text-slate-500 mb-1">Total Earnings</p>
            <p className="text-xl font-bold text-slate-900">{formatCurrency(totalEarnings)}</p>
          </div>
          <div className="w-12 h-12 rounded-xl bg-blue-100 flex items-center justify-center text-blue-600">
            <TrendingUp className="w-6 h-6" />
          </div>
        </Card>
        <Card className="p-5 flex items-center justify-between hover:shadow-md transition-shadow">
          <div>
            <p className="text-sm font-medium text-slate-500 mb-1">Paid Commissions</p>
            <p className="text-xl font-bold text-slate-900">{formatCurrency(totalPaid)}</p>
          </div>
          <div className="w-12 h-12 rounded-xl bg-green-100 flex items-center justify-center text-green-600">
            <CheckCircle className="w-6 h-6" />
          </div>
        </Card>
        <Card className="p-5 flex items-center justify-between hover:shadow-md transition-shadow">
          <div>
            <p className="text-sm font-medium text-slate-500 mb-1">Pending Payment</p>
            <p className="text-xl font-bold text-slate-900">{formatCurrency(totalPending)}</p>
          </div>
          <div className="w-12 h-12 rounded-xl bg-amber-100 flex items-center justify-center text-amber-600">
            <Clock className="w-6 h-6" />
          </div>
        </Card>
        <Card className="p-5 flex items-center justify-between hover:shadow-md transition-shadow">
          <div>
            <p className="text-sm font-medium text-slate-500 mb-1">Unpaid Commissions</p>
            <p className="text-xl font-bold text-slate-900">{formatCurrency(totalUnpaid)}</p>
          </div>
          <div className="w-12 h-12 rounded-xl bg-red-100 flex items-center justify-center text-red-600">
            <Wallet className="w-6 h-6" />
          </div>
        </Card>
      </div>

      {/* Payment Progress Bar */}
      <Card className="p-4 mb-4">
        <div className="flex items-center justify-between gap-3 mb-2">
          <h2 className="text-sm font-semibold text-slate-900">Commission Payment Status</h2>
          <span className="text-sm font-semibold text-green-700">{payoutPercentage}% Paid</span>
        </div>
        <div className="h-2.5 rounded-full bg-slate-200 overflow-hidden">
          <div className="h-full bg-green-600 transition-[width]" style={{ width: `${payoutPercentage}%` }} />
        </div>
        <div className="grid grid-cols-3 gap-2 mt-3 text-sm">
          <span className="text-green-700 font-medium">Paid: {formatCurrency(totalPaid)}</span>
          <span className="text-amber-700 font-medium">Pending: {formatCurrency(totalPending)}</span>
          <span className="text-red-700 font-medium">Unpaid: {formatCurrency(totalUnpaid)}</span>
        </div>
      </Card>

      {/* Filters */}
      <Card className="p-4 mb-4">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-3">
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
              { value: 'processing', label: 'Processing' },
              { value: 'paid', label: 'Paid' },
              { value: 'cancelled', label: 'Cancelled' },
            ]}
          />
          <Select
            label="Vendor"
            value={vendorFilter}
            onChange={(v) => {
              setVendorFilter(v);
              setPage(0);
            }}
            options={vendorOptions}
          />
          <Select
            label="Date Range"
            value={dateFilter}
            onChange={setDateFilter}
            options={[
              { value: 'all', label: 'All Time' },
              { value: 'today', label: 'Today' },
              { value: 'week', label: 'This Week' },
              { value: 'month', label: 'This Month' },
            ]}
          />
          <div className="flex items-end gap-2">
            <Button variant="ghost" size="md">Export CSV</Button>
            <Button size="md" onClick={handleProcessPayouts} disabled={isProcessingPayouts}>
              {isProcessingPayouts ? 'Processing...' : 'Process Payments'}
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
                <th className="text-left font-semibold px-4 py-3">Commission ID</th>
                <th className="text-left font-semibold px-4 py-3">Vendor</th>
                <th className="text-left font-semibold px-4 py-3">Order ID</th>
                <th className="text-left font-semibold px-4 py-3">Amount</th>
                <th className="text-left font-semibold px-4 py-3">Rate</th>
                <th className="text-left font-semibold px-4 py-3">Status</th>
                <th className="text-left font-semibold px-4 py-3">Order Date</th>
                <th className="text-left font-semibold px-4 py-3">Created</th>
                <th className="text-right font-semibold px-4 py-3">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {isLoading ? (
                <tr>
                  <td className="px-4 py-8 text-slate-500 text-center" colSpan={9}>
                    Loading…
                  </td>
                </tr>
              ) : commissions.length === 0 ? (
                <tr>
                  <td className="px-4 py-8 text-slate-500 text-center" colSpan={9}>
                    No commission records found
                  </td>
                </tr>
              ) : (
                commissions.map((c) => (
                  <tr key={c.id} className="hover:bg-slate-50/60">
                    <td className="px-4 py-3 font-mono text-slate-700">#{c.id?.slice(0, 8) || 'N/A'}</td>
                    <td className="px-4 py-3">
                      <p className="font-medium text-slate-900">{c.vendor?.name || 'Unknown Vendor'}</p>
                      {c.vendor?.phone ? (
                        <p className="text-xs text-slate-500">{c.vendor.phone}</p>
                      ) : null}
                    </td>
                    <td className="px-4 py-3 font-mono text-slate-700">#{c.order_id?.slice(0, 8) || 'N/A'}</td>
                    <td className="px-4 py-3 font-semibold text-blue-700">{formatCurrency(c.commission_amount || 0)}</td>
                    <td className="px-4 py-3 font-semibold text-slate-900">{c.commission_rate || 0}%</td>
                    <td className="px-4 py-3">
                      <StatusChip
                        label={c.status.replace(/\b\w/g, (l) => l.toUpperCase())}
                        variant={statusToVariant(c.status)}
                      />
                    </td>
                    <td className="px-4 py-3 text-slate-600">{c.order_date ? formatDate(c.order_date) : 'N/A'}</td>
                    <td className="px-4 py-3 text-slate-600">{c.created_at ? formatDate(c.created_at) : 'N/A'}</td>
                    <td className="px-4 py-3 text-right">
                      <button
                        type="button"
                        onClick={() => {
                          setSelectedCommission(c);
                          setViewDialogOpen(true);
                        }}
                        className="inline-flex items-center justify-center p-2 rounded-lg text-slate-600 hover:bg-slate-100 hover:text-slate-900"
                        aria-label="View details"
                      >
                        <Eye className="w-4 h-4" />
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

      <Modal
        open={viewDialogOpen}
        title="Commission Details"
        onClose={() => setViewDialogOpen(false)}
        footer={
          <>
            <Button variant="ghost" onClick={() => setViewDialogOpen(false)}>
              Close
            </Button>
            {selectedCommission?.status === 'pending' ? (
              <Button onClick={() => handleMarkAsPaid(selectedCommission.id)}>Mark as Paid</Button>
            ) : null}
          </>
        }
      >
        {selectedCommission ? (
          <div className="rounded-xl bg-slate-50 border border-slate-200 p-4 text-sm text-slate-800 space-y-2">
            <div>
              <span className="font-semibold">Commission ID:</span> #{selectedCommission.id}
            </div>
            <div>
              <span className="font-semibold">Order ID:</span> #{selectedCommission.order_id}
            </div>
            <div>
              <span className="font-semibold">Vendor:</span> {selectedCommission.vendor?.name || '-'}
            </div>
            <div>
              <span className="font-semibold">Commission Amount:</span>{' '}
              {formatCurrency(selectedCommission.commission_amount || 0)}
            </div>
            <div>
              <span className="font-semibold">Commission Rate:</span> {selectedCommission.commission_rate}%
            </div>
            <div className="flex items-center gap-2">
              <span className="font-semibold">Status:</span>
              <StatusChip
                label={selectedCommission.status.replace(/\b\w/g, (l) => l.toUpperCase())}
                variant={statusToVariant(selectedCommission.status)}
              />
            </div>
            <div>
              <span className="font-semibold">Order Total:</span> {formatCurrency(selectedCommission.order_total || 0)}
            </div>
            <div>
              <span className="font-semibold">Order Date:</span>{' '}
              {selectedCommission.order_date ? formatDate(selectedCommission.order_date) : 'N/A'}
            </div>
            <div>
              <span className="font-semibold">Created:</span>{' '}
              {selectedCommission.created_at ? formatDate(selectedCommission.created_at) : 'N/A'}
            </div>
            {selectedCommission.paid_at ? (
              <div>
                <span className="font-semibold">Paid On:</span> {formatDate(selectedCommission.paid_at)}
              </div>
            ) : null}
          </div>
        ) : null}
      </Modal>
    </div>
  );
};

export default Commissions;
