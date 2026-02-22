import { createSlice, createAsyncThunk, PayloadAction } from '@reduxjs/toolkit';
import { WhatsAppMessage, WhatsAppOrder } from '@/types';
import apiService from '@/services/api';

interface WhatsAppState {
    config: any;
    messages: WhatsAppMessage[];
    orders: WhatsAppOrder[];
    pagination: { page: number; limit: number; total: number; totalPages: number };
    isLoading: boolean;
    error: string | null;
}

const initialState: WhatsAppState = {
    config: null,
    messages: [],
    orders: [],
    pagination: { page: 1, limit: 10, total: 0, totalPages: 0 },
    isLoading: false,
    error: null,
};

export const fetchWhatsAppConfig = createAsyncThunk(
    'whatsapp/fetchConfig',
    async (_, { rejectWithValue }) => {
        try {
            const response = await apiService.getWhatsAppConfig();
            return response;
        } catch (error: any) {
            return rejectWithValue(error.response?.data?.error || 'Failed to fetch WhatsApp config');
        }
    }
);

export const fetchWhatsAppMessages = createAsyncThunk(
    'whatsapp/fetchMessages',
    async (params: any, { rejectWithValue }) => {
        try {
            const response = await apiService.getWhatsAppMessages(params);
            return response;
        } catch (error: any) {
            return rejectWithValue(error.response?.data?.error || 'Failed to fetch WhatsApp messages');
        }
    }
);

export const fetchWhatsAppOrders = createAsyncThunk(
    'whatsapp/fetchOrders',
    async (params: any, { rejectWithValue }) => {
        try {
            const response = await apiService.getWhatsAppOrders(params);
            return response;
        } catch (error: any) {
            return rejectWithValue(error.response?.data?.error || 'Failed to fetch WhatsApp orders');
        }
    }
);

const whatsappSlice = createSlice({
    name: 'whatsapp',
    initialState,
    reducers: {
        clearError: (state) => { state.error = null; },
    },
    extraReducers: (builder) => {
        builder
            .addCase(fetchWhatsAppConfig.fulfilled, (state, action: PayloadAction<any>) => {
                state.config = action.payload;
            })
            .addCase(fetchWhatsAppMessages.fulfilled, (state, action: PayloadAction<any>) => {
                state.messages = action.payload.messages;
                state.pagination = action.payload.pagination;
            })
            .addCase(fetchWhatsAppOrders.fulfilled, (state, action: PayloadAction<any>) => {
                state.orders = action.payload.orders;
                state.pagination = action.payload.pagination;
            });
    },
});

export default whatsappSlice.reducer;
