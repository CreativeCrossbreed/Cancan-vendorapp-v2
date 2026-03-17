'use client';

import React, { useState, useEffect } from 'react';
import {
  Bell,
  CheckCircle,
  Database,
  Eye,
  EyeOff,
  Info,
  MessageCircle,
  Pencil,
  Save,
  Settings as GearIcon,
  Shield,
  User,
} from 'lucide-react';
import { useSelector } from 'react-redux';
import { RootState } from '@/store';
import apiService from '@/services/api';
import PortalPageHeader from '@/components/portal/PortalPageHeader';
import { Button, Card, Input, Modal } from '@/components/portal/ui';

function FieldWithTooltip({
  label,
  tooltip,
  children,
}: {
  label: string;
  tooltip: string;
  children: React.ReactNode;
}) {
  return (
    <label className="block">
      <span className="flex items-center gap-1.5 text-sm font-medium text-slate-700 mb-1">
        {label}
        <span title={tooltip} className="text-slate-400 cursor-help">
          <Info className="w-3.5 h-3.5" />
        </span>
      </span>
      {children}
    </label>
  );
}

function Toggle({
  checked,
  onChange,
  className = '',
}: {
  checked: boolean;
  onChange: (checked: boolean) => void;
  className?: string;
}) {
  return (
    <button
      type="button"
      role="switch"
      aria-checked={checked}
      onClick={() => onChange(!checked)}
      className={`relative inline-flex h-6 w-11 shrink-0 rounded-full border border-slate-200 transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-cancan-primary/40 ${className} ${
        checked ? 'bg-cancan-primary border-cancan-primary' : 'bg-slate-200'
      }`}
    >
      <span
        className="pointer-events-none inline-block h-5 w-5 rounded-full bg-white shadow ring-0 transition-transform"
        style={{ transform: checked ? 'translateX(1.25rem)' : 'translateX(0.125rem)' }}
      />
    </button>
  );
}

