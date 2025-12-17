/**
 * CAN CAN ADMIN DASHBOARD SERVER
 * Unified API Server using Supabase as single source of truth
 * Replaces custom backend with Supabase integration
 */

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const crypto = require('crypto');
const morgan = require('morgan');
const path = require('path');
require('dotenv').config();

// Import our Supabase services
const { AdminAuth, VendorManager, LocationService, RealtimeService } = require('./api/supabase-admin');

const app = express();
const PORT = process.env.PORT || 3001;

// Security middleware
app.use(helmet({
  crossOriginResourcePolicy: { policy: "cross-origin" }
}));

app.use(cors({
  origin: process.env.FRONTEND_URL || 'http://localhost:3000',
  credentials: true,
}));

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Logging
app.use(morgan('combined'));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later.',
});
app.use('/api/', limiter);

// Serve static files for the frontend
app.use(express.static(path.join(__dirname, 'frontend/build')));

// Authentication middleware
const authenticateAdmin = async (req, res, next) => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');

    if (!token) {
      return res.status(401).json({
        success: false,
        error: 'Authentication required'
      });
    }

    const result = await AdminAuth.verifySession(token);

    if (!result.success) {
      return res.status(401).json({
        success: false,
        error: result.error
      });
    }

    req.admin = result.admin;
    next();
  } catch (error) {
    console.error('Authentication error:', error);
    return res.status(401).json({
      success: false,
      error: 'Authentication failed'
    });
  }
};

// ============================================
// AUTHENTICATION ROUTES
// ============================================

// Admin login
app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        error: 'Email and password are required',
      });
    }

    const result = await AdminAuth.login(email, password);

    if (result.success) {
      res.json(result);
    } else {
      res.status(401).json(result);
    }
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
    });
  }
});

// Admin logout
app.post('/api/auth/logout', authenticateAdmin, async (req, res) => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');
    const result = await AdminAuth.logout(token);

    res.json(result);
  } catch (error) {
    console.error('Logout error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
    });
  }
});

// Verify admin session
app.get('/api/auth/verify', authenticateAdmin, (req, res) => {
  res.json({
    success: true,
    admin: req.admin,
  });
});

// ============================================
// VENDOR MANAGEMENT ROUTES
// ============================================

// Create new vendor (admin onboarding)
app.post('/api/vendors', authenticateAdmin, async (req, res) => {
  try {
    const result = await VendorManager.createVendor(req.body, req.admin.id);

    if (result.success) {
      res.json(result);
    } else {
      res.status(400).json(result);
    }
  } catch (error) {
    console.error('Create vendor error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to create vendor',
    });
  }
});

// Get all vendors with pagination and filters
app.get('/api/vendors', authenticateAdmin, async (req, res) => {
  try {
    const options = {
      page: parseInt(req.query.page) || 1,
      limit: parseInt(req.query.limit) || 20,
      status: req.query.status,
      verificationStatus: req.query.verificationStatus,
      search: req.query.search,
      sortBy: req.query.sortBy || 'created_at',
      sortOrder: req.query.sortOrder || 'desc',
    };

    const result = await VendorManager.getVendors(options);

    if (result.success) {
      res.json(result);
    } else {
      res.status(400).json(result);
    }
  } catch (error) {
    console.error('Get vendors error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch vendors',
    });
  }
});

// Get vendor by ID
app.get('/api/vendors/:id', authenticateAdmin, async (req, res) => {
  try {
    const { id } = req.params;
    const result = await VendorManager.getVendorById(id);

    if (result.success) {
      res.json(result);
    } else {
      res.status(404).json(result);
    }
  } catch (error) {
    console.error('Get vendor error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch vendor',
    });
  }
});

// Update vendor verification status
app.put('/api/vendors/:id/verification', authenticateAdmin, async (req, res) => {
  try {
    const { id } = req.params;
    const { status, notes } = req.body;

    if (!status) {
      return res.status(400).json({
        success: false,
        error: 'Status is required',
      });
    }

    const result = await VendorManager.updateVerificationStatus(
      id,
      status,
      notes,
      req.admin.id
    );

    if (result.success) {
      res.json(result);
    } else {
      res.status(400).json(result);
    }
  } catch (error) {
    console.error('Update verification error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to update verification status',
    });
  }
});

