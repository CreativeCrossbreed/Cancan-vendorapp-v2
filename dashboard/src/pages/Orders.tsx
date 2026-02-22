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
  Menu,
  Divider,
} from '@mui/material';
import {
  Add as AddIcon,
  MoreVert as MoreVertIcon,
  Edit as EditIcon,
  LocalShipping as LocalShippingIcon,
  Assignment as AssignmentIcon,
  Payment as PaymentIcon,
  Person as PersonIcon,
  Store as StoreIcon,
  Cancel as CancelIcon,
  CheckCircle as CheckCircleIcon,
  Schedule as ScheduleIcon,
} from '@mui/icons-material';
import { useDispatch, useSelector } from 'react-redux';
import { RootState, AppDispatch } from '../store';
import { fetchOrders } from '../store/orderSlice';
import { Order } from '../types';

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
    dispatch(fetchOrders({
      page: page + 1,
      limit: rowsPerPage,
      search: searchTerm || undefined,
      status: statusFilter !== 'all' ? statusFilter : undefined,
      payment_status: paymentFilter !== 'all' ? paymentFilter : undefined,
    }));
  }, [dispatch, page, rowsPerPage, searchTerm, statusFilter, paymentFilter]);

  const handleChangePage = (event: unknown, newPage: number) => {
    setPage(newPage);
  };

  const handleChangeRowsPerPage = (event: React.ChangeEvent<HTMLInputElement>) => {
    setRowsPerPage(parseInt(event.target.value, 10));
    setPage(0);
  };

  const handleSearch = (event: React.ChangeEvent<HTMLInputElement>) => {
    setSearchTerm(event.target.value);
    setPage(0);
  };

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

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'pending': return { bg: '#FEF7E0', text: '#B45309' };
      case 'confirmed': return { bg: '#E1F5FE', text: '#0277BD' };
      case 'assigned': return { bg: '#E8EAF6', text: '#37474F' };
      case 'picked_up': return { bg: '#F3E5F5', text: '#7B1FA2' };
      case 'delivered': return { bg: '#E8F5E9', text: '#2E7D32' };
      case 'cancelled': return { bg: '#FFEBEE', text: '#C62828' };
      default: return { bg: '#F5F5F5', text: '#616161' };
    }
  };

  const getPaymentStatusColor = (status: string) => {
    switch (status) {
      case 'paid': return { bg: '#E8F5E9', text: '#2E7D32' };
      case 'unpaid': return { bg: '#FEF7E0', text: '#B45309' };
      case 'refunded': return { bg: '#E1F5FE', text: '#0277BD' };
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

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-IN', {
      style: 'currency',
      currency: 'INR',
      minimumFractionDigits: 0,
    }).format(amount);
  };

  const todayOrders = orders.filter(order => {
    const orderDate = new Date(order.created_at).toDateString();
    return orderDate === new Date().toDateString();
  });

  const pendingOrders = orders.filter(order => order.status === 'pending');
  const deliveredOrders = orders.filter(order => order.status === 'delivered');
  const todayRevenue = todayOrders.reduce((sum, order) => sum + (order.total_amount || 0), 0);

  if (error) {
    return (
      <Box>
        <Typography variant="h4" sx={{ fontWeight: 600, mb: 2 }}>
          Orders Management
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
          Orders Management
        </Typography>
        <Typography variant="body1" sx={{ color: 'text.secondary' }}>
          Manage and track all water can delivery orders
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
                    Today's Orders
                  </Typography>
                  <Typography variant="h4" sx={{ fontWeight: 700, color: '#202124' }}>
                    {todayOrders.length}
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
                  <AssignmentIcon sx={{ color: '#1A73E8', fontSize: 24 }} />
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
                    {pendingOrders.length}
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
                  <ScheduleIcon sx={{ color: '#FBBC05', fontSize: 24 }} />
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
                    Delivered Today
                  </Typography>
                  <Typography variant="h4" sx={{ fontWeight: 700, color: '#202124' }}>
                    {deliveredOrders.length}
                  </Typography>
                </Box>
                <Box
                  sx={{
                    width: 48,
                    height: 48,
                    borderRadius: 2.5,
                    bgcolor: 'rgba(52, 168, 83, 0.1)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                  }}
                >
                  <CheckCircleIcon sx={{ color: '#34A853', fontSize: 24 }} />
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
                    Today's Revenue
                  </Typography>
                  <Typography variant="h4" sx={{ fontWeight: 700, color: '#202124' }}>
                    {formatCurrency(todayRevenue)}
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
                  <PaymentIcon sx={{ color: '#0288D1', fontSize: 24 }} />
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

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
          <Grid item xs={12} md={3}>
            <TextField
              fullWidth
              label="Search orders..."
              value={searchTerm}
              onChange={handleSearch}
              size="small"
              placeholder="Order #, Customer, Vendor"
              sx={{ '& .MuiOutlinedInput-root': { borderRadius: 2 } }}
            />
          </Grid>
          <Grid item xs={12} md={2}>
            <FormControl fullWidth size="small">
              <InputLabel>Status</InputLabel>
              <Select
                value={statusFilter}
                onChange={(e) => setStatusFilter(e.target.value)}
                label="Status"
                sx={{ borderRadius: 2 }}
              >
                <MenuItem value="all">All Status</MenuItem>
                <MenuItem value="pending">Pending</MenuItem>
                <MenuItem value="confirmed">Confirmed</MenuItem>
                <MenuItem value="assigned">Assigned</MenuItem>
                <MenuItem value="picked_up">Picked Up</MenuItem>
                <MenuItem value="delivered">Delivered</MenuItem>
                <MenuItem value="cancelled">Cancelled</MenuItem>
              </Select>
            </FormControl>
          </Grid>
          <Grid item xs={12} md={2}>
            <FormControl fullWidth size="small">
              <InputLabel>Payment</InputLabel>
              <Select
                value={paymentFilter}
                onChange={(e) => setPaymentFilter(e.target.value)}
                label="Payment"
                sx={{ borderRadius: 2 }}
              >
                <MenuItem value="all">All Payment</MenuItem>
                <MenuItem value="paid">Paid</MenuItem>
                <MenuItem value="unpaid">Unpaid</MenuItem>
                <MenuItem value="refunded">Refunded</MenuItem>
              </Select>
            </FormControl>
          </Grid>
          <Grid item xs={12} md={5}>
            <Box display="flex" justifyContent="flex-end">
              <Button
                variant="contained"
                startIcon={<AddIcon />}
                sx={{ borderRadius: 2, fontWeight: 600 }}
              >
                Create Order
              </Button>
            </Box>
          </Grid>
        </Grid>
      </Paper>

      {/* Table */}
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
              <TableRow>
                <TableCell>Order #</TableCell>
                <TableCell>Customer</TableCell>
                <TableCell>Vendor</TableCell>
                <TableCell>Delivery Date</TableCell>
                <TableCell>Time Slot</TableCell>
                <TableCell>Amount</TableCell>
                <TableCell>Status</TableCell>
                <TableCell>Payment</TableCell>
                <TableCell>Created</TableCell>
                <TableCell>Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {isLoading ? (
                <TableRow>
                  <TableCell colSpan={10} align="center" sx={{ py: 4 }}>
                    <CircularProgress />
                  </TableCell>
                </TableRow>
              ) : orders.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={10} align="center" sx={{ py: 4 }}>
                    <Typography variant="body2" sx={{ color: 'text.secondary' }}>
                      No orders found
                    </Typography>
                  </TableCell>
                </TableRow>
              ) : (
                orders.map((order) => {
                  const statusColors = getStatusColor(order.status);
                  const paymentColors = getPaymentStatusColor(order.payment_status);
                  return (
                    <TableRow key={order.id} hover>
                      <TableCell>
                        <Typography variant="subtitle2" sx={{ fontWeight: 600, color: '#1A73E8' }}>
                          #{order.order_number}
                        </Typography>
                      </TableCell>
                      <TableCell>
                        <Box display="flex" alignItems="center" gap={1}>
                          <PersonIcon fontSize="small" sx={{ color: 'text.secondary' }} />
                          <Box>
                            <Typography variant="body2" sx={{ fontWeight: 500 }}>
                              {order.customer?.name || 'Customer'}
                            </Typography>
                            <Typography variant="caption" sx={{ color: 'text.secondary' }}>
                              {order.customer?.phone || 'N/A'}
                            </Typography>
                          </Box>
                        </Box>
                      </TableCell>
                      <TableCell>
                        <Box display="flex" alignItems="center" gap={1}>
                          <StoreIcon fontSize="small" sx={{ color: 'text.secondary' }} />
                          <Typography variant="body2" sx={{ fontWeight: 500 }}>
                            {order.vendor?.name || 'Unassigned'}
                          </Typography>
                        </Box>
                      </TableCell>
                      <TableCell>
                        <Typography variant="body2">
                          {new Date(order.delivery_date).toLocaleDateString()}
                        </Typography>
                      </TableCell>
                      <TableCell>
                        <Typography variant="body2">{order.time_slot}</Typography>
                      </TableCell>
                      <TableCell>
                        <Typography variant="subtitle2" sx={{ fontWeight: 600 }}>
                          {formatCurrency(order.total_amount)}
                        </Typography>
                      </TableCell>
                      <TableCell>
                        <Chip
                          label={order.status.replace('_', ' ').replace(/\b\w/g, l => l.toUpperCase())}
                          sx={{
                            bgcolor: statusColors.bg,
                            color: statusColors.text,
                            fontWeight: 600,
                            fontSize: '0.75rem',
                          }}
                          size="small"
                        />
                      </TableCell>
                      <TableCell>
                        <Chip
                          label={order.payment_status.replace(/\b\w/g, l => l.toUpperCase())}
                          sx={{
                            bgcolor: paymentColors.bg,
                            color: paymentColors.text,
                            fontWeight: 600,
                            fontSize: '0.75rem',
                          }}
                          size="small"
                        />
                      </TableCell>
                      <TableCell>
                        <Typography variant="body2">
                          {formatDate(order.created_at)}
                        </Typography>
                      </TableCell>
                      <TableCell>
                        <IconButton
                          size="small"
                          onClick={(e) => handleActionMenuOpen(e, order)}
                          sx={{ borderRadius: 2 }}
                        >
                          <MoreVertIcon />
                        </IconButton>
                      </TableCell>
                    </TableRow>
                  );
                })
              )}
            </TableBody>
          </Table>
        </TableContainer>
        <TablePagination
          rowsPerPageOptions={[5, 10, 25, 50]}
          component="div"
          count={pagination.total}
          rowsPerPage={rowsPerPage}
          page={page}
          onPageChange={handleChangePage}
          onRowsPerPageChange={handleChangeRowsPerPage}
          sx={{ borderTop: '1px solid #E8EAED' }}
        />
      </Paper>

      {/* Action Menu */}
      <Menu
        anchorEl={actionMenuAnchor}
        open={Boolean(actionMenuAnchor)}
        onClose={handleActionMenuClose}
        PaperProps={{
          sx: {
            borderRadius: 2,
            boxShadow: '0 4px 12px rgba(0,0,0,0.15)',
            minWidth: 180,
          },
        }}
      >
        <MenuItem onClick={() => handleViewOrder(selectedOrderForAction!)} sx={{ fontWeight: 500 }}>
          <EditIcon sx={{ mr: 1.5, fontSize: 18 }} />
          View Details
        </MenuItem>
        <Divider />
        <MenuItem onClick={() => handleStatusChange('confirmed')} sx={{ fontWeight: 500 }}>
          <CheckCircleIcon sx={{ mr: 1.5, fontSize: 18, color: '#0288D1' }} />
          Confirm Order
        </MenuItem>
        <MenuItem onClick={() => handleStatusChange('assigned')} sx={{ fontWeight: 500 }}>
          <LocalShippingIcon sx={{ mr: 1.5, fontSize: 18, color: '#9334EA' }} />
          Assign to Vendor
        </MenuItem>
        <MenuItem onClick={() => handleStatusChange('delivered')} sx={{ fontWeight: 500 }}>
          <CheckCircleIcon sx={{ mr: 1.5, fontSize: 18, color: '#34A853' }} />
          Mark Delivered
        </MenuItem>
        <Divider />
        <MenuItem onClick={() => handleStatusChange('cancelled')} sx={{ fontWeight: 500, color: '#EA4335' }}>
          <CancelIcon sx={{ mr: 1.5, fontSize: 18, color: '#EA4335' }} />
          Cancel Order
        </MenuItem>
      </Menu>

      {/* Order Details Dialog */}
      <Dialog
        open={viewDialogOpen}
        onClose={() => setViewDialogOpen(false)}
        maxWidth="md"
        fullWidth
        PaperProps={{ sx: { borderRadius: 3 } }}
      >
        <DialogTitle sx={{ fontWeight: 600, fontSize: '1.25rem' }}>Order Details</DialogTitle>
        <DialogContent>
          {selectedOrder && (
            <Grid container spacing={3} sx={{ mt: 0.5 }}>
              <Grid item xs={12} md={6}>
                <Typography variant="subtitle2" sx={{ fontWeight: 600, mb: 1.5 }}>Order Information</Typography>
                <Box sx={{ bgcolor: '#F8F9FA', p: 2.5, borderRadius: 2 }}>
                  <Typography variant="body2" sx={{ mb: 1 }}><strong>Order #:</strong> #{selectedOrder.order_number}</Typography>
                  <Typography variant="body2" sx={{ mb: 1, display: 'flex', alignItems: 'center', gap: 1 }}>
                    <strong>Status:</strong>
                    <Chip
                      label={selectedOrder.status.replace('_', ' ').replace(/\b\w/g, l => l.toUpperCase())}
                      sx={{
                        bgcolor: getStatusColor(selectedOrder.status).bg,
                        color: getStatusColor(selectedOrder.status).text,
                        fontWeight: 600,
                        fontSize: '0.75rem',
                      }}
                      size="small"
                    />
                  </Typography>
                  <Typography variant="body2" sx={{ mb: 1, display: 'flex', alignItems: 'center', gap: 1 }}>
                    <strong>Payment Status:</strong>
                    <Chip
                      label={selectedOrder.payment_status.replace(/\b\w/g, l => l.toUpperCase())}
                      sx={{
                        bgcolor: getPaymentStatusColor(selectedOrder.payment_status).bg,
                        color: getPaymentStatusColor(selectedOrder.payment_status).text,
                        fontWeight: 600,
                        fontSize: '0.75rem',
                      }}
                      size="small"
                    />
                  </Typography>
                  <Typography variant="body2" sx={{ mb: 1 }}><strong>Total Amount:</strong> {formatCurrency(selectedOrder.total_amount)}</Typography>
                  <Typography variant="body2"><strong>Created:</strong> {formatDate(selectedOrder.created_at)}</Typography>
                </Box>
              </Grid>
              <Grid item xs={12} md={6}>
                <Typography variant="subtitle2" sx={{ fontWeight: 600, mb: 1.5 }}>Delivery Information</Typography>
                <Box sx={{ bgcolor: '#F8F9FA', p: 2.5, borderRadius: 2 }}>
                  <Typography variant="body2" sx={{ mb: 1 }}><strong>Delivery Date:</strong> {new Date(selectedOrder.delivery_date).toLocaleDateString()}</Typography>
                  <Typography variant="body2" sx={{ mb: 1 }}><strong>Time Slot:</strong> {selectedOrder.time_slot}</Typography>
                  <Typography variant="body2"><strong>Is Delivered:</strong> {selectedOrder.is_delivered ? 'Yes' : 'No'}</Typography>
                  {selectedOrder.delivered_at && (
                    <Typography variant="body2" sx={{ mt: 1 }}><strong>Delivered At:</strong> {formatDate(selectedOrder.delivered_at)}</Typography>
                  )}
                  {selectedOrder.payment_marked_at && (
                    <Typography variant="body2" sx={{ mt: 1 }}><strong>Payment Marked:</strong> {formatDate(selectedOrder.payment_marked_at)}</Typography>
                  )}
                </Box>
              </Grid>
              <Grid item xs={12} md={6}>
                <Typography variant="subtitle2" sx={{ fontWeight: 600, mb: 1.5 }}>Customer Information</Typography>
                <Box sx={{ bgcolor: '#F8F9FA', p: 2.5, borderRadius: 2 }}>
                  <Typography variant="body2" sx={{ mb: 1 }}><strong>Name:</strong> {selectedOrder.customer?.name || 'N/A'}</Typography>
                  <Typography variant="body2" sx={{ mb: 1 }}><strong>Phone:</strong> {selectedOrder.customer?.phone || 'N/A'}</Typography>
                  <Typography variant="body2"><strong>Address:</strong> {selectedOrder.customer?.address || 'N/A'}</Typography>
                </Box>
              </Grid>
              <Grid item xs={12} md={6}>
                <Typography variant="subtitle2" sx={{ fontWeight: 600, mb: 1.5 }}>Vendor Information</Typography>
                <Box sx={{ bgcolor: '#F8F9FA', p: 2.5, borderRadius: 2 }}>
                  <Typography variant="body2" sx={{ mb: 1 }}><strong>Name:</strong> {selectedOrder.vendor?.name || 'Unassigned'}</Typography>
                  <Typography variant="body2" sx={{ mb: 1 }}><strong>Phone:</strong> {selectedOrder.vendor?.phone || 'N/A'}</Typography>
                  <Typography variant="body2"><strong>Business:</strong> {selectedOrder.vendor?.business_name || 'N/A'}</Typography>
                </Box>
              </Grid>
            </Grid>
          )}
        </DialogContent>
        <DialogActions sx={{ p: 2.5, pt: 0 }}>
          <Button onClick={() => setViewDialogOpen(false)} sx={{ borderRadius: 2 }}>Close</Button>
        </DialogActions>
      </Dialog>

      {/* Status Change Dialog */}
      <Dialog
        open={statusDialogOpen}
        onClose={() => setStatusDialogOpen(false)}
        maxWidth="sm"
        fullWidth
        PaperProps={{ sx: { borderRadius: 3 } }}
      >
        <DialogTitle sx={{ fontWeight: 600 }}>Change Order Status</DialogTitle>
        <DialogContent>
          <Typography variant="body1" sx={{ mt: 1 }}>
            Change order #{selectedOrderForAction?.order_number} status to <strong>{selectedStatus}</strong>
          </Typography>
          <TextField
            fullWidth
            label="Notes (optional)"
            multiline
            rows={3}
            value={statusNotes}
            onChange={(e) => setStatusNotes(e.target.value)}
            sx={{ mt: 2, '& .MuiOutlinedInput-root': { borderRadius: 2 } }}
          />
        </DialogContent>
        <DialogActions sx={{ p: 2.5, pt: 0 }}>
          <Button onClick={() => setStatusDialogOpen(false)} sx={{ borderRadius: 2 }}>Cancel</Button>
          <Button
            variant="contained"
            onClick={() => {
              setStatusDialogOpen(false);
              setStatusNotes('');
            }}
            sx={{ borderRadius: 2, fontWeight: 600 }}
          >
            Update Status
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default Orders;
