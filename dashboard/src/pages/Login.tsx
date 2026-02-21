// @ts-nocheck
import React, { useState } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { useNavigate } from 'react-router-dom';
import {
  Container,
  Paper,
  Box,
  Typography,
  TextField,
  Button,
  Alert,
  CircularProgress,
  InputAdornment,
  IconButton,
} from '@mui/material';
import {
  Visibility,
  VisibilityOff,
  WhatsApp,
} from '@mui/icons-material';
import { login } from '../store/authSlice';
import { RootState, AppDispatch } from '../store';

const Login: React.FC = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const dispatch = useDispatch<AppDispatch>();
  const navigate = useNavigate();
  const { isLoading, error } = useSelector((state: RootState) => state.auth);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const result = await dispatch(login({ email, password }));
    if (login.fulfilled.match(result)) {
      navigate('/dashboard');
    }
  };

  const togglePasswordVisibility = () => {
    setShowPassword(!showPassword);
  };

  return (
    <Box
      sx={{
        minHeight: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        bgcolor: '#F5F5F5',
        backgroundImage: 'linear-gradient(135deg, #F5F5F5 0%, #E8EAED 100%)',
      }}
    >
      <Container component="main" maxWidth="sm">
        <Box
          sx={{
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
          }}
        >
          {/* Logo and Brand */}
          <Box
            sx={{
              mb: 4,
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
            }}
          >
            <Box
              sx={{
                width: 64,
                height: 64,
                borderRadius: 3,
                bgcolor: 'primary.main',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                mb: 2,
                boxShadow: '0 4px 12px rgba(26, 115, 232, 0.3)',
              }}
            >
              <WhatsApp sx={{ color: 'white', fontSize: 36 }} />
            </Box>
            <Typography
              component="h1"
              variant="h4"
              sx={{ fontWeight: 700, color: '#1A73E8', mb: 0.5 }}
            >
              Can Can
            </Typography>
            <Typography
              variant="body1"
              sx={{ color: 'text.secondary' }}
            >
              Water Can Delivery Management
            </Typography>
          </Box>

          {/* Login Card */}
          <Paper
            elevation={0}
            sx={{
              width: '100%',
              p: 4,
              borderRadius: 3,
              boxShadow: '0 4px 24px rgba(0,0,0,0.08)',
            }}
          >
            <Typography
              component="h2"
              variant="h5"
              align="center"
              sx={{ fontWeight: 600, mb: 0.5, color: '#202124' }}
            >
              Welcome Back
            </Typography>
            <Typography
              variant="body2"
              align="center"
              sx={{ color: 'text.secondary', mb: 3 }}
            >
              Sign in to access your admin dashboard
            </Typography>

            {error && (
              <Alert
                severity="error"
                sx={{
                  mb: 3,
                  borderRadius: 2,
                  '& .MuiAlert-icon': {
                    alignItems: 'center',
                  },
                }}
              >
                {error}
              </Alert>
            )}

            <Box component="form" onSubmit={handleSubmit}>
              <TextField
                margin="normal"
                required
                fullWidth
                id="email"
                label="Email Address"
                name="email"
                autoComplete="email"
                autoFocus
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                disabled={isLoading}
                placeholder="admin@cancan.com"
                sx={{
                  '& .MuiOutlinedInput-root': {
                    borderRadius: 2,
                  },
                }}
              />
              <TextField
                margin="normal"
                required
                fullWidth
                name="password"
                label="Password"
                type={showPassword ? 'text' : 'password'}
                id="password"
                autoComplete="current-password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                disabled={isLoading}
                placeholder="Enter your password"
                sx={{
                  '& .MuiOutlinedInput-root': {
                    borderRadius: 2,
                  },
                }}
                InputProps={{
                  endAdornment: (
                    <InputAdornment position="end">
                      <IconButton
                        aria-label="toggle password visibility"
                        onClick={togglePasswordVisibility}
                        edge="end"
                        sx={{ color: 'text.secondary' }}
                      >
                        {showPassword ? <VisibilityOff /> : <Visibility />}
                      </IconButton>
                    </InputAdornment>
                  ),
                }}
              />
              <Button
                type="submit"
                fullWidth
                variant="contained"
                sx={{
                  mt: 3,
                  mb: 2,
                  py: 1.5,
                  borderRadius: 2,
                  fontWeight: 600,
                  fontSize: '1rem',
                }}
                disabled={isLoading}
              >
                {isLoading ? (
                  <CircularProgress size={24} color="inherit" />
                ) : (
                  'Sign In'
                )}
              </Button>

              <Box
                sx={{
                  mt: 3,
                  p: 2,
                  bgcolor: '#F8F9FA',
                  borderRadius: 2,
                  border: '1px solid #E8EAED',
                }}
              >
                <Typography
                  variant="caption"
                  display="block"
                  align="center"
                  sx={{ color: 'text.secondary', mb: 0.5 }}
                >
                  <strong>Demo Credentials:</strong>
                </Typography>
                <Typography
                  variant="caption"
                  display="block"
                  align="center"
                  sx={{ color: 'text.secondary' }}
                >
                  Email: admin@cancan.com &nbsp;|&nbsp; Password: admin123
                </Typography>
              </Box>
            </Box>
          </Paper>

          {/* Footer */}
          <Box sx={{ mt: 4 }}>
            <Typography
              variant="caption"
              align="center"
              sx={{ color: 'text.secondary' }}
            >
              © 2024 Can Can Water Delivery. All rights reserved.
            </Typography>
          </Box>
        </Box>
      </Container>
    </Box>
  );
};

export default Login;
