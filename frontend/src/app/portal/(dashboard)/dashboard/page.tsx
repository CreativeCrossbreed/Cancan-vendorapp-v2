'use client';
import React, { useEffect } from 'react';
import {
    Activity,
    ArrowDown,
    ArrowUp,
    ArrowUpRight,
    Hourglass,
    IndianRupee,
    MessageCircle,
    Percent,
    ReceiptText,
    Store,
    Users,
    UserCheck,
} from 'lucide-react';
import { useDispatch, useSelector } from 'react-redux';
import { RootState, AppDispatch } from '@/store';
import { fetchDashboardStats } from '@/store/dashboardSlice';

const Dashboard: React.FC = () => {
    const dispatch = useDispatch<AppDispatch>();
    const { stats, isLoading, error } = useSelector((state: RootState) => state.dashboard);

    useEffect(() => {
        dispatch(fetchDashboardStats());
    }, [dispatch]);

    const statCards: Array<{
        title: string;
        value: React.ReactNode;
        Icon: React.ComponentType<{ className?: string }>;
        iconBg: string;
        iconColor: string;
        trend: string | null;
    }> = [
            { title: 'Total Vendors', value: stats?.totalVendors ?? 0, Icon: Store, iconBg: 'bg-blue-100', iconColor: 'text-blue-700', trend: null },
            { title: 'Active Vendors', value: stats?.activeVendors ?? 0, Icon: UserCheck, iconBg: 'bg-green-100', iconColor: 'text-green-700', trend: '+12%' },
            { title: 'Total Customers', value: stats?.totalCustomers ?? 0, Icon: Users, iconBg: 'bg-amber-100', iconColor: 'text-amber-800', trend: '+8%' },
            { title: "Today's Orders", value: stats?.todayOrders ?? 0, Icon: ReceiptText, iconBg: 'bg-violet-100', iconColor: 'text-violet-700', trend: '+5%' },
            { title: "Today's Revenue", value: `₹${stats?.todayRevenue ?? 0}`, Icon: IndianRupee, iconBg: 'bg-red-100', iconColor: 'text-red-700', trend: '+15%' },
            { title: 'Commission Earned', value: `₹${stats?.commissionEarned ?? 0}`, Icon: Percent, iconBg: 'bg-sky-100', iconColor: 'text-sky-700', trend: null },
            { title: 'WhatsApp Orders', value: stats?.whatsappOrdersProcessed ?? 0, Icon: MessageCircle, iconBg: 'bg-green-100', iconColor: 'text-green-700', trend: '+22%' },
            { title: 'Pending Payments', value: `₹${stats?.pendingPayments ?? 0}`, Icon: Hourglass, iconBg: 'bg-orange-100', iconColor: 'text-orange-700', trend: '-3%' },
        ];

    if (isLoading && !stats) {
        return (
            <div className="flex justify-center items-center min-h-[60vh]">
                <div className="w-10 h-10 border-2 border-cancan-primary border-t-transparent rounded-full animate-spin" />
            </div>
        );
    }

    if (error) {
        return (
            <div className="flex justify-center items-center min-h-[60vh]">
                <p className="text-red-600 font-medium">{error}</p>
            </div>
        );
    }

    return (
        <div>
            {/* Header */}
            <div className="mb-8">
                <h1 className="text-2xl font-semibold text-slate-900 mb-1">
                    Dashboard
                </h1>
                <p className="text-slate-600">
                    Welcome to the Can Can Water Can Delivery Admin Dashboard
                </p>
            </div>

            {/* Stat Cards */}
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
                {statCards.map((card, index) => {
                    const TrendIcon = card.trend?.startsWith('+') ? ArrowUp : ArrowDown;
                    const trendColor = card.trend?.startsWith('+') ? 'text-green-600' : 'text-red-600';
                    return (
                        <div
                            key={index}
                            className="h-full rounded-xl bg-white border border-slate-200 shadow-sm hover:shadow-md hover:-translate-y-0.5 transition-all duration-200 p-5"
                        >
                            <div className="flex items-start justify-between">
                                <div>
                                    <p className="text-sm font-medium text-slate-500 mb-1">{card.title}</p>
                                    <p className="text-xl font-bold text-slate-900">{card.value}</p>
                                    {card.trend && (
                                        <div className="flex items-center gap-1 mt-2">
                                            <TrendIcon className={`w-3.5 h-3.5 ${trendColor}`} />
                                            <span className={`text-xs font-semibold ${trendColor}`}>{card.trend}</span>
                                            <span className="text-xs text-slate-500">vs last month</span>
                                        </div>
                                    )}
                                </div>
                                <div className={`rounded-xl p-2.5 ${card.iconBg} ${card.iconColor}`}>
                                    <card.Icon className="w-5 h-5" />
                                </div>
                            </div>
                        </div>
                    );
                })}
            </div>

            {/* Info Cards */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mt-4">
                <div className="p-6 rounded-xl bg-white border border-slate-200 shadow-sm">
                    <div className="flex items-center gap-3 mb-4">
                        <div className="w-12 h-12 rounded-xl bg-blue-100 flex items-center justify-center text-blue-600">
                            <ArrowUpRight className="w-6 h-6" />
                        </div>
                        <div>
                            <h2 className="text-lg font-semibold text-slate-900">Quick Actions</h2>
                            <p className="text-sm text-slate-500">Common tasks</p>
                        </div>
                    </div>
                    <div className="flex flex-col gap-2">
                        {[
                            { label: 'View and manage all vendors', dot: 'bg-blue-600' },
                            { label: 'Monitor customer orders', dot: 'bg-green-600' },
                            { label: 'Track WhatsApp integrations', dot: 'bg-amber-500' },
                            { label: 'Manage commission payments', dot: 'bg-red-600' },
                        ].map((item, idx) => (
                            <div key={idx} className="flex items-center gap-2">
                                <span className={`w-2 h-2 rounded-full ${item.dot}`} />
                                <span className="text-sm text-slate-600">{item.label}</span>
                            </div>
                        ))}
                    </div>
                </div>

                <div className="p-6 rounded-xl bg-white border border-slate-200 shadow-sm">
                    <div className="flex items-center gap-3 mb-4">
                        <div className="w-12 h-12 rounded-xl bg-green-100 flex items-center justify-center text-green-600">
                            <Activity className="w-6 h-6" />
                        </div>
                        <div>
                            <h2 className="text-lg font-semibold text-slate-900">System Status</h2>
                            <p className="text-sm text-slate-500">All systems operational</p>
                        </div>
                    </div>
                    <div className="flex flex-col gap-2">
                        {[
                            'All systems operational',
                            'WhatsApp API connected',
                            'Database sync active',
                            'Real-time updates enabled',
                        ].map((label, idx) => (
                            <div key={idx} className="flex items-center gap-2 p-2 rounded-lg bg-slate-50">
                                <span className="w-2 h-2 rounded-full bg-green-500 animate-pulse" />
                                <span className="text-sm font-medium text-slate-800">{label}</span>
                            </div>
                        ))}
                    </div>
                </div>
            </div>
        </div>
    );
};

export default Dashboard;
