'use client';

import React, { useState, useEffect } from 'react';
import { useRouter, usePathname } from 'next/navigation';
import Image from 'next/image';
import {
    ChevronLeft,
    IndianRupee,
    LayoutDashboard,
    LogOut,
    MessageCircle,
    Menu,
    Package,
    Settings,
    Store,
    User,
    Users,
} from 'lucide-react';
import { useDispatch, useSelector } from 'react-redux';
import { logout, getProfile } from '@/store/authSlice';
import type { AppDispatch, RootState } from '@/store';
import { StoreProvider } from '@/store/StoreProvider';

const DRAWER_WIDTH = 260;
const DRAWER_COLLAPSED = 72;

const menuItems: Array<{ text: string; path: string; Icon: React.ComponentType<{ className?: string }> }> = [
    { text: 'Dashboard', path: '/portal/dashboard', Icon: LayoutDashboard },
    { text: 'Vendors', path: '/portal/vendors', Icon: Store },
    { text: 'Customers', path: '/portal/customers', Icon: Users },
    { text: 'Orders', path: '/portal/orders', Icon: Package },
    { text: 'WhatsApp', path: '/portal/whatsapp', Icon: MessageCircle },
    { text: 'Commissions', path: '/portal/commissions', Icon: IndianRupee },
    { text: 'Settings', path: '/portal/settings', Icon: Settings },
];

function useIsMobile() {
    const [isMobile, setIsMobile] = useState(false);
    useEffect(() => {
        const mq = window.matchMedia('(max-width: 768px)');
        const update = () => setIsMobile(mq.matches);
        update();
        mq.addEventListener('change', update);
        return () => mq.removeEventListener('change', update);
    }, []);
    return isMobile;
}

