import { createSlice, createAsyncThunk, PayloadAction } from '@reduxjs/toolkit';
import apiService from '@/services/api';

interface AuthState {
    user: { id: string; email: string; role: string; last_login?: string } | null;
    token: string | null;
    isLoading: boolean;
    error: string | null;
}

const getInitialToken = (): string | null => {
    if (typeof window !== 'undefined') {
        return localStorage.getItem('token');
    }
    return null;
};

const initialState: AuthState = {
    user: null,
    token: getInitialToken(),
    isLoading: false,
    error: null,
};

export const login = createAsyncThunk(
    'auth/login',
    async (credentials: { email: string; password: string }, { rejectWithValue }) => {
        try {
            const response = await apiService.login(credentials.email, credentials.password);
            localStorage.setItem('token', response.token);
            return response;
        } catch (error: unknown) {
            const err = error as { response?: { data?: { error?: string } } };
            return rejectWithValue(err.response?.data?.error || 'Login failed');
        }
    }
);

export const getProfile = createAsyncThunk(
    'auth/getProfile',
    async (_, { rejectWithValue }) => {
        try {
            const response = await apiService.getProfile();
            return response.user;
        } catch (error: unknown) {
            const err = error as { response?: { data?: { error?: string } } };
            return rejectWithValue(err.response?.data?.error || 'Failed to get profile');
        }
    }
);

const authSlice = createSlice({
    name: 'auth',
    initialState,
    reducers: {
        logout: (state) => {
            state.user = null;
            state.token = null;
            state.error = null;
            if (typeof window !== 'undefined') {
                localStorage.removeItem('token');
            }
        },
        clearError: (state) => {
            state.error = null;
        },
    },
    extraReducers: (builder) => {
        builder
            .addCase(login.pending, (state) => {
                state.isLoading = true;
                state.error = null;
            })
            .addCase(login.fulfilled, (state, action: PayloadAction<{ token: string; user: AuthState['user'] }>) => {
                state.isLoading = false;
                state.user = action.payload.user;
                state.token = action.payload.token;
                state.error = null;
            })
            .addCase(login.rejected, (state, action) => {
                state.isLoading = false;
                state.error = action.payload as string;
            })
            .addCase(getProfile.pending, (state) => {
                state.isLoading = true;
            })
            .addCase(getProfile.fulfilled, (state, action) => {
                state.isLoading = false;
                state.user = action.payload;
            })
            .addCase(getProfile.rejected, (state, action) => {
                state.isLoading = false;
                state.error = action.payload as string;
            });
    },
});

export const { logout, clearError } = authSlice.actions;
export default authSlice.reducer;