const Settings: React.FC = () => {
  const { user } = useSelector((state: RootState) => state.auth);

  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [snackbar, setSnackbar] = useState({ open: false, message: '', severity: 'success' as 'success' | 'error' });
  const [passwordDialogOpen, setPasswordDialogOpen] = useState(false);
  const [passwordForm, setPasswordForm] = useState({ currentPassword: '', newPassword: '', confirmPassword: '' });
  const [showSecrets, setShowSecrets] = useState<Record<string, boolean>>({});

  const [whatsapp, setWhatsapp] = useState({
    whatsapp_api_token: '',
    whatsapp_phone_number_id: '',
    whatsapp_webhook_secret: '',
    whatsapp_business_account_id: '',
    meta_app_secret: '',
  });

  const [company, setCompany] = useState({
    company_name: 'Can Can Water Delivery',
    company_email: '',
    company_phone: '',
    company_address: '',
  });

  const [notifications, setNotifications] = useState({
    notif_email: 'true',
    notif_sms: 'false',
    notif_push: 'true',
    notif_order_alerts: 'true',
    notif_payment_alerts: 'true',
  });

  const [system, setSystem] = useState({
    auto_assign_orders: 'false',
    require_vendor_approval: 'true',
    enable_customer_signup: 'true',
    maintenance_mode: 'false',
  });

  useEffect(() => {
    loadSettings();
  }, []);

  useEffect(() => {
    if (!snackbar.open) return;
    const t = setTimeout(() => setSnackbar((s) => ({ ...s, open: false })), 4000);
    return () => clearTimeout(t);
  }, [snackbar.open]);

  const loadSettings = async () => {
    try {
      setLoading(true);
      const { settings } = await apiService.getSettings();
      if (settings) {
        setWhatsapp((prev) => ({
          whatsapp_api_token: settings.whatsapp_api_token || prev.whatsapp_api_token,
          whatsapp_phone_number_id: settings.whatsapp_phone_number_id || prev.whatsapp_phone_number_id,
          whatsapp_webhook_secret: settings.whatsapp_webhook_secret || prev.whatsapp_webhook_secret,
          whatsapp_business_account_id: settings.whatsapp_business_account_id || prev.whatsapp_business_account_id,
          meta_app_secret: settings.meta_app_secret || prev.meta_app_secret,
        }));
        setCompany((prev) => ({
          company_name: settings.company_name || prev.company_name,
          company_email: settings.company_email || prev.company_email,
          company_phone: settings.company_phone || prev.company_phone,
          company_address: settings.company_address || prev.company_address,
        }));
        setNotifications((prev) => ({
          notif_email: settings.notif_email || prev.notif_email,
          notif_sms: settings.notif_sms || prev.notif_sms,
          notif_push: settings.notif_push || prev.notif_push,
          notif_order_alerts: settings.notif_order_alerts || prev.notif_order_alerts,
          notif_payment_alerts: settings.notif_payment_alerts || prev.notif_payment_alerts,
        }));
        setSystem((prev) => ({
          auto_assign_orders: settings.auto_assign_orders || prev.auto_assign_orders,
          require_vendor_approval: settings.require_vendor_approval || prev.require_vendor_approval,
          enable_customer_signup: settings.enable_customer_signup || prev.enable_customer_signup,
          maintenance_mode: settings.maintenance_mode || prev.maintenance_mode,
        }));
      }
    } catch (err) {
      console.error('Failed to load settings:', err);
      setSnackbar({ open: true, message: 'Failed to load settings. Supabase may not be configured.', severity: 'error' });
    } finally {
      setLoading(false);
    }
  };

  const handleSave = async () => {
    try {
      setSaving(true);
      const allSettings = { ...whatsapp, ...company, ...notifications, ...system };
      await apiService.updateSettings(allSettings);
      setSnackbar({ open: true, message: 'Settings saved successfully!', severity: 'success' });
    } catch (err: unknown) {
      const message = err && typeof err === 'object' && 'response' in err && err.response && typeof (err.response as { data?: { error?: string } }).data?.error === 'string'
        ? (err.response as { data: { error: string } }).data.error
        : 'Failed to save settings';
      setSnackbar({ open: true, message, severity: 'error' });
    } finally {
      setSaving(false);
    }
  };

  const toggleSecret = (key: string) => {
    setShowSecrets((prev) => ({ ...prev, [key]: !prev[key] }));
  };

  const handlePasswordChange = () => {
    setPasswordDialogOpen(false);
    setPasswordForm({ currentPassword: '', newPassword: '', confirmPassword: '' });
  };

  if (loading) {
    return (
      <div className="flex justify-center items-center min-h-[60vh]">
        <div className="w-10 h-10 border-2 border-cancan-primary border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  return (
    <div>
      <PortalPageHeader
        title="Settings"
        subtitle="Manage API credentials, company info, and application configuration"
      />

      <div className="space-y-6">
        {/* Supabase Connection */}
        <Card className="p-6">
          <div className="flex items-center flex-wrap gap-4 mb-4">
            <div className="w-12 h-12 rounded-xl bg-green-100 flex items-center justify-center text-green-600">
              <Database className="w-6 h-6" />
            </div>
            <div className="flex-1 min-w-0">
              <h2 className="text-lg font-semibold text-slate-900">Supabase Connection</h2>
              <p className="text-sm text-slate-500">
                Database connection status — configured via environment variables
              </p>
            </div>
            <span className="inline-flex items-center gap-1.5 rounded-full border border-green-200 bg-green-50 px-2.5 py-1 text-xs font-medium text-green-800">
              <CheckCircle className="w-3.5 h-3.5" />
              Configured
            </span>
          </div>
          <div className="rounded-xl border border-blue-200 bg-blue-50 px-4 py-3 text-sm text-blue-800">
            Supabase URL and API keys are set via environment variables (Vercel dashboard or{' '}
            <code className="rounded bg-blue-100 px-1">.env.local</code>). They cannot be changed from this page for
            security reasons — the app needs them to boot.
          </div>
        </Card>

        {/* WhatsApp Business API */}
        <Card className="p-6">
          <div className="flex items-center gap-4 mb-6">
            <div className="w-12 h-12 rounded-xl bg-green-100 flex items-center justify-center text-[#25D366]">
              <MessageCircle className="w-6 h-6" />
            </div>
            <div>
              <h2 className="text-lg font-semibold text-slate-900">WhatsApp Business API</h2>
              <p className="text-sm text-slate-500">
                Credentials for the Meta WhatsApp Business Platform. Changes take effect immediately.
              </p>
            </div>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <FieldWithTooltip
              label="API Token"
              tooltip="The permanent access token from Meta Business Suite → System Users → Generate Token. Starts with 'EAA...'"
            >
              <Input
                label=""
                type={showSecrets.whatsapp_api_token ? 'text' : 'password'}
                value={whatsapp.whatsapp_api_token}
                onChange={(v) => setWhatsapp({ ...whatsapp, whatsapp_api_token: v })}
                placeholder="EAAxxxxxxx..."
                right={
                  <button
                    type="button"
                    onClick={() => toggleSecret('whatsapp_api_token')}
                    className="p-1 rounded-lg text-slate-500 hover:text-slate-700"
                    aria-label={showSecrets.whatsapp_api_token ? 'Hide' : 'Show'}
                  >
                    {showSecrets.whatsapp_api_token ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                  </button>
                }
              />
            </FieldWithTooltip>
            <FieldWithTooltip
              label="Phone Number ID"
              tooltip="Found in Meta Business Suite → WhatsApp → Getting Started → Phone Number ID. A numeric string like '1234567890'."
            >
              <Input
                label=""
                value={whatsapp.whatsapp_phone_number_id}
                onChange={(v) => setWhatsapp({ ...whatsapp, whatsapp_phone_number_id: v })}
                placeholder="1234567890"
              />
            </FieldWithTooltip>
            <FieldWithTooltip
              label="Webhook Verify Token"
              tooltip="A custom secret string YOU create. Enter the same value here and in Meta's webhook configuration page."
            >
              <Input
                label=""
                type={showSecrets.whatsapp_webhook_secret ? 'text' : 'password'}
                value={whatsapp.whatsapp_webhook_secret}
                onChange={(v) => setWhatsapp({ ...whatsapp, whatsapp_webhook_secret: v })}
                placeholder="my-secret-verify-token"
                right={
                  <button
                    type="button"
                    onClick={() => toggleSecret('whatsapp_webhook_secret')}
                    className="p-1 rounded-lg text-slate-500 hover:text-slate-700"
                    aria-label={showSecrets.whatsapp_webhook_secret ? 'Hide' : 'Show'}
                  >
                    {showSecrets.whatsapp_webhook_secret ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                  </button>
                }
              />
            </FieldWithTooltip>
            <FieldWithTooltip
              label="Business Account ID"
              tooltip="Found in Meta Business Suite → Business Settings → Business Info. A numeric ID for your WhatsApp Business Account."
            >
              <Input
                label=""
                value={whatsapp.whatsapp_business_account_id}
                onChange={(v) => setWhatsapp({ ...whatsapp, whatsapp_business_account_id: v })}
                placeholder="9876543210"
              />
            </FieldWithTooltip>
            <FieldWithTooltip
              label="Meta App Secret"
              tooltip="Found in Meta Developers → Your App → Settings → Basic → App Secret. Used to verify webhook signatures."
            >
              <Input
                label=""
                type={showSecrets.meta_app_secret ? 'text' : 'password'}
                value={whatsapp.meta_app_secret}
                onChange={(v) => setWhatsapp({ ...whatsapp, meta_app_secret: v })}
                placeholder="abcdef123456..."
                right={
                  <button
                    type="button"
                    onClick={() => toggleSecret('meta_app_secret')}
                    className="p-1 rounded-lg text-slate-500 hover:text-slate-700"
                    aria-label={showSecrets.meta_app_secret ? 'Hide' : 'Show'}
                  >
                    {showSecrets.meta_app_secret ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                  </button>
                }
              />
            </FieldWithTooltip>
          </div>
        </Card>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {/* Profile */}
          <Card className="p-6 h-full">
            <div className="flex items-center gap-3 mb-4">
              <div className="w-12 h-12 rounded-xl bg-blue-100 flex items-center justify-center text-blue-600">
                <User className="w-6 h-6" />
              </div>
              <div>
                <h2 className="text-lg font-semibold text-slate-900">Profile</h2>
                <p className="text-sm text-slate-500">Your admin account info</p>
              </div>
            </div>
            <div className="rounded-xl bg-slate-50 border border-slate-200 p-4 mb-4 space-y-2 text-sm text-slate-800">
              <p><strong>Email:</strong> {user?.email || 'Admin'}</p>
              <p><strong>Role:</strong> {user?.role || 'super_admin'}</p>
              <p><strong>Last Login:</strong> {new Date().toLocaleDateString()}</p>
            </div>
            <Button variant="ghost" className="w-full gap-2" onClick={() => setPasswordDialogOpen(true)}>
              <Pencil className="w-4 h-4" />
              Change Password
            </Button>
          </Card>

          {/* Company Info */}
          <Card className="p-6 h-full">
            <div className="flex items-center gap-3 mb-4">
              <div className="w-12 h-12 rounded-xl bg-amber-100 flex items-center justify-center text-amber-600">
                <GearIcon className="w-6 h-6" />
              </div>
              <div>
                <h2 className="text-lg font-semibold text-slate-900">Company Information</h2>
                <p className="text-sm text-slate-500">Update your business details</p>
              </div>
            </div>
            <div className="space-y-3">
              <FieldWithTooltip label="Company Name" tooltip="The name displayed on invoices, WhatsApp messages, and the landing page.">
                <Input label="" value={company.company_name} onChange={(v) => setCompany({ ...company, company_name: v })} />
              </FieldWithTooltip>
              <FieldWithTooltip label="Email" tooltip="Support email shown to customers and in the footer of the website.">
                <Input label="" value={company.company_email} onChange={(v) => setCompany({ ...company, company_email: v })} />
              </FieldWithTooltip>
              <FieldWithTooltip label="Phone" tooltip="Business phone number for customer inquiries.">
                <Input label="" value={company.company_phone} onChange={(v) => setCompany({ ...company, company_phone: v })} />
              </FieldWithTooltip>
              <FieldWithTooltip label="Address" tooltip="Physical business address shown on invoices and the website.">
                <textarea
                  value={company.company_address}
                  onChange={(e) => setCompany({ ...company, company_address: e.target.value })}
                  rows={2}
                  className="w-full rounded-xl border border-slate-200 bg-white px-4 py-3 text-slate-900 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-cancan-primary/30"
                />
              </FieldWithTooltip>
            </div>
          </Card>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {/* Notifications */}
          <Card className="p-6 h-full">
            <div className="flex items-center gap-3 mb-4">
              <div className="w-12 h-12 rounded-xl bg-green-100 flex items-center justify-center text-green-600">
                <Bell className="w-6 h-6" />
              </div>
              <div>
                <h2 className="text-lg font-semibold text-slate-900">Notifications</h2>
                <p className="text-sm text-slate-500">Configure alert preferences</p>
              </div>
            </div>
            <ul className="divide-y divide-slate-100">
              {[
                { key: 'notif_email', label: 'Email Notifications', desc: 'Receive updates via email', tip: 'Sends daily summaries and alerts to the company email address above.' },
                { key: 'notif_sms', label: 'SMS Notifications', desc: 'Receive SMS alerts', tip: 'Sends critical alerts (e.g., large orders, system issues) via SMS.' },
                { key: 'notif_push', label: 'Push Notifications', desc: 'Browser push alerts', tip: 'Shows real-time browser notifications for new orders and messages.' },
                { key: 'notif_order_alerts', label: 'Order Alerts', desc: 'New order notifications', tip: 'Notifies when a new order comes in via WhatsApp or the website.' },
                { key: 'notif_payment_alerts', label: 'Payment Alerts', desc: 'Payment updates', tip: 'Notifies when a payment status changes (paid, overdue, etc.).' },
              ].map((item) => (
                <li key={item.key} className="py-3 first:pt-0 flex items-center justify-between gap-3 hover:bg-slate-50/60 rounded-lg px-1 -mx-1">
                  <div className="flex items-center gap-1.5 min-w-0">
                    <span className="text-sm font-medium text-slate-900">{item.label}</span>
                    <span title={item.tip} className="text-slate-400 cursor-help shrink-0">
                      <Info className="w-3.5 h-3.5" />
                    </span>
                  </div>
                  <Toggle
                    checked={notifications[item.key as keyof typeof notifications] === 'true'}
                    onChange={(checked) => setNotifications({ ...notifications, [item.key]: checked ? 'true' : 'false' })}
                  />
                </li>
              ))}
            </ul>
          </Card>

          {/* System Settings */}
          <Card className="p-6 h-full">
            <div className="flex items-center gap-3 mb-4">
              <div className="w-12 h-12 rounded-xl bg-violet-100 flex items-center justify-center text-violet-600">
                <Shield className="w-6 h-6" />
              </div>
              <div>
                <h2 className="text-lg font-semibold text-slate-900">System Settings</h2>
                <p className="text-sm text-slate-500">Configure app behavior</p>
              </div>
            </div>
            <ul className="divide-y divide-slate-100">
              {[
                { key: 'auto_assign_orders', label: 'Auto-Assign Orders', desc: 'Auto-assign to nearest vendor', tip: 'When enabled, new orders are automatically assigned to the nearest available vendor.' },
                { key: 'require_vendor_approval', label: 'Require Vendor Approval', desc: 'Manual approval for new vendors', tip: 'When enabled, newly registered vendors must be manually approved by an admin.' },
                { key: 'enable_customer_signup', label: 'Customer Self-Registration', desc: 'Allow customers to register', tip: 'Allows customers to create accounts themselves via WhatsApp.' },
                { key: 'maintenance_mode', label: 'Maintenance Mode', desc: 'Temporarily disable ordering', tip: 'Puts the system in read-only mode. The WhatsApp bot will inform customers that service is temporarily unavailable.' },
              ].map((item) => (
                <li key={item.key} className="py-3 first:pt-0 flex items-center justify-between gap-3 hover:bg-slate-50/60 rounded-lg px-1 -mx-1">
                  <div className="flex items-center gap-1.5 min-w-0">
                    <span className="text-sm font-medium text-slate-900">{item.label}</span>
                    <span title={item.tip} className="text-slate-400 cursor-help shrink-0">
                      <Info className="w-3.5 h-3.5" />
                    </span>
                  </div>
                  <Toggle
                    checked={system[item.key as keyof typeof system] === 'true'}
                    onChange={(checked) => setSystem({ ...system, [item.key]: checked ? 'true' : 'false' })}
                  />
                </li>
              ))}
            </ul>
          </Card>
        </div>

        <div className="flex justify-end">
          <Button onClick={handleSave} disabled={saving} className="gap-2 min-w-[180px]">
            {saving ? (
              <>
                <span className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
                Saving…
              </>
            ) : (
              <>
                <Save className="w-4 h-4" />
                Save All Settings
              </>
            )}
          </Button>
        </div>
      </div>

      {/* Password Modal */}
      <Modal
        open={passwordDialogOpen}
        title="Change Password"
        onClose={() => setPasswordDialogOpen(false)}
        footer={
          <>
            <Button variant="ghost" onClick={() => setPasswordDialogOpen(false)}>
              Cancel
            </Button>
            <Button onClick={handlePasswordChange}>Update Password</Button>
          </>
        }
      >
        <div className="space-y-3">
          <Input
            label="Current Password"
            type="password"
            value={passwordForm.currentPassword}
            onChange={(v) => setPasswordForm({ ...passwordForm, currentPassword: v })}
          />
          <Input
            label="New Password"
            type="password"
            value={passwordForm.newPassword}
            onChange={(v) => setPasswordForm({ ...passwordForm, newPassword: v })}
          />
          <Input
            label="Confirm New Password"
            type="password"
            value={passwordForm.confirmPassword}
            onChange={(v) => setPasswordForm({ ...passwordForm, confirmPassword: v })}
          />
        </div>
      </Modal>

      {/* Toast */}
      {snackbar.open && (
        <div
          className="fixed bottom-4 right-4 z-50 flex items-center gap-3 rounded-xl border px-4 py-3 shadow-lg max-w-sm animate-in fade-in slide-in-from-bottom-2"
          style={{
            backgroundColor: snackbar.severity === 'success' ? 'rgb(240 253 244)' : 'rgb(254 242 242)',
            borderColor: snackbar.severity === 'success' ? 'rgb(187 247 208)' : 'rgb(254 202 202)',
          }}
        >
          {snackbar.severity === 'success' ? (
            <CheckCircle className="w-5 h-5 text-green-600 shrink-0" />
          ) : (
            <span className="w-5 h-5 rounded-full bg-red-500 flex items-center justify-center text-white text-xs shrink-0">!</span>
          )}
          <p className={`text-sm font-medium ${snackbar.severity === 'success' ? 'text-green-800' : 'text-red-800'}`}>
            {snackbar.message}
          </p>
          <button
            type="button"
            onClick={() => setSnackbar((s) => ({ ...s, open: false }))}
            className="ml-1 rounded p-1 opacity-70 hover:opacity-100"
            aria-label="Close"
          >
            ×
          </button>
        </div>
      )}
    </div>
  );
};

export default Settings;
