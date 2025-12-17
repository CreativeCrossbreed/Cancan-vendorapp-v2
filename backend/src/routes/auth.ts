import express from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { supabase, db } from '../config/database';
import { authenticateToken, authenticateVendorToken } from '../middleware/auth';

const router = express.Router();

// ============================================
// DASHBOARD AUTHENTICATION
// ============================================

// Admin login endpoint for dashboard
router.post('/admin/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password required' });
    }

    // Development mode - bypass database for demo
    if (process.env.DEV_MODE === 'true' && email === 'admin@cancan.com' && password === 'admin123') {
      // Generate JWT token
      const token = jwt.sign(
        { email: 'admin@cancan.com', role: 'super_admin', type: 'admin' },
        process.env.JWT_SECRET as string,
        { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
      );

      return res.json({
        token,
        user: {
          id: 'dev-admin-1',
          email: 'admin@cancan.com',
          role: 'super_admin',
          last_login: new Date().toISOString()
        }
      });
    }

    // Fetch admin user from database
    const { data: admin, error } = await supabase
      .from('admin_users')
      .select('*')
      .eq('email', email)
      .eq('is_active', true)
      .single();

    if (error || !admin) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Verify password
    const isValidPassword = await bcrypt.compare(password, admin.password);
    if (!isValidPassword) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Update last login
    await supabase
      .from('admin_users')
      .update({ last_login: new Date().toISOString() })
      .eq('id', admin.id);

    // Generate JWT token
    const token = jwt.sign(
      {
        id: admin.id,
        email: admin.email,
        role: admin.role,
        type: 'admin'
      },
      process.env.JWT_SECRET as string,
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );

    res.json({
      token,
      user: {
        id: admin.id,
        email: admin.email,
        role: admin.role,
        last_login: admin.last_login,
      },
    });
  } catch (error) {
    console.error('Admin login error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get current admin user
router.get('/admin/me', authenticateToken, async (req: any, res) => {
  if (req.user.type !== 'admin') {
    return res.status(403).json({ error: 'Access denied' });
  }

  res.json({
    user: {
      id: req.user.id,
      email: req.user.email,
      role: req.user.role,
      last_login: req.user.last_login,
    },
  });
});

// ============================================
// MOBILE APP AUTHENTICATION
// ============================================

// Send OTP to phone number (for mobile app)
router.post('/send-otp', async (req, res) => {
  try {
    const { phone } = req.body;

    if (!phone) {
      return res.status(400).json({ error: 'Phone number required' });
    }

    // Development mode - auto-accept development phone
    if (process.env.DEV_MODE === 'true' && phone === process.env.DEV_PHONE) {
      return res.json({
        success: true,
        message: 'OTP sent successfully (development mode)',
        otp: process.env.TEST_OTP, // Return OTP in dev mode
        devMode: true
      });
    }

    // Check if vendor exists with this phone
    const vendor = await db.getVendorByPhone(phone);
    if (!vendor && phone !== process.env.DEV_PHONE) {
      // For new vendors, allow registration but note it
      console.log(`New vendor registration attempt for phone: ${phone}`);
    }

    // In production, integrate with SMS gateway
    // For now, generate a 6-digit OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();

    // Store OTP with expiration (in production, use Redis or database)
    // For now, just log it
    console.log(`OTP for ${phone}: ${otp}`);

    // TODO: Integrate with SMS gateway like Twilio
    // await smsService.sendOTP(phone, otp);

    res.json({
      success: true,
      message: 'OTP sent successfully',
      devMode: false
    });

  } catch (error) {
    console.error('Send OTP error:', error);
    res.status(500).json({ error: 'Failed to send OTP' });
  }
});

// Verify OTP and login/register vendor
router.post('/verify-otp', async (req, res) => {
  try {
    const { phone, otp } = req.body;

    if (!phone || !otp) {
      return res.status(400).json({ error: 'Phone number and OTP required' });
    }

    // Development mode - accept test OTP
    if (process.env.DEV_MODE === 'true') {
      if (phone === process.env.DEV_PHONE && otp === process.env.TEST_OTP) {
        const vendor = await db.getVendorByPhone(phone);

        if (!vendor) {
          // Create new vendor for development
          const newVendor = await db.createVendor({
            business_name: 'Test Vendor',
            owner_name: 'Test Owner',
            phone: phone,
            address: 'Test Address',
            is_active: true,
            is_verified: true,
            created_at: new Date().toISOString()
          });

          const token = jwt.sign(
            {
              vendorId: newVendor.id,
              phone: newVendor.phone,
              type: 'vendor'
            },
            process.env.JWT_SECRET as string,
            { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
          );

          return res.json({
            success: true,
            token,
            vendor: newVendor,
            isNewVendor: true
          });
        }

        const token = jwt.sign(
          {
            vendorId: vendor.id,
            phone: vendor.phone,
            type: 'vendor'
          },
          process.env.JWT_SECRET as string,
          { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
        );

        return res.json({
          success: true,
          token,
          vendor,
          isNewVendor: false
        });
      }
    }

    // Production OTP verification
    // TODO: Verify OTP from Redis/database
    const isValidOTP = otp === process.env.TEST_OTP; // Simplified for now

    if (!isValidOTP) {
      return res.status(401).json({ error: 'Invalid OTP' });
    }

    // Check if vendor exists
    let vendor = await db.getVendorByPhone(phone);

    if (!vendor) {
      return res.status(404).json({
        error: 'Vendor not found',
        needsRegistration: true
      });
    }

    // Generate JWT token
    const token = jwt.sign(
      {
        vendorId: vendor.id,
        phone: vendor.phone,
        type: 'vendor'
      },
      process.env.JWT_SECRET as string,
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );

    res.json({
      success: true,
      token,
      vendor,
      isNewVendor: false
    });

  } catch (error) {
    console.error('Verify OTP error:', error);
    res.status(500).json({ error: 'Failed to verify OTP' });
  }
});

// Register new vendor (after OTP verification)
router.post('/register', async (req, res) => {
  try {
    const { phone, businessName, ownerName, address, email } = req.body;

    if (!phone || !businessName || !ownerName || !address) {
      return res.status(400).json({ error: 'Required fields missing' });
    }

    // Check if vendor already exists
    const existingVendor = await db.getVendorByPhone(phone);
    if (existingVendor) {
      return res.status(409).json({ error: 'Vendor already exists with this phone number' });
    }

    // Create new vendor
    const newVendor = await db.createVendor({
      business_name: businessName,
      owner_name: ownerName,
      phone: phone,
      email: email || null,
      address: address,
      is_active: true,
      is_verified: false, // Needs verification
      rating: 0.0,
      total_orders: 0,
      completed_orders: 0,
      cancelled_orders: 0,
      commission_rate: 10.0,
      created_at: new Date().toISOString()
    });

    // Generate JWT token
    const token = jwt.sign(
      {
        vendorId: newVendor.id,
        phone: newVendor.phone,
        type: 'vendor'
      },
      process.env.JWT_SECRET as string,
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );

    res.status(201).json({
      success: true,
      token,
      vendor: newVendor,
      isNewVendor: true
    });

  } catch (error) {
    console.error('Vendor registration error:', error);
    res.status(500).json({ error: 'Failed to register vendor' });
  }
});

// Get current vendor (mobile app)
router.get('/vendor/me', authenticateVendorToken, async (req: any, res) => {
  try {
    if (req.user.type !== 'vendor') {
      return res.status(403).json({ error: 'Access denied' });
    }

    const vendor = await db.getVendorById(req.user.vendorId);
    if (!vendor) {
      return res.status(404).json({ error: 'Vendor not found' });
    }

    res.json({
      success: true,
      vendor
    });

  } catch (error) {
    console.error('Get vendor error:', error);
    res.status(500).json({ error: 'Failed to get vendor details' });
  }
});

// ============================================
// COMMON ENDPOINTS
// ============================================

// Get current user (backward compatibility)
router.get('/me', authenticateToken, async (req: any, res) => {
  res.json({
    user: {
      id: req.user.id,
      email: req.user.email,
      role: req.user.role,
      type: req.user.type,
      last_login: req.user.last_login,
    },
  });
});

// Change password (admin only)
router.put('/change-password', authenticateToken, async (req: any, res) => {
  try {
    if (req.user.type !== 'admin') {
      return res.status(403).json({ error: 'Access denied' });
    }

    const { currentPassword, newPassword } = req.body;

    if (!currentPassword || !newPassword) {
      return res.status(400).json({ error: 'Current and new passwords required' });
    }

    // Fetch admin user with password
    const { data: admin, error } = await supabase
      .from('admin_users')
      .select('password')
      .eq('id', req.user.id)
      .single();

    if (error || !admin) {
      return res.status(404).json({ error: 'Admin user not found' });
    }

    // Verify current password
    const isValidPassword = await bcrypt.compare(currentPassword, admin.password);
    if (!isValidPassword) {
      return res.status(401).json({ error: 'Current password is incorrect' });
    }

    // Hash new password
    const hashedNewPassword = await bcrypt.hash(newPassword, 12);

    // Update password
    const { error: updateError } = await supabase
      .from('admin_users')
      .update({ password: hashedNewPassword })
      .eq('id', req.user.id);

    if (updateError) {
      return res.status(500).json({ error: 'Failed to update password' });
    }

    res.json({ message: 'Password updated successfully' });
  } catch (error) {
    console.error('Change password error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Logout endpoint
router.post('/logout', authenticateToken, async (req, res) => {
  // In a stateful implementation, you would blacklist the token
  // For JWT, the client should simply discard the token
  res.json({ message: 'Logout successful' });
});

// Vendor logout
router.post('/vendor/logout', authenticateVendorToken, async (req, res) => {
  res.json({ message: 'Vendor logout successful' });
});

export default router;