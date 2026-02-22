'use client';

import React, { useState, useEffect } from 'react';
import { useRouter, usePathname } from 'next/navigation';
import Image from 'next/image';
import {
    Box,
    Drawer,
    List,
    ListItem,
    ListItemButton,
    ListItemIcon,
    ListItemText,
    AppBar,
    Toolbar,
    IconButton,
    Typography,
    Avatar,
    Menu,
    MenuItem,
    Divider,
    useMediaQuery,
    useTheme,
    CircularProgress,
} from '@mui/material';
import {
    Dashboard,
    Store,
    People,
    ShoppingCart,
    WhatsApp,
    AttachMoney,
    Settings,
    Menu as MenuIcon,
    ChevronLeft,
    Logout,
    Person,
} from '@mui/icons-material';
import { useDispatch, useSelector } from 'react-redux';
import { logout, getProfile } from '@/store/authSlice';
import type { AppDispatch, RootState } from '@/store';
import { StoreProvider } from '@/store/StoreProvider';

const DRAWER_WIDTH = 260;
const DRAWER_COLLAPSED = 72;

const menuItems = [
    { text: 'Dashboard', icon: <Dashboard />, path: '/portal/dashboard' },
    { text: 'Vendors', icon: <Store />, path: '/portal/vendors' },
    { text: 'Customers', icon: <People />, path: '/portal/customers' },
    { text: 'Orders', icon: <ShoppingCart />, path: '/portal/orders' },
    { text: 'WhatsApp', icon: <WhatsApp />, path: '/portal/whatsapp' },
    { text: 'Commissions', icon: <AttachMoney />, path: '/portal/commissions' },
    { text: 'Settings', icon: <Settings />, path: '/portal/settings' },
];

