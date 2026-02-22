// @ts-nocheck
'use client';
import React, { useState, useEffect } from 'react';
import {
  Typography, Box, Grid, Card, CardContent, TextField, Button,
  Switch, Divider, Alert, List, ListItem, ListItemText, ListItemSecondaryAction,
  Dialog, DialogTitle, DialogContent, DialogActions, Tooltip, IconButton,
  CircularProgress, Snackbar, Chip,
} from '@mui/material';
import {
  Person as PersonIcon, Security as SecurityIcon,
  Notifications as NotificationsIcon, Settings as SettingsIcon,
  Save as SaveIcon, Edit as EditIcon,
  WhatsApp as WhatsAppIcon, Storage as StorageIcon,
  InfoOutlined as InfoIcon, CheckCircle, Cancel as ErrorIcon,
  Visibility, VisibilityOff,
} from '@mui/icons-material';
import { useSelector } from 'react-redux';
import { RootState } from '@/store';
import apiService from '@/services/api';

const FIELD_SX = { '& .MuiOutlinedInput-root': { borderRadius: 2 } };

const FieldWithTooltip = ({ label, tooltip, children }: { label: string; tooltip: string; children: React.ReactNode }) => (
  <Box>
    <Box display="flex" alignItems="center" gap={0.5} mb={0.5}>
      <Typography variant="caption" sx={{ fontWeight: 600, color: 'text.secondary' }}>{label}</Typography>
      <Tooltip title={tooltip} arrow placement="top">
        <InfoIcon sx={{ fontSize: 14, color: 'text.disabled', cursor: 'help' }} />
      </Tooltip>
    </Box>
    {children}
  </Box>
);