function PortalShell({ children }: { children: React.ReactNode }) {
    const router = useRouter();
    const pathname = usePathname();
    const dispatch = useDispatch<AppDispatch>();
    const { user, token } = useSelector((state: RootState) => state.auth);
    const isMobile = useIsMobile();

    const [collapsed, setCollapsed] = useState(false);
    const [mobileOpen, setMobileOpen] = useState(false);
    const [userMenuOpen, setUserMenuOpen] = useState(false);
    const [checking, setChecking] = useState(true);

    useEffect(() => {
        if (!token) {
            router.replace('/portal/login');
            return;
        }
        if (!user) {
            dispatch(getProfile()).finally(() => setChecking(false));
        } else {
            const t = setTimeout(() => setChecking(false), 0);
            return () => clearTimeout(t);
        }
    }, [token, user, dispatch, router]);

    const handleLogout = () => {
        dispatch(logout());
        setUserMenuOpen(false);
        router.push('/portal/login');
    };

    if (checking) {
        return (
            <div className="flex items-center justify-center min-h-screen bg-slate-50">
                <div className="w-10 h-10 border-2 border-cancan-primary border-t-transparent rounded-full animate-spin" />
            </div>
        );
    }

    const drawerWidth = collapsed && !isMobile ? DRAWER_COLLAPSED : DRAWER_WIDTH;
    const pageTitle = menuItems.find((item) => pathname.startsWith(item.path))?.text || 'Portal';

    const drawerContent = (
        <div className="flex flex-col h-full">
            <div
                className={`flex items-center min-h-16 px-4 ${collapsed ? 'justify-center' : 'justify-between'}`}
            >
                {!collapsed && (
                    <Image
                        src="/cancan/cancan-logo.png"
                        alt="Can Can"
                        width={40}
                        height={40}
                        className="object-contain"
                        priority
                    />
                )}
                {!isMobile && (
                    <button
                        type="button"
                        onClick={() => setCollapsed(!collapsed)}
                        className="p-1.5 rounded-lg hover:bg-black/5 text-slate-600 hover:text-slate-900 transition-colors"
                        aria-label={collapsed ? 'Expand sidebar' : 'Collapse sidebar'}
                    >
                        <ChevronLeft className={`w-5 h-5 transition-transform duration-200 ${collapsed ? 'rotate-180' : ''}`} />
                    </button>
                )}
            </div>
            <div className="border-t border-slate-200" />
            <nav className="flex-1 px-2 py-2 overflow-y-auto">
                {menuItems.map((item) => {
                    const active = pathname.startsWith(item.path);
                    return (
                        <button
                            key={item.text}
                            type="button"
                            onClick={() => {
                                router.push(item.path);
                                if (isMobile) setMobileOpen(false);
                            }}
                            className={`w-full flex items-center gap-3 rounded-xl min-h-[44px] px-3 py-2.5 text-left transition-colors ${
                                active
                                    ? 'bg-cancan-primary/10 text-cancan-primary-dark font-semibold hover:bg-cancan-primary/15'
                                    : 'text-slate-600 hover:bg-black/5 font-medium'
                            } ${collapsed ? 'justify-center px-2' : ''}`}
                        >
                            <item.Icon className="w-5 h-5 flex-shrink-0" />
                            {!collapsed && <span className="text-sm truncate">{item.text}</span>}
                        </button>
                    );
                })}
            </nav>
        </div>
    );

    return (
        <div className="flex min-h-screen bg-slate-50">
            {/* Mobile overlay */}
            {isMobile && mobileOpen && (
                <button
                    type="button"
                    aria-label="Close menu"
                    className="fixed inset-0 z-20 bg-black/40 md:hidden"
                    onClick={() => setMobileOpen(false)}
                />
            )}

            {/* Sidebar - desktop */}
            {!isMobile && (
                <aside
                    className="flex-shrink-0 border-r border-slate-200 bg-white overflow-hidden transition-[width] duration-200 ease-out"
                    style={{ width: drawerWidth }}
                >
                    {drawerContent}
                </aside>
            )}

            {/* Sidebar - mobile drawer */}
            {isMobile && (
                <aside
                    className={`fixed top-0 left-0 z-30 h-full bg-white border-r border-slate-200 shadow-xl transition-transform duration-200 ease-out ${mobileOpen ? 'translate-x-0' : '-translate-x-full'}`}
                    style={{ width: DRAWER_WIDTH }}
                >
                    {drawerContent}
                </aside>
            )}

            {/* Main content */}
            <div className="flex-1 flex flex-col min-w-0">
                <header className="sticky top-0 z-10 flex items-center gap-2 px-4 py-3 bg-white border-b border-slate-200">
                    {isMobile && (
                        <button
                            type="button"
                            onClick={() => setMobileOpen(true)}
                            className="p-2 -ml-2 rounded-lg hover:bg-slate-100 text-slate-600"
                            aria-label="Open menu"
                        >
                            <Menu className="w-5 h-5" />
                        </button>
                    )}
                    <h1 className="flex-1 text-lg font-bold text-slate-900 truncate">
                        {pageTitle}
                    </h1>
                    <div className="relative">
                        <button
                            type="button"
                            onClick={() => setUserMenuOpen((o) => !o)}
                            className="flex items-center justify-center w-9 h-9 rounded-full bg-cancan-primary text-white text-sm font-semibold hover:opacity-90 transition-opacity"
                            aria-expanded={userMenuOpen}
                            aria-haspopup="true"
                        >
                            {user?.email?.charAt(0).toUpperCase() || 'A'}
                        </button>
                        {userMenuOpen && (
                            <>
                                <button
                                    type="button"
                                    aria-label="Close menu"
                                    className="fixed inset-0 z-10"
                                    onClick={() => setUserMenuOpen(false)}
                                />
                                <div className="absolute right-0 top-full mt-2 z-20 w-56 py-2 bg-white rounded-xl border border-slate-200 shadow-lg">
                                    <div className="flex items-center gap-2 px-4 py-2 text-slate-500 text-sm">
                                        <User className="w-4 h-4 shrink-0" />
                                        <span className="truncate">{user?.email || 'Admin'}</span>
                                    </div>
                                    <div className="border-t border-slate-100 my-1" />
                                    <button
                                        type="button"
                                        onClick={handleLogout}
                                        className="w-full flex items-center gap-2 px-4 py-2.5 text-left text-red-600 hover:bg-red-50 transition-colors"
                                    >
                                        <LogOut className="w-4 h-4 shrink-0" />
                                        Logout
                                    </button>
                                </div>
                            </>
                        )}
                    </div>
                </header>
                <main className="flex-1 p-4 sm:p-6 overflow-auto">
                    {children}
                </main>
            </div>
        </div>
    );
}

export default function PortalLayout({ children }: { children: React.ReactNode }) {
    return (
        <StoreProvider>
            <PortalShell>{children}</PortalShell>
        </StoreProvider>
    );
}
