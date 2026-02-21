// @ts-nocheck
import React, { useState } from 'react';
import {
  Typography,
  Box,
  Paper,
  Grid,
  Card,
  CardContent,
  TextField,
  Button,
  Switch,
  FormControlLabel,
  Divider,
  Alert,
  List,
  ListItem,
  ListItemText,
  ListItemSecondaryAction,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
} from '@mui/material';
import {
  Person as PersonIcon,
  Security as SecurityIcon,
  Notifications as NotificationsIcon,
  Settings as SettingsIcon,
  Save as SaveIcon,
  Edit as EditIcon,
  Lock as LockIcon,
  Smartphone as SmartphoneIcon,
  AdminPanelSettings as AdminIcon,
} from '@mui/icons-material';
import { useSelector } from 'react-redux';
import { RootState } from '../store';

const Settings: React.FC = () => {
  const { user } = useSelector((state: RootState) => state.auth);

  const [passwordDialogOpen, setPasswordDialogOpen] = useState(false);
  const [passwordForm, setPasswordForm] = useState({
    currentPassword: '',
    newPassword: '',
    confirmPassword: '',
  });
  const [notifications, setNotifications] = useState({
    emailNotifications: true,
    smsNotifications: false,
    pushNotifications: true,
    orderAlerts: true,
    paymentAlerts: true,
    systemAlerts: false,
  });
  const [systemSettings, setSystemSettings] = useState({
    autoAssignOrders: false,
    requireApproval: true,
    enableCustomerSignup: true,
    maintenanceMode: false,
  });
  const [companyInfo, setCompanyInfo] = useState({
    name: 'Can Can Water Delivery',
    email: 'support@cancan.com',
    phone: '+91-9876543210',
    address: '123 Main St, Mumbai, India 400001',
  });

  const handlePasswordChange = () => {
    setPasswordDialogOpen(false);
    setPasswordForm({ currentPassword: '', newPassword: '', confirmPassword: '' });
  };

  const handleSaveSettings = () => {
    alert('Settings saved successfully!');
  };

  return (
    <Box>
      {/* Header */}
      <Box sx={{ mb: 3 }}>
        <Typography variant="h4" sx={{ fontWeight: 600, color: '#202124', mb: 0.5 }}>
          Settings
        </Typography>
        <Typography variant="body1" sx={{ color: 'text.secondary' }}>
          Manage your account and application settings
        </Typography>
      </Box>

      <Grid container spacing={3}>
        {/* Profile Settings */}
        <Grid item xs={12} md={6}>
          <Card
            sx={{
              borderRadius: 3,
              boxShadow: '0 1px 3px rgba(0,0,0,0.08)',
              height: '100%',
            }}
          >
            <CardContent sx={{ p: 3 }}>
              <Box display="flex" alignItems="center" mb={3}>
                <Box
                  sx={{
                    width: 48,
                    height: 48,
                    borderRadius: 2.5,
                    bgcolor: 'rgba(26, 115, 232, 0.1)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    mr: 2,
                  }}
                >
                  <PersonIcon sx={{ color: '#1A73E8', fontSize: 24 }} />
                </Box>
                <Box>
                  <Typography variant="h6" sx={{ fontWeight: 600 }}>Profile Settings</Typography>
                  <Typography variant="caption" sx={{ color: 'text.secondary' }}>
                    Manage your profile information
                  </Typography>
                </Box>
              </Box>
              <Box sx={{ bgcolor: '#F8F9FA', p: 3, borderRadius: 2, mb: 3 }}>
                <Typography variant="body2" sx={{ mb: 1.5 }}><strong>Name:</strong> {user?.name || 'Admin User'}</Typography>
                <Typography variant="body2" sx={{ mb: 1.5 }}><strong>Email:</strong> {user?.email || 'you@example.com'}</Typography>
                <Typography variant="body2" sx={{ mb: 1.5 }}><strong>Role:</strong> {user?.role || 'Administrator'}</Typography>
                <Typography variant="body2"><strong>Last Login:</strong> {new Date().toLocaleDateString()}</Typography>
              </Box>
              <Button
                variant="outlined"
                startIcon={<EditIcon />}
                onClick={() => setPasswordDialogOpen(true)}
                fullWidth
                sx={{ borderRadius: 2, fontWeight: 600 }}
              >
                Change Password
              </Button>
            </CardContent>
          </Card>
        </Grid>

        {/* Notification Settings */}
        <Grid item xs={12} md={6}>
          <Card
            sx={{
              borderRadius: 3,
              boxShadow: '0 1px 3px rgba(0,0,0,0.08)',
              height: '100%',
            }}
          >
            <CardContent sx={{ p: 3 }}>
              <Box display="flex" alignItems="center" mb={3}>
                <Box
                  sx={{
                    width: 48,
                    height: 48,
                    borderRadius: 2.5,
                    bgcolor: 'rgba(52, 168, 83, 0.1)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    mr: 2,
                  }}
                >
                  <NotificationsIcon sx={{ color: '#34A853', fontSize: 24 }} />
                </Box>
                <Box>
                  <Typography variant="h6" sx={{ fontWeight: 600 }}>Notification Settings</Typography>
                  <Typography variant="caption" sx={{ color: 'text.secondary' }}>
                    Configure your notification preferences
                  </Typography>
                </Box>
              </Box>
              <List disablePadding>
                <ListItem
                  sx={{
                    px: 0,
                    py: 1.5,
                    borderRadius: 2,
                    '&:hover': { bgcolor: '#F8F9FA' },
                  }}
                >
                  <ListItemText
                    primary="Email Notifications"
                    secondary="Receive updates via email"
                    primaryTypographyProps={{ fontWeight: 500 }}
                  />
                  <ListItemSecondaryAction>
                    <Switch
                      checked={notifications.emailNotifications}
                      onChange={(e) => setNotifications({...notifications, emailNotifications: e.target.checked})}
                      sx={{ mr: -1 }}
                    />
                  </ListItemSecondaryAction>
                </ListItem>
                <Divider />
                <ListItem
                  sx={{
                    px: 0,
                    py: 1.5,
                    borderRadius: 2,
                    '&:hover': { bgcolor: '#F8F9FA' },
                  }}
                >
                  <ListItemText
                    primary="SMS Notifications"
                    secondary="Receive SMS alerts"
                    primaryTypographyProps={{ fontWeight: 500 }}
                  />
                  <ListItemSecondaryAction>
                    <Switch
                      checked={notifications.smsNotifications}
                      onChange={(e) => setNotifications({...notifications, smsNotifications: e.target.checked})}
                      sx={{ mr: -1 }}
                    />
                  </ListItemSecondaryAction>
                </ListItem>
                <Divider />
                <ListItem
                  sx={{
                    px: 0,
                    py: 1.5,
                    borderRadius: 2,
                    '&:hover': { bgcolor: '#F8F9FA' },
                  }}
                >
                  <ListItemText
                    primary="Push Notifications"
                    secondary="Browser push notifications"
                    primaryTypographyProps={{ fontWeight: 500 }}
                  />
                  <ListItemSecondaryAction>
                    <Switch
                      checked={notifications.pushNotifications}
                      onChange={(e) => setNotifications({...notifications, pushNotifications: e.target.checked})}
                      sx={{ mr: -1 }}
                    />
                  </ListItemSecondaryAction>
                </ListItem>
                <Divider sx={{ my: 2 }} />
                <ListItem
                  sx={{
                    px: 0,
                    py: 1.5,
                    borderRadius: 2,
                    '&:hover': { bgcolor: '#F8F9FA' },
                  }}
                >
                  <ListItemText
                    primary="Order Alerts"
                    secondary="New order notifications"
                    primaryTypographyProps={{ fontWeight: 500 }}
                  />
                  <ListItemSecondaryAction>
                    <Switch
                      checked={notifications.orderAlerts}
                      onChange={(e) => setNotifications({...notifications, orderAlerts: e.target.checked})}
                      sx={{ mr: -1 }}
                    />
                  </ListItemSecondaryAction>
                </ListItem>
                <Divider />
                <ListItem
                  sx={{
                    px: 0,
                    py: 1.5,
                    borderRadius: 2,
                    '&:hover': { bgcolor: '#F8F9FA' },
                  }}
                >
                  <ListItemText
                    primary="Payment Alerts"
                    secondary="Payment status updates"
                    primaryTypographyProps={{ fontWeight: 500 }}
                  />
                  <ListItemSecondaryAction>
                    <Switch
                      checked={notifications.paymentAlerts}
                      onChange={(e) => setNotifications({...notifications, paymentAlerts: e.target.checked})}
                      sx={{ mr: -1 }}
                    />
                  </ListItemSecondaryAction>
                </ListItem>
                <Divider />
                <ListItem
                  sx={{
                    px: 0,
                    py: 1.5,
                    borderRadius: 2,
                    '&:hover': { bgcolor: '#F8F9FA' },
                  }}
                >
                  <ListItemText
                    primary="System Alerts"
                    secondary="System maintenance"
                    primaryTypographyProps={{ fontWeight: 500 }}
                  />
                  <ListItemSecondaryAction>
                    <Switch
                      checked={notifications.systemAlerts}
                      onChange={(e) => setNotifications({...notifications, systemAlerts: e.target.checked})}
                      sx={{ mr: -1 }}
                    />
                  </ListItemSecondaryAction>
                </ListItem>
              </List>
            </CardContent>
          </Card>
        </Grid>

        {/* System Settings */}
        <Grid item xs={12} md={6}>
          <Card
            sx={{
              borderRadius: 3,
              boxShadow: '0 1px 3px rgba(0,0,0,0.08)',
              height: '100%',
            }}
          >
            <CardContent sx={{ p: 3 }}>
              <Box display="flex" alignItems="center" mb={3}>
                <Box
                  sx={{
                    width: 48,
                    height: 48,
                    borderRadius: 2.5,
                    bgcolor: 'rgba(147, 52, 234, 0.1)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    mr: 2,
                  }}
                >
                  <AdminIcon sx={{ color: '#9334EA', fontSize: 24 }} />
                </Box>
                <Box>
                  <Typography variant="h6" sx={{ fontWeight: 600 }}>System Settings</Typography>
                  <Typography variant="caption" sx={{ color: 'text.secondary' }}>
                    Configure system behavior
                  </Typography>
                </Box>
              </Box>
              <List disablePadding>
                <ListItem
                  sx={{
                    px: 0,
                    py: 1.5,
                    borderRadius: 2,
                    '&:hover': { bgcolor: '#F8F9FA' },
                  }}
                >
                  <ListItemText
                    primary="Auto-Assign Orders"
                    secondary="Automatically assign orders to vendors"
                    primaryTypographyProps={{ fontWeight: 500 }}
                  />
                  <ListItemSecondaryAction>
                    <Switch
                      checked={systemSettings.autoAssignOrders}
                      onChange={(e) => setSystemSettings({...systemSettings, autoAssignOrders: e.target.checked})}
                      sx={{ mr: -1 }}
                    />
                  </ListItemSecondaryAction>
                </ListItem>
                <Divider />
                <ListItem
                  sx={{
                    px: 0,
                    py: 1.5,
                    borderRadius: 2,
                    '&:hover': { bgcolor: '#F8F9FA' },
                  }}
                >
                  <ListItemText
                    primary="Require Approval"
                    secondary="Require manual approval for new vendors"
                    primaryTypographyProps={{ fontWeight: 500 }}
                  />
                  <ListItemSecondaryAction>
                    <Switch
                      checked={systemSettings.requireApproval}
                      onChange={(e) => setSystemSettings({...systemSettings, requireApproval: e.target.checked})}
                      sx={{ mr: -1 }}
                    />
                  </ListItemSecondaryAction>
                </ListItem>
                <Divider />
                <ListItem
                  sx={{
                    px: 0,
                    py: 1.5,
                    borderRadius: 2,
                    '&:hover': { bgcolor: '#F8F9FA' },
                  }}
                >
                  <ListItemText
                    primary="Customer Signup"
                    secondary="Allow customers to self-register"
                    primaryTypographyProps={{ fontWeight: 500 }}
                  />
                  <ListItemSecondaryAction>
                    <Switch
                      checked={systemSettings.enableCustomerSignup}
                      onChange={(e) => setSystemSettings({...systemSettings, enableCustomerSignup: e.target.checked})}
                      sx={{ mr: -1 }}
                    />
                  </ListItemSecondaryAction>
                </ListItem>
                <Divider />
                <ListItem
                  sx={{
                    px: 0,
                    py: 1.5,
                    borderRadius: 2,
                    '&:hover': { bgcolor: '#F8F9FA' },
                  }}
                >
                  <ListItemText
                    primary="Maintenance Mode"
                    secondary="Temporarily disable customer access"
                    primaryTypographyProps={{ fontWeight: 500 }}
                  />
                  <ListItemSecondaryAction>
                    <Switch
                      checked={systemSettings.maintenanceMode}
                      onChange={(e) => setSystemSettings({...systemSettings, maintenanceMode: e.target.checked})}
                      sx={{ mr: -1 }}
                    />
                  </ListItemSecondaryAction>
                </ListItem>
              </List>
            </CardContent>
          </Card>
        </Grid>

        {/* Company Information */}
        <Grid item xs={12} md={6}>
          <Card
            sx={{
              borderRadius: 3,
              boxShadow: '0 1px 3px rgba(0,0,0,0.08)',
              height: '100%',
            }}
          >
            <CardContent sx={{ p: 3 }}>
              <Box display="flex" alignItems="center" mb={3}>
                <Box
                  sx={{
                    width: 48,
                    height: 48,
                    borderRadius: 2.5,
                    bgcolor: 'rgba(251, 188, 5, 0.1)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    mr: 2,
                  }}
                >
                  <SettingsIcon sx={{ color: '#FBBC05', fontSize: 24 }} />
                </Box>
                <Box>
                  <Typography variant="h6" sx={{ fontWeight: 600 }}>Company Information</Typography>
                  <Typography variant="caption" sx={{ color: 'text.secondary' }}>
                    Update company details
                  </Typography>
                </Box>
              </Box>
              <Grid container spacing={2}>
                <Grid item xs={12}>
                  <TextField
                    fullWidth
                    label="Company Name"
                    value={companyInfo.name}
                    onChange={(e) => setCompanyInfo({...companyInfo, name: e.target.value})}
                    size="small"
                    sx={{ '& .MuiOutlinedInput-root': { borderRadius: 2 } }}
                  />
                </Grid>
                <Grid item xs={12}>
                  <TextField
                    fullWidth
                    label="Email Address"
                    value={companyInfo.email}
                    onChange={(e) => setCompanyInfo({...companyInfo, email: e.target.value})}
                    size="small"
                    sx={{ '& .MuiOutlinedInput-root': { borderRadius: 2 } }}
                  />
                </Grid>
                <Grid item xs={12}>
                  <TextField
                    fullWidth
                    label="Phone Number"
                    value={companyInfo.phone}
                    onChange={(e) => setCompanyInfo({...companyInfo, phone: e.target.value})}
                    size="small"
                    sx={{ '& .MuiOutlinedInput-root': { borderRadius: 2 } }}
                  />
                </Grid>
                <Grid item xs={12}>
                  <TextField
                    fullWidth
                    label="Address"
                    value={companyInfo.address}
                    onChange={(e) => setCompanyInfo({...companyInfo, address: e.target.value})}
                    multiline
                    rows={2}
                    size="small"
                    sx={{ '& .MuiOutlinedInput-root': { borderRadius: 2 } }}
                  />
                </Grid>
              </Grid>
            </CardContent>
          </Card>
        </Grid>

        {/* Security Settings */}
        <Grid item xs={12}>
          <Card
            sx={{
              borderRadius: 3,
              boxShadow: '0 1px 3px rgba(0,0,0,0.08)',
            }}
          >
            <CardContent sx={{ p: 3 }}>
              <Box display="flex" alignItems="center" mb={3}>
                <Box
                  sx={{
                    width: 48,
                    height: 48,
                    borderRadius: 2.5,
                    bgcolor: 'rgba(2, 136, 209, 0.1)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    mr: 2,
                  }}
                >
                  <SecurityIcon sx={{ color: '#0288D1', fontSize: 24 }} />
                </Box>
                <Box>
                  <Typography variant="h6" sx={{ fontWeight: 600 }}>Security Settings</Typography>
                  <Typography variant="caption" sx={{ color: 'text.secondary' }}>
                    Manage your account security
                  </Typography>
                </Box>
              </Box>
              <Alert
                severity="info"
                sx={{
                  mb: 3,
                  borderRadius: 2,
                  '& .MuiAlert-icon': { alignItems: 'center' },
                }}
              >
                Your account is protected with industry-standard encryption and security measures.
              </Alert>
              <Grid container spacing={3}>
                <Grid item xs={12} md={4}>
                  <Paper
                    sx={{
                      p: 3,
                      borderRadius: 2,
                      border: '1px solid #E8EAED',
                      bgcolor: '#F8F9FA',
                    }}
                  >
                    <Box display="flex" alignItems="center" gap={1.5} mb={2}>
                      <LockIcon sx={{ color: '#1A73E8' }} />
                      <Typography variant="subtitle2" sx={{ fontWeight: 600 }}>
                        Two-Factor Authentication
                      </Typography>
                    </Box>
                    <Typography variant="body2" sx={{ color: 'text.secondary', mb: 2 }}>
                      Add an extra layer of security to your account
                    </Typography>
                    <Button variant="outlined" size="small" sx={{ borderRadius: 2 }}>
                      Enable 2FA
                    </Button>
                  </Paper>
                </Grid>
                <Grid item xs={12} md={4}>
                  <Paper
                    sx={{
                      p: 3,
                      borderRadius: 2,
                      border: '1px solid #E8EAED',
                      bgcolor: '#F8F9FA',
                    }}
                  >
                    <Box display="flex" alignItems="center" gap={1.5} mb={2}>
                      <SmartphoneIcon sx={{ color: '#34A853' }} />
                      <Typography variant="subtitle2" sx={{ fontWeight: 600 }}>
                        Session Management
                      </Typography>
                    </Box>
                    <Typography variant="body2" sx={{ color: 'text.secondary', mb: 2 }}>
                      View and manage active sessions
                    </Typography>
                    <Button variant="outlined" size="small" sx={{ borderRadius: 2 }}>
                      Manage Sessions
                    </Button>
                  </Paper>
                </Grid>
                <Grid item xs={12} md={4}>
                  <Paper
                    sx={{
                      p: 3,
                      borderRadius: 2,
                      border: '1px solid #E8EAED',
                      bgcolor: '#F8F9FA',
                    }}
                  >
                    <Box display="flex" alignItems="center" gap={1.5} mb={2}>
                      <SettingsIcon sx={{ color: '#FBBC05' }} />
                      <Typography variant="subtitle2" sx={{ fontWeight: 600 }}>
                        API Keys
                      </Typography>
                    </Box>
                    <Typography variant="body2" sx={{ color: 'text.secondary', mb: 2 }}>
                      Generate and manage API access keys
                    </Typography>
                    <Button variant="outlined" size="small" sx={{ borderRadius: 2 }}>
                      Manage Keys
                    </Button>
                  </Paper>
                </Grid>
              </Grid>
            </CardContent>
          </Card>
        </Grid>

        {/* Save Settings Button */}
        <Grid item xs={12}>
          <Box display="flex" justifyContent="flex-end" sx={{ mt: 2 }}>
            <Button
              variant="contained"
              startIcon={<SaveIcon />}
              onClick={handleSaveSettings}
              size="large"
              sx={{ borderRadius: 2, fontWeight: 600 }}
            >
              Save All Settings
            </Button>
          </Box>
        </Grid>
      </Grid>

      {/* Change Password Dialog */}
      <Dialog
        open={passwordDialogOpen}
        onClose={() => setPasswordDialogOpen(false)}
        maxWidth="sm"
        fullWidth
        PaperProps={{ sx: { borderRadius: 3 } }}
      >
        <DialogTitle sx={{ fontWeight: 600 }}>Change Password</DialogTitle>
        <DialogContent>
          <TextField
            fullWidth
            label="Current Password"
            type="password"
            value={passwordForm.currentPassword}
            onChange={(e) => setPasswordForm({...passwordForm, currentPassword: e.target.value})}
            sx={{ mt: 2, '& .MuiOutlinedInput-root': { borderRadius: 2 } }}
          />
          <TextField
            fullWidth
            label="New Password"
            type="password"
            value={passwordForm.newPassword}
            onChange={(e) => setPasswordForm({...passwordForm, newPassword: e.target.value})}
            sx={{ mt: 2, '& .MuiOutlinedInput-root': { borderRadius: 2 } }}
          />
          <TextField
            fullWidth
            label="Confirm New Password"
            type="password"
            value={passwordForm.confirmPassword}
            onChange={(e) => setPasswordForm({...passwordForm, confirmPassword: e.target.value})}
            sx={{ mt: 2, '& .MuiOutlinedInput-root': { borderRadius: 2 } }}
          />
        </DialogContent>
        <DialogActions sx={{ p: 2.5, pt: 0 }}>
          <Button onClick={() => setPasswordDialogOpen(false)} sx={{ borderRadius: 2 }}>Cancel</Button>
          <Button variant="contained" onClick={handlePasswordChange} sx={{ borderRadius: 2, fontWeight: 600 }}>
            Update Password
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default Settings;
