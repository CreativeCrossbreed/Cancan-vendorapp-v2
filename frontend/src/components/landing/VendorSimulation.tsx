'use client';

import { useState, useEffect, useRef, useCallback } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { playKaChing } from './SoundEngine';

interface Order {
    id: number;
    customer: string;
    brand: string;
    qty: number;
    area: string;
    amount: number;
    time: string;
}

const CUSTOMERS = [
    'Priya S.', 'Karthik R.', 'Lakshmi V.', 'Arun K.',
    'Deepa M.', 'Vijay P.', 'Meena G.', 'Suresh N.',
    'Kavitha T.', 'Raj B.', 'Anitha L.', 'Kumar D.',
];
const BRANDS = ['Bisleri 20L', 'Kinley 20L', 'Local Brand'];
const AREAS = [
    'T. Nagar', 'Anna Nagar', 'Adyar', 'Velachery',
    'Porur', 'Tambaram', 'Chromepet', 'Guindy',
    'Mylapore', 'Besant Nagar', 'Kodambakkam', 'Ashok Nagar',
];
const PRICES: Record<string, number> = { 'Bisleri 20L': 70, 'Kinley 20L': 65, 'Local Brand': 50 };

function randomOrder(id: number): Order {
    const brand = BRANDS[Math.floor(Math.random() * BRANDS.length)];
    const qty = Math.random() > 0.6 ? Math.floor(Math.random() * 4) + 2 : 1;
    const now = new Date();
    const h = now.getHours();
    const m = now.getMinutes();
    return {
        id,
        customer: CUSTOMERS[Math.floor(Math.random() * CUSTOMERS.length)],
        brand,
        qty,
        area: AREAS[Math.floor(Math.random() * AREAS.length)],
        amount: PRICES[brand] * qty,
        time: `${h.toString().padStart(2, '0')}:${m.toString().padStart(2, '0')}`,
    };
}

/** Animated INR counter with realistic ticking */
function INRCounter({ value }: { value: number }) {
    const [display, setDisplay] = useState(0);
    const animRef = useRef<number>(0);

    useEffect(() => {
        const start = display;
        const diff = value - start;
        if (diff === 0) return;

        const duration = 600;
        const startTime = performance.now();

        const tick = (now: number) => {
            const elapsed = now - startTime;
            const progress = Math.min(elapsed / duration, 1);
            // Ease out cubic
            const ease = 1 - Math.pow(1 - progress, 3);
            setDisplay(Math.round(start + diff * ease));
            if (progress < 1) {
                animRef.current = requestAnimationFrame(tick);
            }
        };

        animRef.current = requestAnimationFrame(tick);
        return () => { if (animRef.current) cancelAnimationFrame(animRef.current); };
    }, [value]); // eslint-disable-line react-hooks/exhaustive-deps

    return (
        <span className="text-[1.4rem] font-black tabular-nums tracking-tighter text-emerald-500">
            ₹{display.toLocaleString('en-IN')}
        </span>
    );
}

export default function VendorSimulation({ soundEnabled }: { soundEnabled: boolean }) {
    const [orders, setOrders] = useState<Order[]>([]);
    const [total, setTotal] = useState(0);
    const [orderCount, setOrderCount] = useState(0);
    const idRef = useRef(0);
    const intervalRef = useRef<NodeJS.Timeout | null>(null);

    const addOrder = useCallback(() => {
        idRef.current += 1;
        const order = randomOrder(idRef.current);
        setOrders((prev) => [order, ...prev].slice(0, 6));
        setTotal((prev) => prev + order.amount);
        setOrderCount((prev) => prev + 1);
        if (soundEnabled) playKaChing();
    }, [soundEnabled]);

    useEffect(() => {
        // Start with 2 orders
        setTimeout(() => addOrder(), 500);
        setTimeout(() => addOrder(), 1200);

        // Then every 3-5 seconds
        intervalRef.current = setInterval(() => {
            addOrder();
        }, 3000 + Math.random() * 2000);

        return () => { if (intervalRef.current) clearInterval(intervalRef.current); };
    }, []); // eslint-disable-line react-hooks/exhaustive-deps

    return (
        <div className="w-full max-w-[480px] rounded-2xl overflow-hidden bg-slate-900 border border-white/10 shadow-3xl">
            {/* Header */}
            <div className="px-6 py-5 border-b border-white/10 bg-slate-900/50 backdrop-blur-md">
                <div className="flex items-center gap-2.5 text-[#f8fafc] text-[15px] font-black">
                    <div className="w-2.5 h-2.5 rounded-full bg-emerald-500 shadow-[0_0_12px_rgba(16,185,129,0.6)] animate-pulse" />
                    Vendor Dashboard — Live
                </div>
                <div className="text-slate-500 text-[11px] mt-1 font-medium italic">Simulation of real vendor experience</div>
            </div>

            {/* Stats Row */}
            <div className="grid grid-cols-3 border-b border-white/5">
                <div className="p-5 flex flex-col gap-1.5 text-center border-r border-white/5">
                    <span className="text-[10px] font-black uppercase tracking-widest text-slate-500">Collection</span>
                    <INRCounter value={total} />
                </div>
                <div className="p-5 flex flex-col gap-1.5 text-center border-r border-white/5">
                    <span className="text-[10px] font-black uppercase tracking-widest text-slate-500">Orders</span>
                    <motion.span
                        className="text-[1.4rem] font-black tabular-nums tracking-tighter text-[#f8fafc]"
                        key={orderCount}
                        initial={{ scale: 1.3, color: '#10b981' }}
                        animate={{ scale: 1, color: '#f8fafc' }}
                        transition={{ duration: 0.4 }}
                    >
                        {orderCount}
                    </motion.span>
                </div>
                <div className="p-5 flex flex-col gap-1.5 text-center">
                    <span className="text-[10px] font-black uppercase tracking-widest text-slate-500">Avg Order</span>
                    <span className="text-[1.4rem] font-black tabular-nums tracking-tighter text-[#f8fafc]">
                        ₹{orderCount > 0 ? Math.round(total / orderCount) : 0}
                    </span>
                </div>
            </div>

            {/* Order Feed */}
            <div className="bg-slate-900/40">
                <div className="px-6 py-3 text-[10px] font-black uppercase tracking-widest text-slate-500 border-b border-white/5">Recent Orders</div>
                <div className="max-h-[300px] overflow-y-auto scrollbar-hide">
                    <AnimatePresence mode="popLayout">
                        {orders.map((order) => (
                            <motion.div
                                key={order.id}
                                className="flex justify-between items-center px-6 py-4 border-b border-white/5 hover:bg-white/[0.02] transition-colors"
                                initial={{ opacity: 0, x: -20, height: 0 }}
                                animate={{ opacity: 1, x: 0, height: 'auto' }}
                                exit={{ opacity: 0, height: 0 }}
                                transition={{ duration: 0.4, ease: [0.22, 1, 0.36, 1] }}
                                layout
                            >
                                <div className="flex flex-col gap-0.5">
                                    <span className="text-[#f8fafc] text-[14px] font-black">{order.customer}</span>
                                    <span className="text-slate-500 text-[11px] font-medium">
                                        {order.qty}x {order.brand} · {order.area}
                                    </span>
                                </div>
                                <div className="flex flex-col items-end gap-0.5">
                                    <span className="text-emerald-500 text-[15px] font-black tabular-nums">₹{order.amount}</span>
                                    <span className="text-slate-600 text-[10px] font-bold">{order.time}</span>
                                </div>
                            </motion.div>
                        ))}
                    </AnimatePresence>
                </div>
            </div>
        </div>
    );
}
