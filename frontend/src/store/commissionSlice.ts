import { createSlice, createAsyncThunk, PayloadAction } from '@reduxjs/toolkit';
import { CommissionRecord } from '../types';
import apiService from '../services/api';

interface CommissionState {
  commissions: CommissionRecord[];
  stats: any;
  vendorBreakdown: any[];
  trends: any[];
  pagination: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
  };
  isLoading: boolean;
  error: string | null;
}

const initialState: CommissionState = {
  commissions: [],
  stats: null,
  vendorBreakdown: [],
  trends: [],
  pagination: {
    page: 1,
    limit: 10,
    total: 0,
    totalPages: 0,
  },
  isLoading: false,
  error: null,
};

export const fetchCommissions = createAsyncThunk(
  'commissions/fetchCommissions',
  async (params: any, { rejectWithValue }) => {
    try {
      const response = await apiService.getCommissions(params);
      return response;
    } catch (error: any) {
      return rejectWithValue(error.response?.data?.error || 'Failed to fetch commissions');
    }
  }
);

const commissionSlice = createSlice({
  name: 'commissions',
  initialState,
  reducers: {
    clearError: (state) => {
      state.error = null;
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetchCommissions.pending, (state) => {
        state.isLoading = true;
        state.error = null;
      })
      .addCase(fetchCommissions.fulfilled, (state, action: PayloadAction<any>) => {
        state.isLoading = false;
        state.commissions = action.payload.commissions;
        state.pagination = action.payload.pagination;
      })
      .addCase(fetchCommissions.rejected, (state, action: PayloadAction<any>) => {
        state.isLoading = false;
        state.error = action.payload;
      });
  },
});

export default commissionSlice.reducer;