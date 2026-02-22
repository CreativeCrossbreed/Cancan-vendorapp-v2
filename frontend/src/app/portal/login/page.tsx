'use client';

import React, { useState, FormEvent } from 'react';
import { useRouter } from 'next/navigation';
import Image from 'next/image';
import {
    Box,
    Paper,
    TextField,
    Button,
    Typography,
    Alert,
    CircularProgress,
    InputAdornment,
    IconButton,
} from '@mui/material';
import { Visibility, VisibilityOff, Email, Lock } from '@mui/icons-material';
import { useDispatch, useSelector } from 'react-redux';
import { login, clearError } from '@/store/authSlice';
import type { AppDispatch, RootState } from '@/store';

export default function LoginPage() {
    const router = useRouter();
    const dispatch = useDispatch<AppDispatch>();
    const { isLoading, error } = useSelector((state: RootState) => state.auth);

    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [showPassword, setShowPassword] = useState(false);

    const handleSubmit = async (e: FormEvent) => {
        e.preventDefault();
        dispatch(clearError());
        const result = await dispatch(login({ email, password }));
        if (login.fulfilled.match(result)) {
            router.push('/portal/dashboard');
        }
    };

    return (
        <Box
            sx={{
                minHeight: '100vh',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                background: 'linear-gradient(135deg, #FAF8F0 0%, #E3F0B6 50%, #6DD3DC22 100%)',
                p: 2,
            }}
        >
            <Paper
                elevation={0}
                sx={{
                    p: { xs: 3, sm: 5 },
                    maxWidth: 440,
                    width: '100%',
                    borderRadius: 4,
                    border: '1px solid rgba(15,23,42,0.06)',
                    boxShadow: '0 20px 60px rgba(15,23,42,0.08)',
                }}
            >
                <Box sx={{ textAlign: 'center', mb: 4 }}>
                    <Image
                        src="/cancan/cancan-logo.png"
                        alt="Can Can"
                        width={140}
                        height={52}
                        priority
                        style={{ display: 'block', margin: '0 auto 16px' }}
                    />
                    <Typography variant="h5" sx={{ fontWeight: 800, letterSpacing: '-0.02em' }}>
                        Admin Portal
                    </Typography>
                    <Typography color="text.secondary" sx={{ mt: 0.5, fontSize: '0.9rem' }}>
                        Sign in to manage your platform
                    </Typography>
                </Box>

                {error && (
                    <Alert severity="error" sx={{ mb: 2, borderRadius: 2 }}>
                        {error}
                    </Alert>
                )}

                <form onSubmit={handleSubmit}>
                    <TextField
                        fullWidth
                        label="Email"
                        type="email"
                        value={email}
                        onChange={(e) => setEmail(e.target.value)}
                        required
                        sx={{ mb: 2 }}
                        slotProps={{
                            input: {
                                startAdornment: (
                                    <InputAdornment position="start">
                                        <Email sx={{ color: 'text.secondary', fontSize: 20 }} />
                                    </InputAdornment>
                                ),
                            },
                        }}
                    />
                    <TextField
                        fullWidth
                        label="Password"
                        type={showPassword ? 'text' : 'password'}
                        value={password}
                        onChange={(e) => setPassword(e.target.value)}
                        required
                        sx={{ mb: 3 }}
                        slotProps={{
                            input: {
                                startAdornment: (
                                    <InputAdornment position="start">
                                        <Lock sx={{ color: 'text.secondary', fontSize: 20 }} />
                                    </InputAdornment>
                                ),
                                endAdornment: (
                                    <InputAdornment position="end">
                                        <IconButton onClick={() => setShowPassword(!showPassword)} edge="end" size="small">
                                            {showPassword ? <VisibilityOff fontSize="small" /> : <Visibility fontSize="small" />}
                                        </IconButton>
                                    </InputAdornment>
                                ),
                            },
                        }}
                    />
                    <Button
                        type="submit"
                        fullWidth
                        variant="contained"
                        size="large"
                        disabled={isLoading}
                        sx={{
                            py: 1.5,
                            borderRadius: 3,
                            fontWeight: 700,
                            fontSize: '1rem',
                            textTransform: 'none',
                            background: 'linear-gradient(135deg, #6DD3DC, #4BBFC9)',
                            boxShadow: '0 4px 18px rgba(109,211,220,0.3)',
                            '&:hover': {
                                background: 'linear-gradient(135deg, #4BBFC9, #3AA5AE)',
                                boxShadow: '0 6px 24px rgba(109,211,220,0.4)',
                            },
                        }}
                    >
                        {isLoading ? <CircularProgress size={24} color="inherit" /> : 'Sign In'}
                    </Button>
                </form>

                <Typography
                    color="text.secondary"
                    sx={{ mt: 3, textAlign: 'center', fontSize: '0.78rem' }}
                >
                    Access restricted to authorized administrators only
                </Typography>
            </Paper>
        </Box>
    );
}

