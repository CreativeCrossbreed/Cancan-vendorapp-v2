import { configureStore } from '@reduxjs/toolkit';
import authSlice from './authSlice';
import dashboardSlice from './dashboardSlice';
import vendorSlice from './vendorSlice';
import customerSlice from './customerSlice';
import orderSlice from './orderSlice';
import whatsappSlice from './whatsappSlice';
import commissionSlice from './commissionSlice';

export const store = configureStore({
  reducer: {
    auth: authSlice,
    dashboard: dashboardSlice,
    vendors: vendorSlice,
    customers: customerSlice,
    orders: orderSlice,
    whatsapp: whatsappSlice,
    commissions: commissionSlice,
  },
});

export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;