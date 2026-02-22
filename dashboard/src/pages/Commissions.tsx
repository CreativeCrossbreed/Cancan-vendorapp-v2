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
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Alert,
  CircularProgress,
  Grid,
  Card,
  CardContent,
  LinearProgress,
} from '@mui/material';
import {
  TrendingUp as TrendingUpIcon,
  AccountBalance as AccountBalanceIcon,
  Pending as PendingIcon,
  CheckCircle as CheckCircleIcon,
  Visibility as VisibilityIcon,
} from '@mui/icons-material';
import { useDispatch, useSelector } from 'react-redux';
import { RootState, AppDispatch } from '../store';
import { fetchCommissions, fetchCommissionStats } from '../store/commissionSlice';
import { CommissionRecord } from '../types';

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

  useEffect(() => {
    dispatch(fetchCommissions({
      page: page + 1,
      limit: rowsPerPage,
      status: statusFilter !== 'all' ? statusFilter : undefined,
      vendor_id: vendorFilter !== 'all' ? vendorFilter : undefined,
    }));
    dispatch(fetchCommissionStats(30));
  }, [dispatch, page, rowsPerPage, statusFilter, vendorFilter]);

  const handleChangePage = (event: unknown, newPage: number) => {
    setPage(newPage);
  };

  const handleChangeRowsPerPage = (event: React.ChangeEvent<HTMLInputElement>) => {
    setRowsPerPage(parseInt(event.target.value, 10));
    setPage(0);
  };

  const handleViewCommission = (commission: CommissionRecord) => {
    setSelectedCommission(commission);
    setViewDialogOpen(true);
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'paid': return { bg: '#E8F5E9', text: '#2E7D32' };
      case 'pending': return { bg: '#FEF7E0', text: '#B45309' };
      case 'processing': return { bg: '#E1F5FE', text: '#0277BD' };
      case 'cancelled': return { bg: '#FFEBEE', text: '#C62828' };
      default: return { bg: '#F5F5F5', text: '#616161' };
    }
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

  const totalPending = stats?.totalPending || 0;
  const totalPaid = stats?.totalPaid || 0;
  const totalUnpaid = stats?.totalUnpaid || 0;
  const totalEarnings = stats?.totalEarnings || 0;
  const payoutPercentage = totalEarnings > 0 ? Math.round((totalPaid / totalEarnings) * 100) : 0;

  if (error) {
    return (
      <Box>
        <Typography variant="h4" sx={{ fontWeight: 600, mb: 2 }}>
          Commission Tracking
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
          Commission Tracking
        </Typography>
        <Typography variant="body1" sx={{ color: 'text.secondary' }}>
          Track and manage vendor commissions
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
                    Total Earnings
                  </Typography>
                  <Typography variant="h4" sx={{ fontWeight: 700, color: '#202124' }}>
                    {formatCurrency(totalEarnings)}
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
                  <TrendingUpIcon sx={{ color: '#1A73E8', fontSize: 24 }} />
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
                    Paid Commissions
                  </Typography>
                  <Typography variant="h4" sx={{ fontWeight: 700, color: '#202124' }}>
                    {formatCurrency(totalPaid)}
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
                    Pending Payment
                  </Typography>
                  <Typography variant="h4" sx={{ fontWeight: 700, color: '#202124' }}>
                    {formatCurrency(totalPending)}
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
                  <PendingIcon sx={{ color: '#FBBC05', fontSize: 24 }} />
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
                    Unpaid Commissions
                  </Typography>
                  <Typography variant="h4" sx={{ fontWeight: 700, color: '#202124' }}>
                    {formatCurrency(totalUnpaid)}
                  </Typography>
                </Box>
                <Box
                  sx={{
                    width: 48,
                    height: 48,
                    borderRadius: 2.5,
                    bgcolor: 'rgba(234, 67, 53, 0.1)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                  }}
                >
                  <AccountBalanceIcon sx={{ color: '#EA4335', fontSize: 24 }} />
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Payment Progress Bar */}
      <Paper
        sx={{
          p: 3,
          mb: 2,
          borderRadius: 3,
          boxShadow: '0 1px 3px rgba(0,0,0,0.08)',
        }}
      >
        <Typography variant="h6" sx={{ fontWeight: 600, mb: 2 }}>Commission Payment Status</Typography>
        <Box display="flex" alignItems="center" gap={2}>
          <Box flex={1}>
            <LinearProgress
              variant="determinate"
              value={payoutPercentage}
              sx={{
                height: 10,
                borderRadius: 5,
                backgroundColor: '#E8EAED',
                '& .MuiLinearProgress-bar': {
                  backgroundColor: '#34A853',
                  borderRadius: 5,
                },
              }}
            />
          </Box>
          <Typography variant="body2" sx={{ fontWeight: 600, color: '#34A853', minWidth: 60 }}>
            {payoutPercentage}% Paid
          </Typography>
        </Box>
        <Grid container spacing={2} sx={{ mt: 2 }}>
          <Grid item xs={4}>
            <Typography variant="body2" sx={{ color: '#34A853', fontWeight: 500 }}>
              Paid: {formatCurrency(totalPaid)}
            </Typography>
          </Grid>
          <Grid item xs={4}>
            <Typography variant="body2" sx={{ color: '#B45309', fontWeight: 500 }}>
              Pending: {formatCurrency(totalPending)}
            </Typography>
          </Grid>
          <Grid item xs={4}>
            <Typography variant="body2" sx={{ color: '#EA4335', fontWeight: 500 }}>
              Unpaid: {formatCurrency(totalUnpaid)}
            </Typography>
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
          <Grid item xs={12} md={3}>
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
                <MenuItem value="processing">Processing</MenuItem>
                <MenuItem value="paid">Paid</MenuItem>
                <MenuItem value="cancelled">Cancelled</MenuItem>
              </Select>
            </FormControl>
          </Grid>
          <Grid item xs={12} md={3}>
            <FormControl fullWidth size="small">
              <InputLabel>Vendor</InputLabel>
              <Select
                value={vendorFilter}
                onChange={(e) => setVendorFilter(e.target.value)}
                label="Vendor"
                sx={{ borderRadius: 2 }}
              >
                <MenuItem value="all">All Vendors</MenuItem>
                <MenuItem value="vendor1">Vendor 1</MenuItem>
                <MenuItem value="vendor2">Vendor 2</MenuItem>
              </Select>
            </FormControl>
          </Grid>
          <Grid item xs={12} md={3}>
            <FormControl fullWidth size="small">
              <InputLabel>Date Range</InputLabel>
              <Select
                value={dateFilter}
                onChange={(e) => setDateFilter(e.target.value)}
                label="Date Range"
                sx={{ borderRadius: 2 }}
              >
                <MenuItem value="all">All Time</MenuItem>
                <MenuItem value="today">Today</MenuItem>
                <MenuItem value="week">This Week</MenuItem>
                <MenuItem value="month">This Month</MenuItem>
              </Select>
            </FormControl>
          </Grid>
          <Grid item xs={12} md={3}>
            <Box display="flex" justifyContent="flex-end" gap={1}>
              <Button variant="outlined" sx={{ borderRadius: 2, fontWeight: 500 }}>Export CSV</Button>
              <Button variant="contained" sx={{ borderRadius: 2, fontWeight: 600 }}>Process Payments</Button>
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
                <TableCell>Commission ID</TableCell>
                <TableCell>Vendor</TableCell>
                <TableCell>Order ID</TableCell>
                <TableCell>Commission Amount</TableCell>
                <TableCell>Commission Rate</TableCell>
                <TableCell>Status</TableCell>
                <TableCell>Order Date</TableCell>
                <TableCell>Created</TableCell>
                <TableCell>Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {isLoading ? (
                <TableRow>
                  <TableCell colSpan={9} align="center" sx={{ py: 4 }}>
                    <CircularProgress />
                  </TableCell>
                </TableRow>
              ) : commissions.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={9} align="center" sx={{ py: 4 }}>
                    <Typography variant="body2" sx={{ color: 'text.secondary' }}>
                      No commission records found
                    </Typography>
                  </TableCell>
                </TableRow>
              ) : (
                commissions.map((commission) => (
                  <TableRow key={commission.id} hover>
                    <TableCell>
                      <Typography variant="body2" sx={{ fontFamily: 'monospace', fontWeight: 500 }}>
                        #{commission.id?.slice(0, 8) || 'N/A'}
                      </Typography>
                    </TableCell>
                    <TableCell>
                      <Typography variant="body2" sx={{ fontWeight: 500 }}>
                        {commission.vendor?.name || 'Unknown Vendor'}
                      </Typography>
                      <Typography variant="caption" sx={{ color: 'text.secondary' }}>
                        {commission.vendor?.phone || ''}
                      </Typography>
                    </TableCell>
                    <TableCell>
                      <Typography variant="body2" sx={{ fontFamily: 'monospace' }}>
                        #{commission.order_id?.slice(0, 8) || 'N/A'}
                      </Typography>
                    </TableCell>
                    <TableCell>
                      <Typography variant="subtitle2" sx={{ fontWeight: 600, color: '#1A73E8' }}>
                        {formatCurrency(commission.commission_amount || 0)}
                      </Typography>
                    </TableCell>
                    <TableCell>
                      <Typography variant="body2" sx={{ fontWeight: 600 }}>
                        {commission.commission_rate || 0}%
                      </Typography>
                    </TableCell>
                    <TableCell>
                      <Chip
                        label={commission.status}
                        sx={{
                          bgcolor: getStatusColor(commission.status).bg,
                          color: getStatusColor(commission.status).text,
                          fontWeight: 600,
                          fontSize: '0.75rem',
                        }}
                        size="small"
                      />
                    </TableCell>
                    <TableCell>
                      <Typography variant="body2">
                        {commission.order_date ? formatDate(commission.order_date) : 'N/A'}
                      </Typography>
                    </TableCell>
                    <TableCell>
                      <Typography variant="body2">
                        {commission.created_at ? formatDate(commission.created_at) : 'N/A'}
                      </Typography>
                    </TableCell>
                    <TableCell>
                      <IconButton
                        size="small"
                        onClick={() => handleViewCommission(commission)}
                        sx={{ borderRadius: 2 }}
                      >
                        <VisibilityIcon fontSize="small" />
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

      {/* Commission Details Dialog */}
      <Dialog
        open={viewDialogOpen}
        onClose={() => setViewDialogOpen(false)}
        maxWidth="sm"
        fullWidth
        PaperProps={{ sx: { borderRadius: 3 } }}
      >
        <DialogTitle sx={{ fontWeight: 600 }}>Commission Details</DialogTitle>
        <DialogContent>
          {selectedCommission && (
            <Box sx={{ bgcolor: '#F8F9FA', p: 2.5, borderRadius: 2, mt: 1 }}>
              <Typography variant="body2" sx={{ mb: 1 }}><strong>Commission ID:</strong> #{selectedCommission.id}</Typography>
              <Typography variant="body2" sx={{ mb: 1 }}><strong>Order ID:</strong> #{selectedCommission.order_id}</Typography>
              <Typography variant="body2" sx={{ mb: 1 }}><strong>Vendor:</strong> {selectedCommission.vendor?.name}</Typography>
              <Typography variant="body2" sx={{ mb: 1 }}><strong>Commission Amount:</strong> {formatCurrency(selectedCommission.commission_amount || 0)}</Typography>
              <Typography variant="body2" sx={{ mb: 1 }}><strong>Commission Rate:</strong> {selectedCommission.commission_rate}%</Typography>
              <Typography variant="body2" sx={{ mb: 1, display: 'flex', alignItems: 'center', gap: 1 }}>
                <strong>Status:</strong>
                <Chip
                  label={selectedCommission.status}
                  sx={{
                    bgcolor: getStatusColor(selectedCommission.status).bg,
                    color: getStatusColor(selectedCommission.status).text,
                    fontWeight: 600,
                    fontSize: '0.75rem',
                  }}
                  size="small"
                />
              </Typography>
              <Typography variant="body2" sx={{ mb: 1 }}><strong>Order Total:</strong> {formatCurrency(selectedCommission.order_total || 0)}</Typography>
              <Typography variant="body2" sx={{ mb: 1 }}><strong>Order Date:</strong> {selectedCommission.order_date ? formatDate(selectedCommission.order_date) : 'N/A'}</Typography>
              <Typography variant="body2"><strong>Created:</strong> {selectedCommission.created_at ? formatDate(selectedCommission.created_at) : 'N/A'}</Typography>
              {selectedCommission.paid_at && (
                <Typography variant="body2" sx={{ mt: 1 }}><strong>Paid On:</strong> {formatDate(selectedCommission.paid_at)}</Typography>
              )}
            </Box>
          )}
        </DialogContent>
        <DialogActions sx={{ p: 2.5, pt: 0 }}>
          <Button onClick={() => setViewDialogOpen(false)} sx={{ borderRadius: 2 }}>Close</Button>
          {selectedCommission?.status === 'pending' && (
            <Button variant="contained" sx={{ borderRadius: 2, fontWeight: 600 }}>
              Mark as Paid
            </Button>
          )}
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default Commissions;
