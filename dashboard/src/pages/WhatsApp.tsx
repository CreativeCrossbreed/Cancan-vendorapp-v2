// @ts-nocheck
import React, { useEffect, useState } from 'react';
import {
  Typography,
  Box,
  Paper,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  TablePagination,
  Button,
  Chip,
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Alert,
  CircularProgress,
  Grid,
  Card,
  CardContent,
  Switch,
  FormControlLabel,
  Divider,
} from '@mui/material';
import {
  WhatsApp as WhatsAppIcon,
  Send as SendIcon,
  Message as MessageIcon,
  Phone as PhoneIcon,
  Settings as SettingsIcon,
  Refresh as RefreshIcon,
  CheckCircle as CheckCircleIcon,
  Error as ErrorIcon,
  Schedule as ScheduleIcon,
  ShoppingCart as ShoppingCartIcon,
} from '@mui/icons-material';
import { useDispatch, useSelector } from 'react-redux';
import { RootState, AppDispatch } from '../store';
import { fetchWhatsAppMessages, fetchWhatsAppOrders } from '../store/whatsappSlice';
import { WhatsAppMessage, WhatsAppOrder } from '../types';

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
  const [sendForm, setSendForm] = useState({
    to: '',
    message: '',
  });

  useEffect(() => {
    if (tab === 'messages') {
      dispatch(fetchWhatsAppMessages({
        page: page + 1,
        limit: rowsPerPage,
        direction: messageFilter !== 'all' ? messageFilter : undefined,
      }));
    } else {
      dispatch(fetchWhatsAppOrders({
        page: page + 1,
        limit: rowsPerPage,
        status: orderFilter !== 'all' ? orderFilter : undefined,
      }));
    }
  }, [dispatch, tab, page, rowsPerPage, messageFilter, orderFilter]);

  const handleChangePage = (event: unknown, newPage: number) => {
    setPage(newPage);
  };

  const handleChangeRowsPerPage = (event: React.ChangeEvent<HTMLInputElement>) => {
    setRowsPerPage(parseInt(event.target.value, 10));
    setPage(0);
  };

  const handleSendMessage = () => {
    setSendDialogOpen(false);
    setSendForm({ to: '', message: '' });
  };

  const handleViewMessage = (message: WhatsAppMessage) => {
    setSelectedMessage(message);
    setViewDialogOpen(true);
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'sent': return { bg: '#E8F5E9', text: '#2E7D32' };
      case 'pending': return { bg: '#FEF7E0', text: '#B45309' };
      case 'failed': return { bg: '#FFEBEE', text: '#C62828' };
      case 'delivered': return { bg: '#E1F5FE', text: '#0277BD' };
      default: return { bg: '#F5F5F5', text: '#616161' };
    }
  };

  const getOrderStatusColor = (status: string) => {
    switch (status) {
      case 'pending': return { bg: '#FEF7E0', text: '#B45309' };
      case 'confirmed': return { bg: '#E1F5FE', text: '#0277BD' };
      case 'processing': return { bg: '#F3E5F5', text: '#7B1FA2' };
      case 'completed': return { bg: '#E8F5E9', text: '#2E7D32' };
      case 'cancelled': return { bg: '#FFEBEE', text: '#C62828' };
      default: return { bg: '#F5F5F5', text: '#616161' };
    }
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  if (error) {
    return (
      <Box>
        <Typography variant="h4" sx={{ fontWeight: 600, mb: 2 }}>
          WhatsApp Integration
        </Typography>
        <Alert severity="error" sx={{ borderRadius: 2 }}>{error}</Alert>
      </Box>
    );
  }

  return (
    <Box>
      {/* Header */}
      <Box sx={{ mb: 3 }}>
        <Typography variant="h4" sx={{ fontWeight: 600, color: '#202124', mb: 0.5 }}>
          WhatsApp Integration
        </Typography>
        <Typography variant="body1" sx={{ color: 'text.secondary' }}>
          Manage WhatsApp messaging and orders
        </Typography>
      </Box>

      {/* Stats Cards */}
      <Grid container spacing={3} sx={{ mb: 3 }}>
        <Grid item xs={12} sm={6} md={3}>
          <Card
            sx={{
              borderRadius: 3,
              boxShadow: '0 1px 3px rgba(0,0,0,0.08)',
              '&:hover': { boxShadow: '0 4px 12px rgba(0,0,0,0.12)' },
              transition: 'box-shadow 0.2s',
            }}
          >
            <CardContent>
              <Box display="flex" alignItems="center" justifyContent="space-between">
                <Box>
                  <Typography variant="body2" sx={{ color: 'text.secondary', mb: 1, fontWeight: 500 }}>
                    API Status
                  </Typography>
                  {config?.connected ? (
                    <Chip label="Connected" sx={{ bgcolor: '#E8F5E9', color: '#2E7D32', fontWeight: 600 }} size="small" />
                  ) : (
                    <Chip label="Disconnected" sx={{ bgcolor: '#FFEBEE', color: '#C62828', fontWeight: 600 }} size="small" />
                  )}
                </Box>
                <Box
                  sx={{
                    width: 48,
                    height: 48,
                    borderRadius: 2.5,
                    bgcolor: config?.connected ? 'rgba(52, 168, 83, 0.1)' : 'rgba(234, 67, 53, 0.1)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                  }}
                >
                  <WhatsAppIcon sx={{ color: config?.connected ? '#34A853' : '#EA4335', fontSize: 24 }} />
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card
            sx={{
              borderRadius: 3,
              boxShadow: '0 1px 3px rgba(0,0,0,0.08)',
              '&:hover': { boxShadow: '0 4px 12px rgba(0,0,0,0.12)' },
              transition: 'box-shadow 0.2s',
            }}
          >
            <CardContent>
              <Box display="flex" alignItems="center" justifyContent="space-between">
                <Box>
                  <Typography variant="body2" sx={{ color: 'text.secondary', mb: 1, fontWeight: 500 }}>
                    Total Messages
                  </Typography>
                  <Typography variant="h4" sx={{ fontWeight: 700, color: '#202124' }}>
                    {messages.length}
                  </Typography>
                </Box>
                <Box
                  sx={{
                    width: 48,
                    height: 48,
                    borderRadius: 2.5,
                    bgcolor: 'rgba(26, 115, 232, 0.1)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                  }}
                >
                  <MessageIcon sx={{ color: '#1A73E8', fontSize: 24 }} />
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card
            sx={{
              borderRadius: 3,
              boxShadow: '0 1px 3px rgba(0,0,0,0.08)',
              '&:hover': { boxShadow: '0 4px 12px rgba(0,0,0,0.12)' },
              transition: 'box-shadow 0.2s',
            }}
          >
            <CardContent>
              <Box display="flex" alignItems="center" justifyContent="space-between">
                <Box>
                  <Typography variant="body2" sx={{ color: 'text.secondary', mb: 1, fontWeight: 500 }}>
                    Today's Messages
                  </Typography>
                  <Typography variant="h4" sx={{ fontWeight: 700, color: '#202124' }}>
                    {messages.filter(msg => new Date(msg.created_at).toDateString() === new Date().toDateString()).length}
                  </Typography>
                </Box>
                <Box
                  sx={{
                    width: 48,
                    height: 48,
                    borderRadius: 2.5,
                    bgcolor: 'rgba(2, 136, 209, 0.1)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                  }}
                >
                  <ScheduleIcon sx={{ color: '#0288D1', fontSize: 24 }} />
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card
            sx={{
              borderRadius: 3,
              boxShadow: '0 1px 3px rgba(0,0,0,0.08)',
              '&:hover': { boxShadow: '0 4px 12px rgba(0,0,0,0.12)' },
              transition: 'box-shadow 0.2s',
            }}
          >
            <CardContent>
              <Box display="flex" alignItems="center" justifyContent="space-between">
                <Box>
                  <Typography variant="body2" sx={{ color: 'text.secondary', mb: 1, fontWeight: 500 }}>
                    Pending Orders
                  </Typography>
                  <Typography variant="h4" sx={{ fontWeight: 700, color: '#202124' }}>
                    {orders.filter(order => order.status === 'pending').length}
                  </Typography>
                </Box>
                <Box
                  sx={{
                    width: 48,
                    height: 48,
                    borderRadius: 2.5,
                    bgcolor: 'rgba(251, 188, 5, 0.1)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                  }}
                >
                  <ShoppingCartIcon sx={{ color: '#FBBC05', fontSize: 24 }} />
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Action Buttons */}
      <Paper
        sx={{
          p: 2.5,
          mb: 2,
          borderRadius: 3,
          boxShadow: '0 1px 3px rgba(0,0,0,0.08)',
        }}
      >
        <Grid container spacing={2} alignItems="center">
          <Grid item xs={12}>
            <Box display="flex" gap={1.5} flexWrap="wrap">
              <Button
                variant={tab === 'messages' ? 'contained' : 'outlined'}
                onClick={() => setTab('messages')}
                sx={{ borderRadius: 2, fontWeight: 500 }}
              >
                Messages
              </Button>
              <Button
                variant={tab === 'orders' ? 'contained' : 'outlined'}
                onClick={() => setTab('orders')}
                sx={{ borderRadius: 2, fontWeight: 500 }}
              >
                WhatsApp Orders
              </Button>
              <Divider orientation="vertical" flexItem sx={{ mx: 1 }} />
              <Button
                variant="outlined"
                startIcon={<SendIcon />}
                onClick={() => setSendDialogOpen(true)}
                sx={{ borderRadius: 2, fontWeight: 500 }}
              >
                Send Message
              </Button>
              <Button
                variant="outlined"
                startIcon={<SettingsIcon />}
                onClick={() => setConfigDialogOpen(true)}
                sx={{ borderRadius: 2, fontWeight: 500 }}
              >
                Configuration
              </Button>
              <Button
                variant="outlined"
                startIcon={<RefreshIcon />}
                onClick={() => window.location.reload()}
                sx={{ borderRadius: 2, fontWeight: 500 }}
              >
                Refresh
              </Button>
            </Box>
          </Grid>
        </Grid>
      </Paper>

      {/* Filters */}
      <Paper
        sx={{
          p: 2.5,
          mb: 2,
          borderRadius: 3,
          boxShadow: '0 1px 3px rgba(0,0,0,0.08)',
        }}
      >
        <Grid container spacing={2} alignItems="center">
          {tab === 'messages' ? (
            <Grid item xs={12} md={3}>
              <FormControl fullWidth size="small">
                <InputLabel>Direction</InputLabel>
                <Select
                  value={messageFilter}
                  onChange={(e) => setMessageFilter(e.target.value)}
                  label="Direction"
                  sx={{ borderRadius: 2 }}
                >
                  <MenuItem value="all">All Messages</MenuItem>
                  <MenuItem value="inbound">Inbound</MenuItem>
                  <MenuItem value="outbound">Outbound</MenuItem>
                </Select>
              </FormControl>
            </Grid>
          ) : (
            <Grid item xs={12} md={3}>
              <FormControl fullWidth size="small">
                <InputLabel>Status</InputLabel>
                <Select
                  value={orderFilter}
                  onChange={(e) => setOrderFilter(e.target.value)}
                  label="Status"
                  sx={{ borderRadius: 2 }}
                >
                  <MenuItem value="all">All Orders</MenuItem>
                  <MenuItem value="pending">Pending</MenuItem>
                  <MenuItem value="confirmed">Confirmed</MenuItem>
                  <MenuItem value="processing">Processing</MenuItem>
                  <MenuItem value="completed">Completed</MenuItem>
                  <MenuItem value="cancelled">Cancelled</MenuItem>
                </Select>
              </FormControl>
            </Grid>
          )}
        </Grid>
      </Paper>

      {/* Data Table */}
      <Paper
        sx={{
          borderRadius: 3,
          boxShadow: '0 1px 3px rgba(0,0,0,0.08)',
          overflow: 'hidden',
        }}
      >
        <TableContainer>
          <Table>
            <TableHead>
              {tab === 'messages' ? (
                <TableRow>
                  <TableCell>Phone</TableCell>
                  <TableCell>Direction</TableCell>
                  <TableCell>Message</TableCell>
                  <TableCell>Status</TableCell>
                  <TableCell>Sent At</TableCell>
                  <TableCell>Actions</TableCell>
                </TableRow>
              ) : (
                <TableRow>
                  <TableCell>Order #</TableCell>
                  <TableCell>Customer</TableCell>
                  <TableCell>Phone</TableCell>
                  <TableCell>Items</TableCell>
                  <TableCell>Total</TableCell>
                  <TableCell>Status</TableCell>
                  <TableCell>Received</TableCell>
                  <TableCell>Actions</TableCell>
                </TableRow>
              )}
            </TableHead>
            <TableBody>
              {isLoading ? (
                <TableRow>
                  <TableCell colSpan={tab === 'messages' ? 6 : 8} align="center" sx={{ py: 4 }}>
                    <CircularProgress />
                  </TableCell>
                </TableRow>
              ) : (tab === 'messages' ? messages : orders).length === 0 ? (
                <TableRow>
                  <TableCell colSpan={tab === 'messages' ? 6 : 8} align="center" sx={{ py: 4 }}>
                    <Typography variant="body2" sx={{ color: 'text.secondary' }}>
                      No {tab === 'messages' ? 'messages' : 'orders'} found
                    </Typography>
                  </TableCell>
                </TableRow>
              ) : (
                (tab === 'messages' ? messages : orders).map((item) => (
                  <TableRow key={item.id} hover>
                    {tab === 'messages' ? (
                      <>
                        <TableCell>
                          <Box display="flex" alignItems="center" gap={1}>
                            <PhoneIcon fontSize="small" sx={{ color: 'text.secondary' }} />
                            <Typography variant="body2" sx={{ fontWeight: 500 }}>
                              {(item as WhatsAppMessage).phone}
                            </Typography>
                          </Box>
                        </TableCell>
                        <TableCell>
                          <Chip
                            label={(item as WhatsAppMessage).direction}
                            sx={{
                              bgcolor: (item as WhatsAppMessage).direction === 'inbound'
                                ? 'rgba(26, 115, 232, 0.1)'
                                : 'rgba(52, 168, 83, 0.1)',
                              color: (item as WhatsAppMessage).direction === 'inbound'
                                ? '#1A73E8'
                                : '#34A853',
                              fontWeight: 600,
                              fontSize: '0.75rem',
                            }}
                            size="small"
                          />
                        </TableCell>
                        <TableCell>
                          <Typography variant="body2" noWrap sx={{ maxWidth: 200 }}>
                            {(item as WhatsAppMessage).message}
                          </Typography>
                        </TableCell>
                        <TableCell>
                          <Chip
                            label={(item as WhatsAppMessage).status}
                            sx={{
                              bgcolor: getStatusColor((item as WhatsAppMessage).status).bg,
                              color: getStatusColor((item as WhatsAppMessage).status).text,
                              fontWeight: 600,
                              fontSize: '0.75rem',
                            }}
                            size="small"
                          />
                        </TableCell>
                        <TableCell>
                          <Typography variant="body2">
                            {formatDate((item as WhatsAppMessage).created_at)}
                          </Typography>
                        </TableCell>
                        <TableCell>
                          <IconButton
                            size="small"
                            onClick={() => handleViewMessage(item as WhatsAppMessage)}
                            sx={{ borderRadius: 2 }}
                          >
                            <MessageIcon fontSize="small" />
                          </IconButton>
                        </TableCell>
                      </>
                    ) : (
                      <>
                        <TableCell>
                          <Typography variant="subtitle2" sx={{ fontWeight: 600, color: '#1A73E8' }}>
                            #{(item as WhatsAppOrder).order_number}
                          </Typography>
                        </TableCell>
                        <TableCell>
                          <Typography variant="body2" sx={{ fontWeight: 500 }}>
                            {(item as WhatsAppOrder).customer_name}
                          </Typography>
                        </TableCell>
                        <TableCell>
                          <Typography variant="body2">
                            {(item as WhatsAppOrder).phone}
                          </Typography>
                        </TableCell>
                        <TableCell>
                          <Typography variant="body2">
                            {(item as WhatsAppOrder).items?.length || 0} items
                          </Typography>
                        </TableCell>
                        <TableCell>
                          <Typography variant="subtitle2" sx={{ fontWeight: 600 }}>
                            ₹{(item as WhatsAppOrder).total_amount || 0}
                          </Typography>
                        </TableCell>
                        <TableCell>
                          <Chip
                            label={(item as WhatsAppOrder).status}
                            sx={{
                              bgcolor: getOrderStatusColor((item as WhatsAppOrder).status).bg,
                              color: getOrderStatusColor((item as WhatsAppOrder).status).text,
                              fontWeight: 600,
                              fontSize: '0.75rem',
                            }}
                            size="small"
                          />
                        </TableCell>
                        <TableCell>
                          <Typography variant="body2">
                            {formatDate((item as WhatsAppOrder).created_at)}
                          </Typography>
                        </TableCell>
                        <TableCell>
                          <Button
                            size="small"
                            variant="outlined"
                            sx={{ borderRadius: 2, fontWeight: 500 }}
                          >
                            Process
                          </Button>
                        </TableCell>
                      </>
                    )}
                  </TableRow>
                ))
              )}
            </TableBody>
          </Table>
        </TableContainer>
        <TablePagination
          rowsPerPageOptions={[5, 10, 25, 50]}
          component="div"
          count={pagination?.total || 0}
          rowsPerPage={rowsPerPage}
          page={page}
          onPageChange={handleChangePage}
          onRowsPerPageChange={handleChangeRowsPerPage}
          sx={{ borderTop: '1px solid #E8EAED' }}
        />
      </Paper>

      {/* Send Message Dialog */}
      <Dialog
        open={sendDialogOpen}
        onClose={() => setSendDialogOpen(false)}
        maxWidth="sm"
        fullWidth
        PaperProps={{ sx: { borderRadius: 3 } }}
      >
        <DialogTitle sx={{ fontWeight: 600 }}>Send WhatsApp Message</DialogTitle>
        <DialogContent>
          <TextField
            fullWidth
            label="Phone Number"
            value={sendForm.to}
            onChange={(e) => setSendForm({ ...sendForm, to: e.target.value })}
            sx={{ mt: 2, '& .MuiOutlinedInput-root': { borderRadius: 2 } }}
            placeholder="+919876543210"
          />
          <TextField
            fullWidth
            label="Message"
            multiline
            rows={4}
            value={sendForm.message}
            onChange={(e) => setSendForm({ ...sendForm, message: e.target.value })}
            sx={{ mt: 2, '& .MuiOutlinedInput-root': { borderRadius: 2 } }}
            placeholder="Type your message here..."
          />
        </DialogContent>
        <DialogActions sx={{ p: 2.5, pt: 0 }}>
          <Button onClick={() => setSendDialogOpen(false)} sx={{ borderRadius: 2 }}>Cancel</Button>
          <Button variant="contained" onClick={handleSendMessage} sx={{ borderRadius: 2, fontWeight: 600 }}>
            Send Message
          </Button>
        </DialogActions>
      </Dialog>

      {/* Configuration Dialog */}
      <Dialog
        open={configDialogOpen}
        onClose={() => setConfigDialogOpen(false)}
        maxWidth="sm"
        fullWidth
        PaperProps={{ sx: { borderRadius: 3 } }}
      >
        <DialogTitle sx={{ fontWeight: 600 }}>WhatsApp Configuration</DialogTitle>
        <DialogContent>
          <FormControlLabel
            control={<Switch checked={config?.webhook_enabled || false} />}
            label="Webhook Enabled"
            sx={{ mt: 2 }}
          />
          <TextField
            fullWidth
            label="Webhook URL"
            value={config?.webhook_url || ''}
            sx={{ mt: 2, '& .MuiOutlinedInput-root': { borderRadius: 2 } }}
            placeholder="https://your-server.com/webhook"
          />
          <TextField
            fullWidth
            label="Access Token"
            type="password"
            value={config?.access_token || ''}
            sx={{ mt: 2, '& .MuiOutlinedInput-root': { borderRadius: 2 } }}
            placeholder="Enter WhatsApp API access token"
          />
          <TextField
            fullWidth
            label="Phone Number ID"
            value={config?.phone_number_id || ''}
            sx={{ mt: 2, '& .MuiOutlinedInput-root': { borderRadius: 2 } }}
            placeholder="Enter WhatsApp phone number ID"
          />
        </DialogContent>
        <DialogActions sx={{ p: 2.5, pt: 0 }}>
          <Button onClick={() => setConfigDialogOpen(false)} sx={{ borderRadius: 2 }}>Cancel</Button>
          <Button variant="contained" sx={{ borderRadius: 2, fontWeight: 600 }}>Save Configuration</Button>
        </DialogActions>
      </Dialog>

      {/* Message Details Dialog */}
      <Dialog
        open={viewDialogOpen}
        onClose={() => setViewDialogOpen(false)}
        maxWidth="sm"
        fullWidth
        PaperProps={{ sx: { borderRadius: 3 } }}
      >
        <DialogTitle sx={{ fontWeight: 600 }}>Message Details</DialogTitle>
        <DialogContent>
          {selectedMessage && (
            <Box sx={{ bgcolor: '#F8F9FA', p: 2.5, borderRadius: 2, mt: 1 }}>
              <Typography variant="body2" sx={{ mb: 1 }}><strong>Phone:</strong> {selectedMessage.phone}</Typography>
              <Typography variant="body2" sx={{ mb: 1 }}><strong>Direction:</strong> {selectedMessage.direction}</Typography>
              <Typography variant="body2" sx={{ mb: 1 }}><strong>Message:</strong> {selectedMessage.message}</Typography>
              <Typography variant="body2" sx={{ mb: 1, display: 'flex', alignItems: 'center', gap: 1 }}>
                <strong>Status:</strong>
                <Chip
                  label={selectedMessage.status}
                  sx={{
                    bgcolor: getStatusColor(selectedMessage.status).bg,
                    color: getStatusColor(selectedMessage.status).text,
                    fontWeight: 600,
                    fontSize: '0.75rem',
                  }}
                  size="small"
                />
              </Typography>
              <Typography variant="body2" sx={{ mb: 1 }}><strong>Message ID:</strong> {selectedMessage.whatsapp_message_id}</Typography>
              <Typography variant="body2"><strong>Sent At:</strong> {formatDate(selectedMessage.created_at)}</Typography>
            </Box>
          )}
        </DialogContent>
        <DialogActions sx={{ p: 2.5, pt: 0 }}>
          <Button onClick={() => setViewDialogOpen(false)} sx={{ borderRadius: 2 }}>Close</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default WhatsApp;
