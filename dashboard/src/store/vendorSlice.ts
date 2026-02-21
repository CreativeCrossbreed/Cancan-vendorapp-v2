import { createSlice, createAsyncThunk, PayloadAction } from '@reduxjs/toolkit';
import { Vendor } from '../types';
import apiService from '../services/api';

interface VendorState {
  vendors: Vendor[];
  currentVendor: Vendor | null;
  pagination: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
  };
  isLoading: boolean;
  error: string | null;
}

const initialState: VendorState = {
  vendors: [],
  currentVendor: null,
  pagination: {
    page: 1,
    limit: 10,
    total: 0,
    totalPages: 0,
  },
  isLoading: false,
  error: null,
};

export const fetchVendors = createAsyncThunk(
  'vendors/fetchVendors',
  async (params: any, { rejectWithValue }) => {
    try {
      const response = await apiService.getVendors(params);
      return response;
    } catch (error: any) {
      return rejectWithValue(error.response?.data?.error || 'Failed to fetch vendors');
    }
  }
);

const vendorSlice = createSlice({
  name: 'vendors',
  initialState,
  reducers: {
    clearError: (state) => {
      state.error = null;
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetchVendors.pending, (state) => {
        state.isLoading = true;
        state.error = null;
      })
      .addCase(fetchVendors.fulfilled, (state, action: PayloadAction<any>) => {
        state.isLoading = false;
        state.vendors = action.payload.vendors;
        state.pagination = action.payload.pagination;
      })
      .addCase(fetchVendors.rejected, (state, action: PayloadAction<any>) => {
        state.isLoading = false;
        state.error = action.payload;
      });
  },
});

export default vendorSlice.reducer;