const Settings: React.FC = () => {
  const { user } = useSelector((state: RootState) => state.auth);

  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [snackbar, setSnackbar] = useState({ open: false, message: '', severity: 'success' as 'success' | 'error' });
  const [passwordDialogOpen, setPasswordDialogOpen] = useState(false);
  const [passwordForm, setPasswordForm] = useState({ currentPassword: '', newPassword: '', confirmPassword: '' });
  const [showSecrets, setShowSecrets] = useState<Record<string, boolean>>({});

  // Settings state
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

  // Load settings on mount
  useEffect(() => {
    loadSettings();
  }, []);

  const loadSettings = async () => {
    try {
      setLoading(true);
      const { settings } = await apiService.getSettings();
      if (settings) {
        setWhatsapp(prev => ({
          whatsapp_api_token: settings.whatsapp_api_token || prev.whatsapp_api_token,
          whatsapp_phone_number_id: settings.whatsapp_phone_number_id || prev.whatsapp_phone_number_id,
          whatsapp_webhook_secret: settings.whatsapp_webhook_secret || prev.whatsapp_webhook_secret,
          whatsapp_business_account_id: settings.whatsapp_business_account_id || prev.whatsapp_business_account_id,
          meta_app_secret: settings.meta_app_secret || prev.meta_app_secret,
        }));
        setCompany(prev => ({
          company_name: settings.company_name || prev.company_name,
          company_email: settings.company_email || prev.company_email,
          company_phone: settings.company_phone || prev.company_phone,
          company_address: settings.company_address || prev.company_address,
        }));
        setNotifications(prev => ({
          notif_email: settings.notif_email || prev.notif_email,
          notif_sms: settings.notif_sms || prev.notif_sms,
          notif_push: settings.notif_push || prev.notif_push,
          notif_order_alerts: settings.notif_order_alerts || prev.notif_order_alerts,
          notif_payment_alerts: settings.notif_payment_alerts || prev.notif_payment_alerts,
        }));
        setSystem(prev => ({
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
    } catch (err: any) {
      setSnackbar({ open: true, message: err.response?.data?.error || 'Failed to save settings', severity: 'error' });
    } finally {
      setSaving(false);
    }
  };

  const toggleSecret = (key: string) => {
    setShowSecrets(prev => ({ ...prev, [key]: !prev[key] }));
  };

  const handlePasswordChange = () => {
    setPasswordDialogOpen(false);
    setPasswordForm({ currentPassword: '', newPassword: '', confirmPassword: '' });
  };

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="60vh">
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box>
      <Box sx={{ mb: 3 }}>
        <Typography variant="h4" sx={{ fontWeight: 600, color: '#202124', mb: 0.5 }}>Settings</Typography>
        <Typography variant="body1" sx={{ color: 'text.secondary' }}>
          Manage API credentials, company info, and application configuration
        </Typography>
      </Box>

      <Grid container spacing={3}>

        {/* ========== SUPABASE CONNECTION STATUS ========== */}
        <Grid item xs={12}>
          <Card sx={{ borderRadius: 3, boxShadow: '0 1px 3px rgba(0,0,0,0.08)' }}>
            <CardContent sx={{ p: 3 }}>
              <Box display="flex" alignItems="center" mb={2}>
                <Box sx={{ width: 48, height: 48, borderRadius: 2.5, bgcolor: 'rgba(52, 168, 83, 0.1)', display: 'flex', alignItems: 'center', justifyContent: 'center', mr: 2 }}>
                  <StorageIcon sx={{ color: '#34A853', fontSize: 24 }} />
                </Box>
                <Box flex={1}>
                  <Typography variant="h6" sx={{ fontWeight: 600 }}>Supabase Connection</Typography>
                  <Typography variant="caption" sx={{ color: 'text.secondary' }}>Database connection status — configured via environment variables</Typography>
                </Box>
                <Chip icon={<CheckCircle />} label="Configured" color="success" variant="outlined" size="small" />
              </Box>
              <Alert severity="info" sx={{ borderRadius: 2 }}>
                Supabase URL and API keys are set via environment variables (Vercel dashboard or <code>.env.local</code>). They cannot be changed from this page for security reasons — the app needs them to boot.
              </Alert>
            </CardContent>
          </Card>
        </Grid>

        {/* ========== WHATSAPP BUSINESS API ========== */}
        <Grid item xs={12}>
          <Card sx={{ borderRadius: 3, boxShadow: '0 1px 3px rgba(0,0,0,0.08)' }}>
            <CardContent sx={{ p: 3 }}>
              <Box display="flex" alignItems="center" mb={3}>
                <Box sx={{ width: 48, height: 48, borderRadius: 2.5, bgcolor: 'rgba(37, 211, 102, 0.1)', display: 'flex', alignItems: 'center', justifyContent: 'center', mr: 2 }}>
                  <WhatsAppIcon sx={{ color: '#25D366', fontSize: 24 }} />
                </Box>
                <Box>
                  <Typography variant="h6" sx={{ fontWeight: 600 }}>WhatsApp Business API</Typography>
                  <Typography variant="caption" sx={{ color: 'text.secondary' }}>
                    Credentials for the Meta WhatsApp Business Platform. Changes take effect immediately.
                  </Typography>
                </Box>
              </Box>

              <Grid container spacing={2}>
                <Grid item xs={12} md={6}>
                  <FieldWithTooltip label="API Token" tooltip="The permanent access token from Meta Business Suite → System Users → Generate Token. Starts with 'EAA...'">
                    <TextField
                      fullWidth size="small" placeholder="EAAxxxxxxx..."
                      type={showSecrets.whatsapp_api_token ? 'text' : 'password'}
                      value={whatsapp.whatsapp_api_token}
                      onChange={(e) => setWhatsapp({ ...whatsapp, whatsapp_api_token: e.target.value })}
                      sx={FIELD_SX}
                      slotProps={{
                        input: {
                          endAdornment: (
                            <IconButton size="small" onClick={() => toggleSecret('whatsapp_api_token')}>
                              {showSecrets.whatsapp_api_token ? <VisibilityOff fontSize="small" /> : <Visibility fontSize="small" />}
                            </IconButton>
                          ),
                        }
                      }}
                    />
                  </FieldWithTooltip>
                </Grid>
                <Grid item xs={12} md={6}>
                  <FieldWithTooltip label="Phone Number ID" tooltip="Found in Meta Business Suite → WhatsApp → Getting Started → Phone Number ID. A numeric string like '1234567890'.">
                    <TextField
                      fullWidth size="small" placeholder="1234567890"
                      value={whatsapp.whatsapp_phone_number_id}
                      onChange={(e) => setWhatsapp({ ...whatsapp, whatsapp_phone_number_id: e.target.value })}
                      sx={FIELD_SX}
                    />
                  </FieldWithTooltip>
                </Grid>
                <Grid item xs={12} md={6}>
                  <FieldWithTooltip label="Webhook Verify Token" tooltip="A custom secret string YOU create. Enter the same value here and in Meta's webhook configuration page so they can verify each other.">
                    <TextField
                      fullWidth size="small" placeholder="my-secret-verify-token"
                      type={showSecrets.whatsapp_webhook_secret ? 'text' : 'password'}
                      value={whatsapp.whatsapp_webhook_secret}
                      onChange={(e) => setWhatsapp({ ...whatsapp, whatsapp_webhook_secret: e.target.value })}
                      sx={FIELD_SX}
                      slotProps={{
                        input: {
                          endAdornment: (
                            <IconButton size="small" onClick={() => toggleSecret('whatsapp_webhook_secret')}>
                              {showSecrets.whatsapp_webhook_secret ? <VisibilityOff fontSize="small" /> : <Visibility fontSize="small" />}
                            </IconButton>
                          ),
                        }
                      }}
                    />
                  </FieldWithTooltip>
                </Grid>
                <Grid item xs={12} md={6}>
                  <FieldWithTooltip label="Business Account ID" tooltip="Found in Meta Business Suite → Business Settings → Business Info. A numeric ID for your WhatsApp Business Account.">
                    <TextField
                      fullWidth size="small" placeholder="9876543210"
                      value={whatsapp.whatsapp_business_account_id}
                      onChange={(e) => setWhatsapp({ ...whatsapp, whatsapp_business_account_id: e.target.value })}
                      sx={FIELD_SX}
                    />
                  </FieldWithTooltip>
                </Grid>
                <Grid item xs={12} md={6}>
                  <FieldWithTooltip label="Meta App Secret" tooltip="Found in Meta Developers → Your App → Settings → Basic → App Secret. Used to verify webhook signatures for security.">
                    <TextField
                      fullWidth size="small" placeholder="abcdef123456..."
                      type={showSecrets.meta_app_secret ? 'text' : 'password'}
                      value={whatsapp.meta_app_secret}
                      onChange={(e) => setWhatsapp({ ...whatsapp, meta_app_secret: e.target.value })}
                      sx={FIELD_SX}
                      slotProps={{
                        input: {
                          endAdornment: (
                            <IconButton size="small" onClick={() => toggleSecret('meta_app_secret')}>
                              {showSecrets.meta_app_secret ? <VisibilityOff fontSize="small" /> : <Visibility fontSize="small" />}
                            </IconButton>
                          ),
                        }
                      }}
                    />
                  </FieldWithTooltip>
                </Grid>
              </Grid>
            </CardContent>
          </Card>
        </Grid>

        {/* ========== PROFILE ========== */}
        <Grid item xs={12} md={6}>
          <Card sx={{ borderRadius: 3, boxShadow: '0 1px 3px rgba(0,0,0,0.08)', height: '100%' }}>
            <CardContent sx={{ p: 3 }}>
              <Box display="flex" alignItems="center" mb={3}>
                <Box sx={{ width: 48, height: 48, borderRadius: 2.5, bgcolor: 'rgba(26, 115, 232, 0.1)', display: 'flex', alignItems: 'center', justifyContent: 'center', mr: 2 }}>
                  <PersonIcon sx={{ color: '#1A73E8', fontSize: 24 }} />
                </Box>
                <Box>
                  <Typography variant="h6" sx={{ fontWeight: 600 }}>Profile</Typography>
                  <Typography variant="caption" sx={{ color: 'text.secondary' }}>Your admin account info</Typography>
                </Box>
              </Box>
              <Box sx={{ bgcolor: '#F8F9FA', p: 3, borderRadius: 2, mb: 3 }}>
                <Typography variant="body2" sx={{ mb: 1.5 }}><strong>Email:</strong> {user?.email || 'Admin'}</Typography>
                <Typography variant="body2" sx={{ mb: 1.5 }}><strong>Role:</strong> {user?.role || 'super_admin'}</Typography>
                <Typography variant="body2"><strong>Last Login:</strong> {new Date().toLocaleDateString()}</Typography>
              </Box>
              <Button variant="outlined" startIcon={<EditIcon />} onClick={() => setPasswordDialogOpen(true)} fullWidth sx={{ borderRadius: 2, fontWeight: 600 }}>
                Change Password
              </Button>
            </CardContent>
          </Card>
        </Grid>

        {/* ========== COMPANY INFO ========== */}
        <Grid item xs={12} md={6}>
          <Card sx={{ borderRadius: 3, boxShadow: '0 1px 3px rgba(0,0,0,0.08)', height: '100%' }}>
            <CardContent sx={{ p: 3 }}>
              <Box display="flex" alignItems="center" mb={3}>
                <Box sx={{ width: 48, height: 48, borderRadius: 2.5, bgcolor: 'rgba(251, 188, 5, 0.1)', display: 'flex', alignItems: 'center', justifyContent: 'center', mr: 2 }}>
                  <SettingsIcon sx={{ color: '#FBBC05', fontSize: 24 }} />
                </Box>
                <Box>
                  <Typography variant="h6" sx={{ fontWeight: 600 }}>Company Information</Typography>
                  <Typography variant="caption" sx={{ color: 'text.secondary' }}>Update your business details</Typography>
                </Box>
              </Box>
              <Grid container spacing={2}>
                <Grid item xs={12}>
                  <FieldWithTooltip label="Company Name" tooltip="The name displayed on invoices, WhatsApp messages, and the landing page.">
                    <TextField fullWidth size="small" value={company.company_name} onChange={(e) => setCompany({ ...company, company_name: e.target.value })} sx={FIELD_SX} />
                  </FieldWithTooltip>
                </Grid>
                <Grid item xs={12}>
                  <FieldWithTooltip label="Email" tooltip="Support email shown to customers and in the footer of the website.">
                    <TextField fullWidth size="small" value={company.company_email} onChange={(e) => setCompany({ ...company, company_email: e.target.value })} sx={FIELD_SX} />
                  </FieldWithTooltip>
                </Grid>
                <Grid item xs={12}>
                  <FieldWithTooltip label="Phone" tooltip="Business phone number for customer inquiries.">
                    <TextField fullWidth size="small" value={company.company_phone} onChange={(e) => setCompany({ ...company, company_phone: e.target.value })} sx={FIELD_SX} />
                  </FieldWithTooltip>
                </Grid>
                <Grid item xs={12}>
                  <FieldWithTooltip label="Address" tooltip="Physical business address shown on invoices and the website.">
                    <TextField fullWidth size="small" multiline rows={2} value={company.company_address} onChange={(e) => setCompany({ ...company, company_address: e.target.value })} sx={FIELD_SX} />
                  </FieldWithTooltip>
                </Grid>
              </Grid>
            </CardContent>
          </Card>
        </Grid>

        {/* ========== NOTIFICATIONS ========== */}
        <Grid item xs={12} md={6}>
          <Card sx={{ borderRadius: 3, boxShadow: '0 1px 3px rgba(0,0,0,0.08)', height: '100%' }}>
            <CardContent sx={{ p: 3 }}>
              <Box display="flex" alignItems="center" mb={3}>
                <Box sx={{ width: 48, height: 48, borderRadius: 2.5, bgcolor: 'rgba(52, 168, 83, 0.1)', display: 'flex', alignItems: 'center', justifyContent: 'center', mr: 2 }}>
                  <NotificationsIcon sx={{ color: '#34A853', fontSize: 24 }} />
                </Box>
                <Box>
                  <Typography variant="h6" sx={{ fontWeight: 600 }}>Notifications</Typography>
                  <Typography variant="caption" sx={{ color: 'text.secondary' }}>Configure alert preferences</Typography>
                </Box>
              </Box>
              <List disablePadding>
                {[
                  { key: 'notif_email', label: 'Email Notifications', desc: 'Receive updates via email', tip: 'Sends daily summaries and alerts to the company email address above.' },
                  { key: 'notif_sms', label: 'SMS Notifications', desc: 'Receive SMS alerts', tip: 'Sends critical alerts (e.g., large orders, system issues) via SMS.' },
                  { key: 'notif_push', label: 'Push Notifications', desc: 'Browser push alerts', tip: 'Shows real-time browser notifications for new orders and messages.' },
                  { key: 'notif_order_alerts', label: 'Order Alerts', desc: 'New order notifications', tip: 'Notifies when a new order comes in via WhatsApp or the website.' },
                  { key: 'notif_payment_alerts', label: 'Payment Alerts', desc: 'Payment updates', tip: 'Notifies when a payment status changes (paid, overdue, etc.).' },
                ].map((item, idx) => (
                  <React.Fragment key={item.key}>
                    {idx > 0 && <Divider />}
                    <ListItem sx={{ px: 0, py: 1.5, borderRadius: 2, '&:hover': { bgcolor: '#F8F9FA' } }}>
                      <ListItemText
                        primary={
                          <Box display="flex" alignItems="center" gap={0.5}>
                            {item.label}
                            <Tooltip title={item.tip} arrow><InfoIcon sx={{ fontSize: 14, color: 'text.disabled' }} /></Tooltip>
                          </Box>
                        }
                        secondary={item.desc}
                        primaryTypographyProps={{ fontWeight: 500 }}
                      />
                      <ListItemSecondaryAction>
                        <Switch
                          checked={notifications[item.key as keyof typeof notifications] === 'true'}
                          onChange={(e) => setNotifications({ ...notifications, [item.key]: e.target.checked ? 'true' : 'false' })}
                          sx={{ mr: -1 }}
                        />
                      </ListItemSecondaryAction>
                    </ListItem>
                  </React.Fragment>
                ))}
              </List>
            </CardContent>
          </Card>
        </Grid>

        {/* ========== SYSTEM SETTINGS ========== */}
        <Grid item xs={12} md={6}>
          <Card sx={{ borderRadius: 3, boxShadow: '0 1px 3px rgba(0,0,0,0.08)', height: '100%' }}>
            <CardContent sx={{ p: 3 }}>
              <Box display="flex" alignItems="center" mb={3}>
                <Box sx={{ width: 48, height: 48, borderRadius: 2.5, bgcolor: 'rgba(147, 52, 234, 0.1)', display: 'flex', alignItems: 'center', justifyContent: 'center', mr: 2 }}>
                  <SecurityIcon sx={{ color: '#9334EA', fontSize: 24 }} />
                </Box>
                <Box>
                  <Typography variant="h6" sx={{ fontWeight: 600 }}>System Settings</Typography>
                  <Typography variant="caption" sx={{ color: 'text.secondary' }}>Configure app behavior</Typography>
                </Box>
              </Box>
              <List disablePadding>
                {[
                  { key: 'auto_assign_orders', label: 'Auto-Assign Orders', desc: 'Auto-assign to nearest vendor', tip: 'When enabled, new orders are automatically assigned to the nearest available vendor instead of waiting for manual assignment.' },
                  { key: 'require_vendor_approval', label: 'Require Vendor Approval', desc: 'Manual approval for new vendors', tip: 'When enabled, newly registered vendors must be manually approved by an admin before they can receive orders.' },
                  { key: 'enable_customer_signup', label: 'Customer Self-Registration', desc: 'Allow customers to register', tip: 'Allows customers to create accounts themselves via WhatsApp. Disable to only accept admin-created customers.' },
                  { key: 'maintenance_mode', label: 'Maintenance Mode', desc: 'Temporarily disable ordering', tip: 'Puts the system in read-only mode. The WhatsApp bot will inform customers that service is temporarily unavailable.' },
                ].map((item, idx) => (
                  <React.Fragment key={item.key}>
                    {idx > 0 && <Divider />}
                    <ListItem sx={{ px: 0, py: 1.5, borderRadius: 2, '&:hover': { bgcolor: '#F8F9FA' } }}>
                      <ListItemText
                        primary={
                          <Box display="flex" alignItems="center" gap={0.5}>
                            {item.label}
                            <Tooltip title={item.tip} arrow><InfoIcon sx={{ fontSize: 14, color: 'text.disabled' }} /></Tooltip>
                          </Box>
                        }
                        secondary={item.desc}
                        primaryTypographyProps={{ fontWeight: 500 }}
                      />
                      <ListItemSecondaryAction>
                        <Switch
                          checked={system[item.key as keyof typeof system] === 'true'}
                          onChange={(e) => setSystem({ ...system, [item.key]: e.target.checked ? 'true' : 'false' })}
                          sx={{ mr: -1 }}
                          color={item.key === 'maintenance_mode' ? 'warning' : 'primary'}
                        />
                      </ListItemSecondaryAction>
                    </ListItem>
                  </React.Fragment>
                ))}
              </List>
            </CardContent>
          </Card>
        </Grid>

        {/* ========== SAVE BUTTON ========== */}
        <Grid item xs={12}>
          <Box display="flex" justifyContent="flex-end" sx={{ mt: 1 }}>
            <Button
              variant="contained"
              startIcon={saving ? <CircularProgress size={18} color="inherit" /> : <SaveIcon />}
              onClick={handleSave}
              disabled={saving}
              size="large"
              sx={{ borderRadius: 2, fontWeight: 600, px: 4 }}
            >
              {saving ? 'Saving...' : 'Save All Settings'}
            </Button>
          </Box>
        </Grid>
      </Grid>

      {/* Password Dialog */}
      <Dialog open={passwordDialogOpen} onClose={() => setPasswordDialogOpen(false)} maxWidth="sm" fullWidth PaperProps={{ sx: { borderRadius: 3 } }}>
        <DialogTitle sx={{ fontWeight: 600 }}>Change Password</DialogTitle>
        <DialogContent>
          <TextField fullWidth label="Current Password" type="password" value={passwordForm.currentPassword}
            onChange={(e) => setPasswordForm({ ...passwordForm, currentPassword: e.target.value })}
            sx={{ mt: 2, ...FIELD_SX }} />
          <TextField fullWidth label="New Password" type="password" value={passwordForm.newPassword}
            onChange={(e) => setPasswordForm({ ...passwordForm, newPassword: e.target.value })}
            sx={{ mt: 2, ...FIELD_SX }} />
          <TextField fullWidth label="Confirm New Password" type="password" value={passwordForm.confirmPassword}
            onChange={(e) => setPasswordForm({ ...passwordForm, confirmPassword: e.target.value })}
            sx={{ mt: 2, ...FIELD_SX }} />
        </DialogContent>
        <DialogActions sx={{ p: 2.5, pt: 0 }}>
          <Button onClick={() => setPasswordDialogOpen(false)} sx={{ borderRadius: 2 }}>Cancel</Button>
          <Button variant="contained" onClick={handlePasswordChange} sx={{ borderRadius: 2, fontWeight: 600 }}>Update Password</Button>
        </DialogActions>
      </Dialog>

      {/* Snackbar */}
      <Snackbar
        open={snackbar.open}
        autoHideDuration={4000}
        onClose={() => setSnackbar({ ...snackbar, open: false })}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
      >
        <Alert onClose={() => setSnackbar({ ...snackbar, open: false })} severity={snackbar.severity} sx={{ borderRadius: 2 }}>
          {snackbar.message}
        </Alert>
      </Snackbar>
    </Box>
  );
};

export default Settings;
