import React, { useEffect } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import {
  Grid,
  Card,
  CardContent,
  Typography,
  Box,
  Paper,
  CircularProgress,
} from '@mui/material';
import {
  People,
  ShoppingCart,
  AttachMoney,
  WhatsApp,
  Payment,
  Store,
} from '@mui/icons-material';
import { RootState, AppDispatch } from '../store';
import { fetchDashboardStats } from '../store/dashboardSlice';

const Dashboard: React.FC = () => {
  const dispatch = useDispatch<AppDispatch>();
  const { stats, isLoading, error } = useSelector((state: RootState) => state.dashboard);

  useEffect(() => {
    dispatch(fetchDashboardStats());
  }, [dispatch]);

  const statCards = [
    {
      title: 'Total Vendors',
      value: stats?.totalVendors || 0,
      icon: <Store />,
      color: '#1976d2',
    },
    {
      title: 'Active Vendors',
      value: stats?.activeVendors || 0,
      icon: <People />,
      color: '#388e3c',
    },
    {
      title: 'Total Customers',
      value: stats?.totalCustomers || 0,
      icon: <People />,
      color: '#f57c00',
    },
    {
      title: "Today's Orders",
      value: stats?.todayOrders || 0,
      icon: <ShoppingCart />,
      color: '#7b1fa2',
    },
    {
      title: "Today's Revenue",
      value: `₹${stats?.todayRevenue || 0}`,
      icon: <AttachMoney />,
      color: '#c62828',
    },
    {
      title: 'Commission Earned',
      value: `₹${stats?.commissionEarned || 0}`,
      icon: <Payment />,
      color: '#0277bd',
    },
    {
      title: 'WhatsApp Orders',
      value: stats?.whatsappOrdersProcessed || 0,
      icon: <WhatsApp />,
      color: '#2e7d32',
    },
    {
      title: 'Pending Payments',
      value: `₹${stats?.pendingPayments || 0}`,
      icon: <Payment />,
      color: '#ef6c00',
    },
  ];

  if (isLoading && !stats) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="60vh">
        <CircularProgress />
      </Box>
    );
  }

  if (error) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="60vh">
        <Typography color="error">{error}</Typography>
      </Box>
    );
  }

  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Dashboard
      </Typography>
      <Typography variant="body1" color="text.secondary" gutterBottom>
        Welcome to the Can Can Water Can Delivery Admin Dashboard
      </Typography>

      <Grid container spacing={3}>
        {statCards.map((card, index) => (
          <Grid item xs={12} sm={6} md={3} key={index}>
            <Card
              sx={{
                height: '100%',
                display: 'flex',
                flexDirection: 'column',
              }}
            >
              <CardContent>
                <Box display="flex" alignItems="center">
                  <Box
                    sx={{
                      backgroundColor: card.color,
                      borderRadius: 1,
                      p: 1,
                      mr: 2,
                      color: 'white',
                    }}
                  >
                    {card.icon}
                  </Box>
                  <Box>
                    <Typography color="textSecondary" gutterBottom variant="h6">
                      {card.title}
                    </Typography>
                    <Typography variant="h4" component="h2">
                      {card.value}
                    </Typography>
                  </Box>
                </Box>
              </CardContent>
            </Card>
          </Grid>
        ))}

        <Grid item xs={12} md={6}>
          <Paper sx={{ p: 2, height: 300 }}>
            <Typography variant="h6" gutterBottom>
              Quick Actions
            </Typography>
            <Typography variant="body2" color="text.secondary">
              • View and manage all vendors<br />
              • Monitor customer orders<br />
              • Track WhatsApp integrations<br />
              • Manage commission payments
            </Typography>
          </Paper>
        </Grid>

        <Grid item xs={12} md={6}>
          <Paper sx={{ p: 2, height: 300 }}>
            <Typography variant="h6" gutterBottom>
              System Status
            </Typography>
            <Typography variant="body2" color="success.main">
              ✓ All systems operational<br />
              ✓ WhatsApp API connected<br />
              ✓ Database sync active<br />
              ✓ Real-time updates enabled
            </Typography>
          </Paper>
        </Grid>
      </Grid>
    </Box>
  );
};

export default Dashboard;