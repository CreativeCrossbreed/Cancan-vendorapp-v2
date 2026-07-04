'use client';

import React, { useEffect, useState } from 'react';
import {
  Clock,
  MessageCircle,
  MessageSquare,
  Megaphone,
  Phone,
  RefreshCw,
  Send,
  ShoppingCart,
  Settings,
} from 'lucide-react';
import { useDispatch, useSelector } from 'react-redux';
import { RootState, AppDispatch } from '@/store';
import { fetchWhatsAppMessages, fetchWhatsAppOrders } from '@/store/whatsappSlice';
import { WhatsAppMessage, WhatsAppOrder } from '@/types';
import PortalPageHeader from '@/components/portal/PortalPageHeader';
import StatusChip, { statusToVariant } from '@/components/portal/StatusChip';
import { Button, Card, Input, Modal, Pagination, Select } from '@/components/portal/ui';

function Toggle({
  checked,
  onChange,
}: {
  checked: boolean;
  onChange: (checked: boolean) => void;
}) {
  return (
    <button
      type="button"
      role="switch"
      aria-checked={checked}
      onClick={() => onChange(!checked)}
      className={`relative inline-flex h-6 w-11 shrink-0 rounded-full border transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-cancan-primary/40 ${
        checked ? 'bg-cancan-primary border-cancan-primary' : 'bg-slate-200 border-slate-200'
      }`}
    >
      <span
        className="pointer-events-none inline-block h-5 w-5 rounded-full bg-white shadow ring-0 transition-transform"
        style={{ transform: checked ? 'translateX(1.25rem)' : 'translateX(0.125rem)' }}
      />
    </button>
  );
}

