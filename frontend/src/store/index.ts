import { configureStore } from '@reduxjs/toolkit';
import authReducer from './authSlice';
import dashboardReducer from './dashboardSlice';
import vendorReducer from './vendorSlice';
import customerReducer from './customerSlice';
import orderReducer from './orderSlice';
import whatsappReducer from './whatsappSlice';
import commissionReducer from './commissionSlice';

export const store = configureStore({
    reducer: {
        auth: authReducer,
        dashboard: dashboardReducer,
        vendors: vendorReducer,
        customers: customerReducer,
        orders: orderReducer,
        whatsapp: whatsappReducer,
        commissions: commissionReducer,
    },
});

export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;
