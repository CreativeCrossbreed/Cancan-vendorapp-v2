// @ts-nocheck
'use client';
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
    TrendingUp,
    ArrowUpward,
    ArrowDownward,
} from '@mui/icons-material';
import { RootState, AppDispatch } from '@/store';
import { fetchDashboardStats } from '@/store/dashboardSlice';

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
            color: '#1A73E8',
            bgColor: 'rgba(26, 115, 232, 0.1)',
            trend: null,
        },
        {
            title: 'Active Vendors',
            value: stats?.activeVendors || 0,
            icon: <People />,
            color: '#34A853',
            bgColor: 'rgba(52, 168, 83, 0.1)',
            trend: '+12%',
        },
        {
            title: 'Total Customers',
            value: stats?.totalCustomers || 0,
            icon: <People />,
            color: '#FBBC05',
            bgColor: 'rgba(251, 188, 5, 0.1)',
            trend: '+8%',
        },
        {
            title: "Today's Orders",
            value: stats?.todayOrders || 0,
            icon: <ShoppingCart />,
            color: '#9334EA',
            bgColor: 'rgba(147, 52, 234, 0.1)',
            trend: '+5%',
        },
        {
            title: "Today's Revenue",
            value: `₹${stats?.todayRevenue || 0}`,
            icon: <AttachMoney />,
            color: '#EA4335',
            bgColor: 'rgba(234, 67, 53, 0.1)',
            trend: '+15%',
        },
        {
            title: 'Commission Earned',
            value: `₹${stats?.commissionEarned || 0}`,
            icon: <Payment />,
            color: '#0288D1',
            bgColor: 'rgba(2, 136, 209, 0.1)',
            trend: null,
        },
        {
            title: 'WhatsApp Orders',
            value: stats?.whatsappOrdersProcessed || 0,
            icon: <WhatsApp />,
            color: '#34A853',
            bgColor: 'rgba(52, 168, 83, 0.1)',
            trend: '+22%',
        },
        {
            title: 'Pending Payments',
            value: `₹${stats?.pendingPayments || 0}`,
            icon: <Payment />,
            color: '#F97316',
            bgColor: 'rgba(249, 115, 22, 0.1)',
            trend: '-3%',
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
            {/* Header */}
            <Box sx={{ mb: 4 }}>
                <Typography variant="h4" sx={{ fontWeight: 600, color: '#202124', mb: 0.5 }}>
                    Dashboard
                </Typography>
                <Typography variant="body1" sx={{ color: 'text.secondary' }}>
                    Welcome to the Can Can Water Can Delivery Admin Dashboard
                </Typography>
            </Box>

            {/* Stat Cards */}
            <Grid container spacing={3}>
                {statCards.map((card, index) => (
                    <Grid item xs={12} sm={6} md={3} key={index}>
                        <Card
                            sx={{
                                height: '100%',
                                borderRadius: 3,
                                boxShadow: '0 1px 3px rgba(0,0,0,0.08), 0 1px 2px rgba(0,0,0,0.04)',
                                transition: 'transform 0.2s, box-shadow 0.2s',
                                '&:hover': {
                                    transform: 'translateY(-4px)',
                                    boxShadow: '0 8px 24px rgba(0,0,0,0.12)',
                                },
                            }}
                        >
                            <CardContent>
                                <Box display="flex" alignItems="center" justifyContent="space-between">
                                    <Box>
                                        <Typography
                                            variant="body2"
                                            sx={{ color: 'text.secondary', mb: 1, fontWeight: 500 }}
                                        >
                                            {card.title}
                                        </Typography>
                                        <Typography variant="h4" sx={{ fontWeight: 700, color: '#202124' }}>
                                            {card.value}
                                        </Typography>
                                        {card.trend && (
                                            <Box display="flex" alignItems="center" gap={0.5} sx={{ mt: 1 }}>
                                                {card.trend.startsWith('+') ? (
                                                    <ArrowUpward sx={{ fontSize: 16, color: '#34A853' }} />
                                                ) : (
                                                    <ArrowDownward sx={{ fontSize: 16, color: '#34A853' }} />
                                                )}
                                                <Typography
                                                    variant="caption"
                                                    sx={{ color: '#34A853', fontWeight: 600 }}
                                                >
                                                    {card.trend}
                                                </Typography>
                                                <Typography variant="caption" sx={{ color: 'text.secondary' }}>
                                                    vs last month
                                                </Typography>
                                            </Box>
                                        )}
                                    </Box>
                                    <Box
                                        sx={{
                                            backgroundColor: card.bgColor,
                                            borderRadius: 3,
                                            p: 1.5,
                                            color: card.color,
                                        }}
                                    >
                                        {card.icon}
                                    </Box>
                                </Box>
                            </CardContent>
                        </Card>
                    </Grid>
                ))}
            </Grid>

            {/* Info Cards */}
            <Grid container spacing={3} sx={{ mt: 1 }}>
                <Grid item xs={12} md={6}>
                    <Paper
                        sx={{
                            p: 3,
                            borderRadius: 3,
                            boxShadow: '0 1px 3px rgba(0,0,0,0.08), 0 1px 2px rgba(0,0,0,0.04)',
                            height: '100%',
                        }}
                    >
                        <Box display="flex" alignItems="center" gap={2} mb={2}>
                            <Box
                                sx={{
                                    width: 48,
                                    height: 48,
                                    borderRadius: 2,
                                    bgcolor: 'rgba(26, 115, 232, 0.1)',
                                    display: 'flex',
                                    alignItems: 'center',
                                    justifyContent: 'center',
                                }}
                            >
                                <TrendingUp sx={{ color: '#1A73E8', fontSize: 24 }} />
                            </Box>
                            <Box>
                                <Typography variant="h6" sx={{ fontWeight: 600 }}>
                                    Quick Actions
                                </Typography>
                                <Typography variant="caption" sx={{ color: 'text.secondary' }}>
                                    Common tasks
                                </Typography>
                            </Box>
                        </Box>
                        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
                            {[
                                { label: 'View and manage all vendors', color: '#1A73E8' },
                                { label: 'Monitor customer orders', color: '#34A853' },
                                { label: 'Track WhatsApp integrations', color: '#FBBC05' },
                                { label: 'Manage commission payments', color: '#EA4335' },
                            ].map((item, idx) => (
                                <Box key={idx} sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                                    <Box sx={{ width: 8, height: 8, borderRadius: '50%', bgcolor: item.color }} />
                                    <Typography variant="body2" sx={{ color: 'text.secondary' }}>
                                        {item.label}
                                    </Typography>
                                </Box>
                            ))}
                        </Box>
                    </Paper>
                </Grid>

                <Grid item xs={12} md={6}>
                    <Paper
                        sx={{
                            p: 3,
                            borderRadius: 3,
                            boxShadow: '0 1px 3px rgba(0,0,0,0.08), 0 1px 2px rgba(0,0,0,0.04)',
                            height: '100%',
                        }}
                    >
                        <Box display="flex" alignItems="center" gap={2} mb={2}>
                            <Box
                                sx={{
                                    width: 48,
                                    height: 48,
                                    borderRadius: 2,
                                    bgcolor: 'rgba(52, 168, 83, 0.1)',
                                    display: 'flex',
                                    alignItems: 'center',
                                    justifyContent: 'center',
                                }}
                            >
                                <WhatsApp sx={{ color: '#34A853', fontSize: 24 }} />
                            </Box>
                            <Box>
                                <Typography variant="h6" sx={{ fontWeight: 600 }}>
                                    System Status
                                </Typography>
                                <Typography variant="caption" sx={{ color: 'text.secondary' }}>
                                    All systems operational
                                </Typography>
                            </Box>
                        </Box>
                        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1.5 }}>
                            {[
                                { label: 'All systems operational', status: 'success' },
                                { label: 'WhatsApp API connected', status: 'success' },
                                { label: 'Database sync active', status: 'success' },
                                { label: 'Real-time updates enabled', status: 'success' },
                            ].map((item, idx) => (
                                <Box
                                    key={idx}
                                    sx={{
                                        display: 'flex',
                                        alignItems: 'center',
                                        gap: 1.5,
                                        p: 1,
                                        borderRadius: 1.5,
                                        bgcolor: '#F8F9FA',
                                    }}
                                >
                                    <Box
                                        sx={{
                                            width: 8,
                                            height: 8,
                                            borderRadius: '50%',
                                            bgcolor: '#34A853',
                                            animation: 'pulse 2s infinite',
                                            '@keyframes pulse': {
                                                '0%': { opacity: 1 },
                                                '50%': { opacity: 0.5 },
                                                '100%': { opacity: 1 },
                                            },
                                        }}
                                    />
                                    <Typography variant="body2" sx={{ color: '#202124', fontWeight: 500 }}>
                                        {item.label}
                                    </Typography>
                                </Box>
                            ))}
                        </Box>
                    </Paper>
                </Grid>
            </Grid>
        </Box>
    );
};

export default Dashboard;