const WhatsApp: React.FC = () => {
  const dispatch = useDispatch<AppDispatch>();
  const { messages, orders, config, pagination, isLoading, error } = useSelector((state: RootState) => state.whatsapp);

  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);
  const [tab, setTab] = useState<'messages' | 'orders'>('messages');
  const [messageFilter, setMessageFilter] = useState('all');
  const [orderFilter, setOrderFilter] = useState('all');
  const [sendDialogOpen, setSendDialogOpen] = useState(false);
  const [configDialogOpen, setConfigDialogOpen] = useState(false);
  const [selectedMessage, setSelectedMessage] = useState<WhatsAppMessage | null>(null);
  const [viewDialogOpen, setViewDialogOpen] = useState(false);
  const [sendForm, setSendForm] = useState({ to: '', message: '' });
  const [configForm, setConfigForm] = useState({
    webhook_enabled: false,
    webhook_url: '',
    access_token: '',
    phone_number_id: '',
  });
  const [broadcastOpen, setBroadcastOpen] = useState(false);
  const [broadcastForm, setBroadcastForm] = useState({ message: '', imageUrl: '' });
  const [broadcasting, setBroadcasting] = useState(false);
  const [broadcastResult, setBroadcastResult] = useState<string | null>(null);

  const handleBroadcast = async () => {
    setBroadcasting(true);
    setBroadcastResult(null);
    try {
      const token = typeof window !== 'undefined' ? localStorage.getItem('token') : null;
      const res = await fetch('/api/whatsapp/broadcast', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          ...(token ? { Authorization: `Bearer ${token}` } : {}),
        },
        body: JSON.stringify({ message: broadcastForm.message, imageUrl: broadcastForm.imageUrl }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error || 'Broadcast failed');
      setBroadcastResult(
        data.note ||
          `✅ Sent to ${data.sent} customer${data.sent === 1 ? '' : 's'}` +
            (data.failed ? ` (${data.failed} failed)` : '') + '.',
      );
    } catch (e) {
      setBroadcastResult(`❌ ${e instanceof Error ? e.message : 'Broadcast failed'}`);
    } finally {
      setBroadcasting(false);
    }
  };

  useEffect(() => {
    if (tab === 'messages') {
      dispatch(
        fetchWhatsAppMessages({
          page: page + 1,
          limit: rowsPerPage,
          direction: messageFilter !== 'all' ? messageFilter : undefined,
        }),
      );
    } else {
      dispatch(
        fetchWhatsAppOrders({
          page: page + 1,
          limit: rowsPerPage,
          status: orderFilter !== 'all' ? orderFilter : undefined,
        }),
      );
    }
  }, [dispatch, tab, page, rowsPerPage, messageFilter, orderFilter]);

  useEffect(() => {
    if (config) {
      setConfigForm((prev) => ({
        webhook_enabled: config.webhook_enabled ?? prev.webhook_enabled,
        webhook_url: config.webhook_url ?? prev.webhook_url,
        access_token: config.access_token ?? prev.access_token,
        phone_number_id: config.phone_number_id ?? prev.phone_number_id,
      }));
    }
  }, [config]);

  const handleSendMessage = () => {
    setSendDialogOpen(false);
    setSendForm({ to: '', message: '' });
  };

  const handleViewMessage = (message: WhatsAppMessage) => {
    setSelectedMessage(message);
    setViewDialogOpen(true);
  };

  const formatDate = (dateString: string) =>
    new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });

  const todayMessages = messages.filter(
    (msg) => new Date(msg.created_at).toDateString() === new Date().toDateString(),
  );
  const pendingOrdersCount = orders.filter((o) => o.status === 'pending').length;

  if (error) {
    return (
      <div>
        <PortalPageHeader title="WhatsApp Integration" />
        <div className="rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">{error}</div>
      </div>
    );
  }

  const totalCount = pagination?.total ?? 0;

  return (
    <div>
      <PortalPageHeader title="WhatsApp Integration" subtitle="Manage WhatsApp messaging and orders" />

      {/* Stats Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        <Card className="p-5 flex items-center justify-between hover:shadow-md transition-shadow">
          <div>
            <p className="text-sm font-medium text-slate-500 mb-1">API Status</p>
            <StatusChip
              label={config?.connected ? 'Connected' : 'Disconnected'}
              variant={config?.connected ? 'success' : 'error'}
            />
          </div>
          <div
            className={`w-12 h-12 rounded-xl flex items-center justify-center ${
              config?.connected ? 'bg-green-100 text-green-600' : 'bg-red-100 text-red-600'
            }`}
          >
            <MessageCircle className="w-6 h-6" />
          </div>
        </Card>
        <Card className="p-5 flex items-center justify-between hover:shadow-md transition-shadow">
          <div>
            <p className="text-sm font-medium text-slate-500 mb-1">Total Messages</p>
            <p className="text-xl font-bold text-slate-900">{messages.length}</p>
          </div>
          <div className="w-12 h-12 rounded-xl bg-blue-100 flex items-center justify-center text-blue-600">
            <MessageSquare className="w-6 h-6" />
          </div>
        </Card>
        <Card className="p-5 flex items-center justify-between hover:shadow-md transition-shadow">
          <div>
            <p className="text-sm font-medium text-slate-500 mb-1">Today&apos;s Messages</p>
            <p className="text-xl font-bold text-slate-900">{todayMessages.length}</p>
          </div>
          <div className="w-12 h-12 rounded-xl bg-sky-100 flex items-center justify-center text-sky-600">
            <Clock className="w-6 h-6" />
          </div>
        </Card>
        <Card className="p-5 flex items-center justify-between hover:shadow-md transition-shadow">
          <div>
            <p className="text-sm font-medium text-slate-500 mb-1">Pending Orders</p>
            <p className="text-xl font-bold text-slate-900">{pendingOrdersCount}</p>
          </div>
          <div className="w-12 h-12 rounded-xl bg-amber-100 flex items-center justify-center text-amber-600">
            <ShoppingCart className="w-6 h-6" />
          </div>
        </Card>
      </div>

      {/* Tabs + Actions */}
      <Card className="p-4 mb-4">
        <div className="flex flex-wrap items-center gap-2">
          <Button
            variant={tab === 'messages' ? 'primary' : 'ghost'}
            size="md"
            onClick={() => setTab('messages')}
          >
            Messages
          </Button>
          <Button
            variant={tab === 'orders' ? 'primary' : 'ghost'}
            size="md"
            onClick={() => setTab('orders')}
          >
            WhatsApp Orders
          </Button>
          <span className="w-px h-6 bg-slate-200 mx-1" aria-hidden />
          <Button variant="ghost" size="md" className="gap-2" onClick={() => setSendDialogOpen(true)}>
            <Send className="w-4 h-4" />
            Send Message
          </Button>
          <Button
            variant="primary"
            size="md"
            className="gap-2"
            onClick={() => {
              setBroadcastResult(null);
              setBroadcastOpen(true);
            }}
          >
            <Megaphone className="w-4 h-4" />
            Broadcast Promotion
          </Button>
          <Button variant="ghost" size="md" className="gap-2" onClick={() => setConfigDialogOpen(true)}>
            <Settings className="w-4 h-4" />
            Configuration
          </Button>
          <Button variant="ghost" size="md" className="gap-2" onClick={() => window.location.reload()}>
            <RefreshCw className="w-4 h-4" />
            Refresh
          </Button>
        </div>
      </Card>

      {/* Filters */}
      <Card className="p-4 mb-4">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-3 items-end">
          {tab === 'messages' ? (
            <Select
              label="Direction"
              value={messageFilter}
              onChange={(v) => {
                setMessageFilter(v);
                setPage(0);
              }}
              options={[
                { value: 'all', label: 'All Messages' },
                { value: 'inbound', label: 'Inbound' },
                { value: 'outbound', label: 'Outbound' },
              ]}
            />
          ) : (
            <Select
              label="Status"
              value={orderFilter}
              onChange={(v) => {
                setOrderFilter(v);
                setPage(0);
              }}
              options={[
                { value: 'all', label: 'All Orders' },
                { value: 'pending', label: 'Pending' },
                { value: 'confirmed', label: 'Confirmed' },
                { value: 'processing', label: 'Processing' },
                { value: 'completed', label: 'Completed' },
                { value: 'cancelled', label: 'Cancelled' },
              ]}
            />
          )}
        </div>
      </Card>

      {/* Table */}
      <Card className="overflow-hidden">
        <div className="overflow-x-auto">
          <table className="min-w-full text-sm">
            <thead className="bg-slate-50 text-slate-600">
              {tab === 'messages' ? (
                <tr>
                  <th className="text-left font-semibold px-4 py-3">Phone</th>
                  <th className="text-left font-semibold px-4 py-3">Direction</th>
                  <th className="text-left font-semibold px-4 py-3">Message</th>
                  <th className="text-left font-semibold px-4 py-3">Status</th>
                  <th className="text-left font-semibold px-4 py-3">Sent At</th>
                  <th className="text-right font-semibold px-4 py-3">Actions</th>
                </tr>
              ) : (
                <tr>
                  <th className="text-left font-semibold px-4 py-3">Order #</th>
                  <th className="text-left font-semibold px-4 py-3">Customer</th>
                  <th className="text-left font-semibold px-4 py-3">Phone</th>
                  <th className="text-left font-semibold px-4 py-3">Items</th>
                  <th className="text-left font-semibold px-4 py-3">Total</th>
                  <th className="text-left font-semibold px-4 py-3">Status</th>
                  <th className="text-left font-semibold px-4 py-3">Received</th>
                  <th className="text-right font-semibold px-4 py-3">Actions</th>
                </tr>
              )}
            </thead>
            <tbody className="divide-y divide-slate-100">
              {isLoading ? (
                <tr>
                  <td
                    className="px-4 py-8 text-slate-500 text-center"
                    colSpan={tab === 'messages' ? 6 : 8}
                  >
                    Loading…
                  </td>
                </tr>
              ) : (tab === 'messages' ? messages : orders).length === 0 ? (
                <tr>
                  <td
                    className="px-4 py-8 text-slate-500 text-center"
                    colSpan={tab === 'messages' ? 6 : 8}
                  >
                    No {tab === 'messages' ? 'messages' : 'orders'} found
                  </td>
                </tr>
              ) : tab === 'messages' ? (
                messages.map((msg) => (
                  <tr key={msg.id} className="hover:bg-slate-50/60">
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-2">
                        <Phone className="w-4 h-4 text-slate-400" />
                        <span className="font-medium text-slate-900">{msg.phone}</span>
                      </div>
                    </td>
                    <td className="px-4 py-3">
                      <StatusChip
                        label={msg.direction}
                        variant={msg.direction === 'inbound' ? 'info' : 'success'}
                      />
                    </td>
                    <td className="px-4 py-3 text-slate-700 max-w-[200px] truncate">{msg.message}</td>
                    <td className="px-4 py-3">
                      <StatusChip label={msg.status} variant={statusToVariant(msg.status)} />
                    </td>
                    <td className="px-4 py-3 text-slate-700">{formatDate(msg.created_at)}</td>
                    <td className="px-4 py-3 text-right">
                      <button
                        type="button"
                        onClick={() => handleViewMessage(msg)}
                        className="p-2 rounded-lg text-slate-600 hover:bg-slate-100 hover:text-slate-900"
                        aria-label="View message"
                      >
                        <MessageSquare className="w-4 h-4" />
                      </button>
                    </td>
                  </tr>
                ))
              ) : (
                orders.map((order) => (
                  <tr key={order.id} className="hover:bg-slate-50/60">
                    <td className="px-4 py-3 font-semibold text-blue-700">#{order.order_number}</td>
                    <td className="px-4 py-3 font-medium text-slate-900">{order.customer_name}</td>
                    <td className="px-4 py-3 text-slate-700">{order.phone}</td>
                    <td className="px-4 py-3 text-slate-700">{order.items?.length ?? 0} items</td>
                    <td className="px-4 py-3 font-semibold text-slate-900">₹{order.total_amount ?? 0}</td>
                    <td className="px-4 py-3">
                      <StatusChip label={order.status} variant={statusToVariant(order.status)} />
                    </td>
                    <td className="px-4 py-3 text-slate-700">{formatDate(order.created_at)}</td>
                    <td className="px-4 py-3 text-right">
                      <Button variant="ghost" size="sm">
                        Process
                      </Button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
        <Pagination
          count={totalCount}
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

      {/* Send Message Modal */}
      <Modal
        open={sendDialogOpen}
        title="Send WhatsApp Message"
        onClose={() => setSendDialogOpen(false)}
        footer={
          <>
            <Button variant="ghost" onClick={() => setSendDialogOpen(false)}>
              Cancel
            </Button>
            <Button onClick={handleSendMessage}>Send Message</Button>
          </>
        }
      >
        <div className="space-y-3">
          <Input
            label="Phone Number"
            value={sendForm.to}
            onChange={(v) => setSendForm({ ...sendForm, to: v })}
            placeholder="+919876543210"
          />
          <label className="block">
            <span className="block text-sm font-medium text-slate-700 mb-1">Message</span>
            <textarea
              value={sendForm.message}
              onChange={(e) => setSendForm({ ...sendForm, message: e.target.value })}
              rows={4}
              className="w-full rounded-xl border border-slate-200 bg-white px-4 py-3 text-slate-900 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-cancan-primary/30"
              placeholder="Type your message here..."
            />
          </label>
        </div>
      </Modal>

      {/* Broadcast Promotion Modal */}
      <Modal
        open={broadcastOpen}
        title="Broadcast Promotion"
        onClose={() => setBroadcastOpen(false)}
        footer={
          <>
            <Button variant="ghost" onClick={() => setBroadcastOpen(false)}>
              Close
            </Button>
            <Button
              onClick={handleBroadcast}
              disabled={broadcasting || (!broadcastForm.message.trim() && !broadcastForm.imageUrl.trim())}
            >
              {broadcasting ? 'Sending…' : 'Send to Active Customers'}
            </Button>
          </>
        }
      >
        <div className="space-y-3">
          <div className="rounded-lg bg-amber-50 border border-amber-200 px-3 py-2 text-xs text-amber-800">
            Reaches customers who messaged in the last <b>24 hours</b> (WhatsApp&apos;s free-form window).
            To reach everyone, an approved Marketing template is required.
          </div>
          <label className="block">
            <span className="block text-sm font-medium text-slate-700 mb-1">Message / Caption</span>
            <textarea
              value={broadcastForm.message}
              onChange={(e) => setBroadcastForm({ ...broadcastForm, message: e.target.value })}
              rows={4}
              className="w-full rounded-xl border border-slate-200 bg-white px-4 py-3 text-slate-900 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-cancan-primary/30"
              placeholder="🎉 Special offer! Order 2 cans today and get free delivery. Reply to order."
            />
          </label>
          <Input
            label="Image / banner URL (optional)"
            value={broadcastForm.imageUrl}
            onChange={(v) => setBroadcastForm({ ...broadcastForm, imageUrl: v })}
            placeholder="https://.../banner.jpg"
          />
          {broadcastResult ? (
            <div
              className={`rounded-lg px-3 py-2 text-sm ${
                broadcastResult.startsWith('❌')
                  ? 'bg-red-50 border border-red-200 text-red-700'
                  : 'bg-green-50 border border-green-200 text-green-700'
              }`}
            >
              {broadcastResult}
            </div>
          ) : null}
        </div>
      </Modal>

      {/* Configuration Modal */}
      <Modal
        open={configDialogOpen}
        title="WhatsApp Configuration"
        onClose={() => setConfigDialogOpen(false)}
        footer={
          <>
            <Button variant="ghost" onClick={() => setConfigDialogOpen(false)}>
              Cancel
            </Button>
            <Button onClick={() => setConfigDialogOpen(false)}>Save Configuration</Button>
          </>
        }
      >
        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <span className="text-sm font-medium text-slate-700">Webhook Enabled</span>
            <Toggle
              checked={configForm.webhook_enabled}
              onChange={(checked) => setConfigForm({ ...configForm, webhook_enabled: checked })}
            />
          </div>
          <Input
            label="Webhook URL"
            value={configForm.webhook_url}
            onChange={(v) => setConfigForm({ ...configForm, webhook_url: v })}
            placeholder="https://your-server.com/webhook"
          />
          <Input
            label="Access Token"
            type="password"
            value={configForm.access_token}
            onChange={(v) => setConfigForm({ ...configForm, access_token: v })}
            placeholder="Enter WhatsApp API access token"
          />
          <Input
            label="Phone Number ID"
            value={configForm.phone_number_id}
            onChange={(v) => setConfigForm({ ...configForm, phone_number_id: v })}
            placeholder="Enter WhatsApp phone number ID"
          />
        </div>
      </Modal>

      {/* Message Details Modal */}
      <Modal
        open={viewDialogOpen}
        title="Message Details"
        onClose={() => setViewDialogOpen(false)}
        footer={
          <Button variant="ghost" onClick={() => setViewDialogOpen(false)}>
            Close
          </Button>
        }
      >
        {selectedMessage ? (
          <Card className="p-4 bg-slate-50 border-slate-200">
            <div className="space-y-2 text-sm text-slate-800">
              <div><span className="font-semibold">Phone:</span> {selectedMessage.phone}</div>
              <div><span className="font-semibold">Direction:</span> {selectedMessage.direction}</div>
              <div><span className="font-semibold">Message:</span> {selectedMessage.message}</div>
              <div className="flex items-center gap-2">
                <span className="font-semibold">Status:</span>
                <StatusChip label={selectedMessage.status} variant={statusToVariant(selectedMessage.status)} />
              </div>
              <div><span className="font-semibold">Message ID:</span> {selectedMessage.whatsapp_message_id}</div>
              <div><span className="font-semibold">Sent At:</span> {formatDate(selectedMessage.created_at)}</div>
            </div>
          </Card>
        ) : null}
      </Modal>
    </div>
  );
};

export default WhatsApp;
