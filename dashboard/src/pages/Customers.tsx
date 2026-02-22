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
  Alert,
  CircularProgress,
  Grid,
  Card,
  CardContent,
  Tooltip,
} from '@mui/material';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Visibility as ViewIcon,
  Person as PersonIcon,
  Phone as PhoneIcon,
  ShoppingBasket as ShoppingBasketIcon,
  AttachMoney as AttachMoneyIcon,
  TrendingUp,
} from '@mui/icons-material';
import { useDispatch, useSelector } from 'react-redux';
import { RootState, AppDispatch } from '../store';
import { fetchCustomers } from '../store/customerSlice';
import { Customer } from '../types';

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
      <Box>
        <Typography variant="h4" sx={{ fontWeight: 600, mb: 2 }}>
          Customers Management
        </Typography>
        <Alert severity="error" sx={{ borderRadius: 2 }}>{error}</Alert>
      </Box>
    );
  }

  const totalSpent = customers.reduce((sum, customer) => sum + (customer.stats?.totalSpent || 0), 0);
  const totalOrders = customers.reduce((sum, customer) => sum + (customer.stats?.totalOrders || 0), 0);
  const avgOrderValue = totalOrders > 0 ? totalSpent / customers.reduce((sum, customer) => sum + (customer.stats?.completedOrders || 0), 1) : 0;

  return (
    <Box>
      {/* Header */}
      <Box sx={{ mb: 3 }}>
        <Typography variant="h4" sx={{ fontWeight: 600, color: '#202124', mb: 0.5 }}>
          Customers Management
        </Typography>
        <Typography variant="body1" sx={{ color: 'text.secondary' }}>
          Manage your water can delivery customers
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
                    Total Customers
                  </Typography>
                  <Typography variant="h4" sx={{ fontWeight: 700, color: '#202124' }}>
                    {pagination.total}
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
                  <PersonIcon sx={{ color: '#1A73E8', fontSize: 24 }} />
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
                    Active Orders
                  </Typography>
                  <Typography variant="h4" sx={{ fontWeight: 700, color: '#202124' }}>
                    {customers.reduce((sum, customer) => sum + (customer.stats?.totalOrders || 0), 0)}
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
                  <ShoppingBasketIcon sx={{ color: '#34A853', fontSize: 24 }} />
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
                    Total Spent
                  </Typography>
                  <Typography variant="h4" sx={{ fontWeight: 700, color: '#202124' }}>
                    {formatCurrency(totalSpent)}
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
                  <AttachMoneyIcon sx={{ color: '#FBBC05', fontSize: 24 }} />
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
                    Avg Order Value
                  </Typography>
                  <Typography variant="h4" sx={{ fontWeight: 700, color: '#202124' }}>
                    {formatCurrency(avgOrderValue)}
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
                  <TrendingUp sx={{ color: '#0288D1', fontSize: 24 }} />
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
          <Grid item xs={12} md={8}>
            <TextField
              fullWidth
              label="Search customers by name, phone, or address..."
              value={searchTerm}
              onChange={handleSearch}
              size="small"
              placeholder="Search..."
              sx={{ '& .MuiOutlinedInput-root': { borderRadius: 2 } }}
            />
          </Grid>
          <Grid item xs={12} md={4}>
            <Box display="flex" justifyContent="flex-end">
              <Button
                variant="contained"
                startIcon={<AddIcon />}
                onClick={handleAddCustomer}
                sx={{ borderRadius: 2, fontWeight: 600 }}
              >
                Add Customer
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
                <TableCell>Customer Info</TableCell>
                <TableCell>Contact</TableCell>
                <TableCell>Address</TableCell>
                <TableCell>Total Orders</TableCell>
                <TableCell>Total Spent</TableCell>
                <TableCell>Last Order</TableCell>
                <TableCell>Joined</TableCell>
                <TableCell>Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {isLoading ? (
                <TableRow>
                  <TableCell colSpan={8} align="center" sx={{ py: 4 }}>
                    <CircularProgress />
                  </TableCell>
                </TableRow>
              ) : customers.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={8} align="center" sx={{ py: 4 }}>
                    <Typography variant="body2" sx={{ color: 'text.secondary' }}>
                      No customers found
                    </Typography>
                  </TableCell>
                </TableRow>
              ) : (
                customers.map((customer) => (
                  <TableRow key={customer.id} hover>
                    <TableCell>
                      <Box display="flex" alignItems="center" gap={1.5}>
                        <Box
                          sx={{
                            width: 40,
                            height: 40,
                            borderRadius: 2,
                            bgcolor: 'rgba(26, 115, 232, 0.1)',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                          }}
                        >
                          <PersonIcon sx={{ color: '#1A73E8', fontSize: 20 }} />
                        </Box>
                        <Box>
                          <Typography variant="subtitle2" sx={{ fontWeight: 600 }}>
                            {customer.name}
                          </Typography>
                          <Typography variant="caption" sx={{ color: 'text.secondary' }}>
                            ID: {customer.id.slice(0, 8)}...
                          </Typography>
                        </Box>
                      </Box>
                    </TableCell>
                    <TableCell>
                      <Box display="flex" alignItems="center" gap={1}>
                        <PhoneIcon fontSize="small" sx={{ color: 'text.secondary' }} />
                        <Typography variant="body2" sx={{ fontWeight: 500 }}>
                          {customer.phone}
                        </Typography>
                      </Box>
                    </TableCell>
                    <TableCell>
                      <Tooltip title={formatAddress(customer)} arrow>
                        <Typography
                          variant="body2"
                          noWrap
                          sx={{
                            maxWidth: 200,
                            display: 'block',
                            color: 'text.secondary',
                          }}
                        >
                          {formatAddress(customer)}
                        </Typography>
                      </Tooltip>
                    </TableCell>
                    <TableCell>
                      <Typography variant="body2" sx={{ fontWeight: 600 }}>
                        {customer.stats?.totalOrders || 0}
                      </Typography>
                      <Typography variant="caption" sx={{ color: 'text.secondary' }}>
                        {customer.stats?.completedOrders || 0} completed
                      </Typography>
                    </TableCell>
                    <TableCell>
                      <Typography variant="body2" sx={{ fontWeight: 600 }}>
                        {formatCurrency(customer.stats?.totalSpent || 0)}
                      </Typography>
                    </TableCell>
                    <TableCell>
                      <Typography variant="body2">
                        {customer.stats?.lastOrderDate
                          ? formatDate(customer.stats.lastOrderDate)
                          : 'No orders'
                        }
                      </Typography>
                    </TableCell>
                    <TableCell>
                      <Typography variant="body2">
                        {formatDate(customer.created_at)}
                      </Typography>
                    </TableCell>
                    <TableCell>
                      <IconButton
                        size="small"
                        onClick={() => handleViewCustomer(customer)}
                        sx={{ borderRadius: 2 }}
                        title="View Details"
                      >
                        <ViewIcon fontSize="small" />
                      </IconButton>
                      <IconButton
                        size="small"
                        title="Edit"
                        sx={{ borderRadius: 2 }}
                      >
                        <EditIcon fontSize="small" />
                      </IconButton>
                    </TableCell>
                  </TableRow>
                ))
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

      {/* Add Customer Dialog */}
      <Dialog
        open={addDialogOpen}
        onClose={() => setAddDialogOpen(false)}
        maxWidth="sm"
        fullWidth
        PaperProps={{ sx: { borderRadius: 3 } }}
      >
        <DialogTitle sx={{ fontWeight: 600 }}>Add New Customer</DialogTitle>
        <DialogContent>
          <Grid container spacing={2} sx={{ mt: 0.5 }}>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Full Name"
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                required
                size="small"
                sx={{ '& .MuiOutlinedInput-root': { borderRadius: 2 } }}
              />
            </Grid>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Phone Number"
                value={formData.phone}
                onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                required
                size="small"
                sx={{ '& .MuiOutlinedInput-root': { borderRadius: 2 } }}
              />
            </Grid>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Street Address"
                value={formData.address}
                onChange={(e) => setFormData({ ...formData, address: e.target.value })}
                multiline
                rows={2}
                size="small"
                sx={{ '& .MuiOutlinedInput-root': { borderRadius: 2 } }}
              />
            </Grid>
            <Grid item xs={12} md={6}>
              <TextField
                fullWidth
                label="Flat/Door Number"
                value={formData.flat_number}
                onChange={(e) => setFormData({ ...formData, flat_number: e.target.value })}
                size="small"
                sx={{ '& .MuiOutlinedInput-root': { borderRadius: 2 } }}
              />
            </Grid>
            <Grid item xs={12} md={6}>
              <TextField
                fullWidth
                label="Floor"
                value={formData.floor}
                onChange={(e) => setFormData({ ...formData, floor: e.target.value })}
                size="small"
                sx={{ '& .MuiOutlinedInput-root': { borderRadius: 2 } }}
              />
            </Grid>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Building Name"
                value={formData.building_name}
                onChange={(e) => setFormData({ ...formData, building_name: e.target.value })}
                size="small"
                sx={{ '& .MuiOutlinedInput-root': { borderRadius: 2 } }}
              />
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions sx={{ p: 2.5, pt: 0 }}>
          <Button onClick={() => setAddDialogOpen(false)} sx={{ borderRadius: 2 }}>Cancel</Button>
          <Button variant="contained" sx={{ borderRadius: 2, fontWeight: 600 }}>Add Customer</Button>
        </DialogActions>
      </Dialog>

      {/* View Customer Dialog */}
      <Dialog
        open={viewDialogOpen}
        onClose={() => setViewDialogOpen(false)}
        maxWidth="md"
        fullWidth
        PaperProps={{ sx: { borderRadius: 3 } }}
      >
        <DialogTitle sx={{ fontWeight: 600 }}>Customer Details</DialogTitle>
        <DialogContent>
          {selectedCustomer && (
            <Grid container spacing={3} sx={{ mt: 0.5 }}>
              <Grid item xs={12} md={6}>
                <Typography variant="subtitle2" sx={{ fontWeight: 600, mb: 1.5 }}>Personal Information</Typography>
                <Box sx={{ bgcolor: '#F8F9FA', p: 2.5, borderRadius: 2 }}>
                  <Typography variant="body2" sx={{ mb: 1 }}><strong>Name:</strong> {selectedCustomer.name}</Typography>
                  <Typography variant="body2" sx={{ mb: 1 }}><strong>Phone:</strong> {selectedCustomer.phone}</Typography>
                  <Typography variant="body2" sx={{ mb: 1, display: 'flex', alignItems: 'center', gap: 1 }}>
                    <strong>Status:</strong>
                    <Chip
                      label={selectedCustomer.status || 'Active'}
                      size="small"
                      sx={{
                        bgcolor: '#E8F5E9',
                        color: '#2E7D32',
                        fontWeight: 600,
                        fontSize: '0.75rem',
                      }}
                    />
                  </Typography>
                  <Typography variant="body2" sx={{ mb: 1 }}><strong>Customer ID:</strong> {selectedCustomer.id}</Typography>
                  <Typography variant="body2"><strong>Joined:</strong> {formatDate(selectedCustomer.created_at)}</Typography>
                </Box>
              </Grid>
              <Grid item xs={12} md={6}>
                <Typography variant="subtitle2" sx={{ fontWeight: 600, mb: 1.5 }}>Address Information</Typography>
                <Box sx={{ bgcolor: '#F8F9FA', p: 2.5, borderRadius: 2 }}>
                  <Typography variant="body2" sx={{ mb: 1 }}><strong>Building:</strong> {selectedCustomer.building_name || '-'}</Typography>
                  <Typography variant="body2" sx={{ mb: 1 }}><strong>Flat/Door:</strong> {selectedCustomer.flat_number || '-'}</Typography>
                  <Typography variant="body2" sx={{ mb: 1 }}><strong>Floor:</strong> {selectedCustomer.floor || '-'}</Typography>
                  <Typography variant="body2"><strong>Street:</strong> {selectedCustomer.address}</Typography>
                </Box>
              </Grid>
              <Grid item xs={12}>
                <Typography variant="subtitle2" sx={{ fontWeight: 600, mb: 1.5 }}>Order Statistics</Typography>
                <Box sx={{ bgcolor: '#F8F9FA', p: 2.5, borderRadius: 2 }}>
                  <Grid container spacing={2}>
                    <Grid item xs={6} md={3}>
                      <Typography variant="body2"><strong>Total Orders:</strong> {selectedCustomer.stats?.totalOrders || 0}</Typography>
                    </Grid>
                    <Grid item xs={6} md={3}>
                      <Typography variant="body2"><strong>Completed:</strong> {selectedCustomer.stats?.completedOrders || 0}</Typography>
                    </Grid>
                    <Grid item xs={6} md={3}>
                      <Typography variant="body2"><strong>Total Spent:</strong> {formatCurrency(selectedCustomer.stats?.totalSpent || 0)}</Typography>
                    </Grid>
                    <Grid item xs={6} md={3}>
                      <Typography variant="body2"><strong>Last Order:</strong> {selectedCustomer.stats?.lastOrderDate ? formatDate(selectedCustomer.stats.lastOrderDate) : 'Never'}</Typography>
                    </Grid>
                  </Grid>
                </Box>
              </Grid>
            </Grid>
          )}
        </DialogContent>
        <DialogActions sx={{ p: 2.5, pt: 0 }}>
          <Button onClick={() => setViewDialogOpen(false)} sx={{ borderRadius: 2 }}>Close</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default Customers;