// Toggle vendor active status
app.put('/api/vendors/:id/status', authenticateAdmin, async (req, res) => {
  try {
    const { id } = req.params;
    const { isActive, reason } = req.body;

    if (typeof isActive !== 'boolean') {
      return res.status(400).json({
        success: false,
        error: 'isActive must be a boolean',
      });
    }

    const result = await VendorManager.toggleVendorStatus(id, isActive, reason);

    if (result.success) {
      res.json(result);
    } else {
      res.status(400).json(result);
    }
  } catch (error) {
    console.error('Toggle vendor status error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to update vendor status',
    });
  }
});

// Get vendor statistics
app.get('/api/vendors/statistics', authenticateAdmin, async (req, res) => {
  try {
    const result = await VendorManager.getVendorStatistics();

    if (result.success) {
      res.json(result);
    } else {
      res.status(400).json(result);
    }
  } catch (error) {
    console.error('Get vendor statistics error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch vendor statistics',
    });
  }
});

// ============================================
// LOCATION SERVICES ROUTES
// ============================================

// Update vendor location
app.post('/api/vendors/:id/location', async (req, res) => {
  try {
    const { id } = req.params;
    const locationData = req.body;

    const result = await LocationService.updateVendorLocation(id, locationData);

    if (result.success) {
      res.json(result);
    } else {
      res.status(400).json(result);
    }
  } catch (error) {
    console.error('Update vendor location error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to update vendor location',
    });
  }
});

// Get vendor location
app.get('/api/vendors/:id/location', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await LocationService.getVendorLocation(id);

    if (result.success) {
      res.json(result);
    } else {
      res.status(404).json(result);
    }
  } catch (error) {
    console.error('Get vendor location error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get vendor location',
    });
  }
});

// Find nearby vendors
app.get('/api/vendors/nearby', async (req, res) => {
  try {
    const {
      latitude,
      longitude,
      radiusKm = 10,
      limit = 10
    } = req.query;

    if (!latitude || !longitude) {
      return res.status(400).json({
        success: false,
        error: 'Latitude and longitude are required',
      });
    }

    const result = await LocationService.findNearbyVendors(
      parseFloat(latitude),
      parseFloat(longitude),
      parseInt(radiusKm),
      parseInt(limit)
    );

    if (result.success) {
      res.json(result);
    } else {
      res.status(400).json(result);
    }
  } catch (error) {
    console.error('Find nearby vendors error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to find nearby vendors',
    });
  }
});

// ============================================
// REAL-TIME WEBHOOKS
// ============================================

// Webhook for real-time updates from Supabase
app.post('/api/webhooks/supabase', (req, res) => {
  try {
    const { type, table, record, old_record } = req.body;

    console.log(`Supabase webhook: ${type} on ${table}`);

    // Handle different webhook events
    switch (table) {
      case 'orders':
        // Broadcast order updates to connected clients
        // This would integrate with WebSocket or Server-Sent Events
        break;
      case 'vendors':
        // Broadcast vendor updates
        break;
      case 'notifications':
        // Broadcast new notifications
        break;
    }

    res.json({ success: true });
  } catch (error) {
    console.error('Webhook error:', error);
    res.status(500).json({ success: false, error: 'Webhook processing failed' });
  }
});

// ============================================
// HEALTH CHECK
// ============================================

app.get('/api/health', (req, res) => {
  res.json({
    success: true,
    message: 'Can Can Admin API is running',
    timestamp: new Date().toISOString(),
    version: '1.0.0',
  });
});

// ============================================
// FRONTEND SERVING
// ============================================

// Serve the React app for any non-API routes
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'frontend/build', 'index.html'));
});

// ============================================
// ERROR HANDLING
// ============================================

// Global error handler
app.use((error, req, res, next) => {
  console.error('Global error handler:', error);

  // Don't send error details in production
  const isDevelopment = process.env.NODE_ENV === 'development';

  res.status(error.status || 500).json({
    success: false,
    error: isDevelopment ? error.message : 'Internal server error',
    ...(isDevelopment && { stack: error.stack }),
  });
});

// ============================================
// SERVER STARTUP
// ============================================

const server = app.listen(PORT, () => {
  console.log(`🚀 Can Can Admin Server running on port ${PORT}`);
  console.log(`📊 Admin Dashboard: http://localhost:${PORT}`);
  console.log(`🔗 API Endpoint: http://localhost:${PORT}/api`);
  console.log(`🏥 Health Check: http://localhost:${PORT}/api/health`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully');
  server.close(() => {
    console.log('Process terminated');
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  console.log('SIGINT received, shutting down gracefully');
  server.close(() => {
    console.log('Process terminated');
    process.exit(0);
  });
});

module.exports = app;