function PortalShell({ children }: { children: React.ReactNode }) {
    const router = useRouter();
    const pathname = usePathname();
    const dispatch = useDispatch<AppDispatch>();
    const { user, token } = useSelector((state: RootState) => state.auth);
    const theme = useTheme();
    const isMobile = useMediaQuery(theme.breakpoints.down('md'));

    const [collapsed, setCollapsed] = useState(false);
    const [mobileOpen, setMobileOpen] = useState(false);
    const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
    const [checking, setChecking] = useState(true);

    useEffect(() => {
        if (!token) {
            router.replace('/portal/login');
            return;
        }
        if (!user) {
            dispatch(getProfile()).finally(() => setChecking(false));
        } else {
            setChecking(false);
        }
    }, [token, user, dispatch, router]);

    const handleLogout = () => {
        dispatch(logout());
        setAnchorEl(null);
        router.push('/portal/login');
    };

    if (checking) {
        return (
            <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'center', minHeight: '100vh' }}>
                <CircularProgress sx={{ color: '#6DD3DC' }} />
            </Box>
        );
    }

    const drawerWidth = collapsed && !isMobile ? DRAWER_COLLAPSED : DRAWER_WIDTH;

    const pageTitle =
        menuItems.find((item) => pathname.startsWith(item.path))?.text || 'Portal';

    const drawerContent = (
        <Box sx={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
            <Box
                sx={{
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: collapsed ? 'center' : 'space-between',
                    p: 2,
                    minHeight: 64,
                }}
            >
                {!collapsed && (
                    <Image
                        src="/cancan/cancan-logo.png"
                        alt="Can Can"
                        width={100}
                        height={36}
                        priority
                    />
                )}
                {!isMobile && (
                    <IconButton onClick={() => setCollapsed(!collapsed)} size="small">
                        <ChevronLeft sx={{ transform: collapsed ? 'rotate(180deg)' : 'none', transition: '0.2s' }} />
                    </IconButton>
                )}
            </Box>
            <Divider />
            <List sx={{ flex: 1, px: 1, py: 1 }}>
                {menuItems.map((item) => {
                    const active = pathname.startsWith(item.path);
                    return (
                        <ListItem key={item.text} disablePadding sx={{ mb: 0.5 }}>
                            <ListItemButton
                                onClick={() => {
                                    router.push(item.path);
                                    if (isMobile) setMobileOpen(false);
                                }}
                                sx={{
                                    borderRadius: 2,
                                    minHeight: 44,
                                    justifyContent: collapsed ? 'center' : 'flex-start',
                                    px: collapsed ? 1.5 : 2,
                                    bgcolor: active ? 'rgba(109,211,220,0.12)' : 'transparent',
                                    color: active ? '#4BBFC9' : 'text.secondary',
                                    '&:hover': {
                                        bgcolor: active ? 'rgba(109,211,220,0.16)' : 'rgba(0,0,0,0.04)',
                                    },
                                }}
                            >
                                <ListItemIcon
                                    sx={{
                                        minWidth: collapsed ? 0 : 40,
                                        color: 'inherit',
                                        justifyContent: 'center',
                                    }}
                                >
                                    {item.icon}
                                </ListItemIcon>
                                {!collapsed && <ListItemText primary={item.text} primaryTypographyProps={{ fontWeight: active ? 700 : 500, fontSize: '0.9rem' }} />}
                            </ListItemButton>
                        </ListItem>
                    );
                })}
            </List>
        </Box>
    );

    return (
        <Box sx={{ display: 'flex', minHeight: '100vh', bgcolor: '#f8fafc' }}>
            {/* Desktop drawer */}
            {!isMobile && (
                <Drawer
                    variant="permanent"
                    sx={{
                        width: drawerWidth,
                        flexShrink: 0,
                        transition: 'width 0.2s',
                        '& .MuiDrawer-paper': {
                            width: drawerWidth,
                            transition: 'width 0.2s',
                            borderRight: '1px solid rgba(0,0,0,0.06)',
                            overflow: 'hidden',
                        },
                    }}
                >
                    {drawerContent}
                </Drawer>
            )}

            {/* Mobile drawer */}
            {isMobile && (
                <Drawer
                    variant="temporary"
                    open={mobileOpen}
                    onClose={() => setMobileOpen(false)}
                    sx={{ '& .MuiDrawer-paper': { width: DRAWER_WIDTH } }}
                >
                    {drawerContent}
                </Drawer>
            )}

            {/* Main content */}
            <Box sx={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0 }}>
                <AppBar
                    position="sticky"
                    elevation={0}
                    sx={{
                        bgcolor: '#fff',
                        color: 'text.primary',
                        borderBottom: '1px solid rgba(0,0,0,0.06)',
                    }}
                >
                    <Toolbar>
                        {isMobile && (
                            <IconButton onClick={() => setMobileOpen(true)} sx={{ mr: 1 }}>
                                <MenuIcon />
                            </IconButton>
                        )}
                        <Typography variant="h6" sx={{ fontWeight: 700, flex: 1, fontSize: '1.1rem' }}>
                            {pageTitle}
                        </Typography>
                        <IconButton onClick={(e) => setAnchorEl(e.currentTarget)}>
                            <Avatar sx={{ width: 34, height: 34, bgcolor: '#6DD3DC', fontSize: '0.9rem' }}>
                                {user?.email?.charAt(0).toUpperCase() || 'A'}
                            </Avatar>
                        </IconButton>
                        <Menu
                            anchorEl={anchorEl}
                            open={!!anchorEl}
                            onClose={() => setAnchorEl(null)}
                            transformOrigin={{ horizontal: 'right', vertical: 'top' }}
                            anchorOrigin={{ horizontal: 'right', vertical: 'bottom' }}
                        >
                            <MenuItem disabled>
                                <Person sx={{ mr: 1, fontSize: 18 }} />
                                {user?.email || 'Admin'}
                            </MenuItem>
                            <Divider />
                            <MenuItem onClick={handleLogout} sx={{ color: 'error.main' }}>
                                <Logout sx={{ mr: 1, fontSize: 18 }} />
                                Logout
                            </MenuItem>
                        </Menu>
                    </Toolbar>
                </AppBar>
                <Box component="main" sx={{ flex: 1, p: { xs: 2, sm: 3 }, overflow: 'auto' }}>
                    {children}
                </Box>
            </Box>
        </Box>
    );
}

export default function PortalLayout({ children }: { children: React.ReactNode }) {
    return (
        <StoreProvider>
            <PortalShell>{children}</PortalShell>
        </StoreProvider>
    );
}

