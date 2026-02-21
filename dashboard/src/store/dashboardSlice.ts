import { createSlice, createAsyncThunk, PayloadAction } from '@reduxjs/toolkit';
import { DashboardStats } from '../types';
import apiService from '../services/api';

interface DashboardState {
  stats: DashboardStats | null;
  revenueAnalytics: any[];
  topVendors: any[];
  recentActivities: any[];
  orderDistribution: any;
  isLoading: boolean;
  error: string | null;
}

const initialState: DashboardState = {
  stats: null,
  revenueAnalytics: [],
  topVendors: [],
  recentActivities: [],
  orderDistribution: {},
  isLoading: false,
  error: null,
};

// Async thunks
export const fetchDashboardStats = createAsyncThunk(
  'dashboard/fetchStats',
  async (_, { rejectWithValue }) => {
    try {
      const stats = await apiService.getDashboardStats();
      return stats;
    } catch (error: any) {
      return rejectWithValue(error.response?.data?.error || 'Failed to fetch dashboard stats');
    }
  }
);

export const fetchRevenueAnalytics = createAsyncThunk(
  'dashboard/fetchRevenueAnalytics',
  async (period: number = 7, { rejectWithValue }) => {
    try {
      const data = await apiService.getRevenueAnalytics(period);
      return data;
    } catch (error: any) {
      return rejectWithValue(error.response?.data?.error || 'Failed to fetch revenue analytics');
    }
  }
);

export const fetchTopVendors = createAsyncThunk(
  'dashboard/fetchTopVendors',
  async (period: number = 30, { rejectWithValue }) => {
    try {
      const data = await apiService.getTopVendors(period);
      return data;
    } catch (error: any) {
      return rejectWithValue(error.response?.data?.error || 'Failed to fetch top vendors');
    }
  }
);

export const fetchRecentActivities = createAsyncThunk(
  'dashboard/fetchRecentActivities',
  async (_, { rejectWithValue }) => {
    try {
      const data = await apiService.getRecentActivities();
      return data;
    } catch (error: any) {
      return rejectWithValue(error.response?.data?.error || 'Failed to fetch recent activities');
    }
  }
);

export const fetchOrderDistribution = createAsyncThunk(
  'dashboard/fetchOrderDistribution',
  async (period: number = 7, { rejectWithValue }) => {
    try {
      const data = await apiService.getOrderDistribution(period);
      return data;
    } catch (error: any) {
      return rejectWithValue(error.response?.data?.error || 'Failed to fetch order distribution');
    }
  }
);

const dashboardSlice = createSlice({
  name: 'dashboard',
  initialState,
  reducers: {
    clearError: (state) => {
      state.error = null;
    },
  },
  extraReducers: (builder) => {
    builder
      // Dashboard Stats
      .addCase(fetchDashboardStats.pending, (state) => {
        state.isLoading = true;
        state.error = null;
      })
      .addCase(fetchDashboardStats.fulfilled, (state, action: PayloadAction<DashboardStats>) => {
        state.isLoading = false;
        state.stats = action.payload;
      })
      .addCase(fetchDashboardStats.rejected, (state, action: PayloadAction<any>) => {
        state.isLoading = false;
        state.error = action.payload;
      })
      // Revenue Analytics
      .addCase(fetchRevenueAnalytics.fulfilled, (state, action: PayloadAction<any[]>) => {
        state.revenueAnalytics = action.payload;
      })
      // Top Vendors
      .addCase(fetchTopVendors.fulfilled, (state, action: PayloadAction<any[]>) => {
        state.topVendors = action.payload;
      })
      // Recent Activities
      .addCase(fetchRecentActivities.fulfilled, (state, action: PayloadAction<any[]>) => {
        state.recentActivities = action.payload;
      })
      // Order Distribution
      .addCase(fetchOrderDistribution.fulfilled, (state, action: PayloadAction<any>) => {
        state.orderDistribution = action.payload;
      });
  },
});

export const { clearError } = dashboardSlice.actions;
export default dashboardSlice.reducer;