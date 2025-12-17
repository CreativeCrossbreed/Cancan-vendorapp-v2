import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { supabase, db } from '../config/database';

interface AuthRequest extends Request {
  user?: any;
}

// Admin authentication middleware
export const authenticateToken = async (req: AuthRequest, res: Response, next: NextFunction) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Access token required' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET!) as any;

    // Check token type - must be admin
    if (decoded.type !== 'admin') {
      return res.status(403).json({ error: 'Invalid token type' });
    }

    // Development mode - bypass database for demo
    if (process.env.DEV_MODE === 'true' && decoded.email === 'admin@cancan.com') {
      req.user = {
        id: 'dev-admin-1',
        email: 'admin@cancan.com',
        role: 'super_admin',
        type: 'admin',
        last_login: new Date().toISOString()
      };
      return next();
    }

    // Fetch admin user from database
    const { data: admin, error } = await supabase
      .from('admin_users')
      .select('*')
      .eq('id', decoded.id)
      .eq('is_active', true)
      .single();

    if (error || !admin) {
      return res.status(401).json({ error: 'Invalid token or user not found' });
    }

    req.user = {
      ...admin,
      type: 'admin'
    };
    next();
  } catch (error) {
    return res.status(403).json({ error: 'Invalid or expired token' });
  }
};

// Vendor authentication middleware (for mobile app)
export const authenticateVendorToken = async (req: AuthRequest, res: Response, next: NextFunction) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Access token required' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET!) as any;

    // Check token type - must be vendor
    if (decoded.type !== 'vendor') {
      return res.status(403).json({ error: 'Invalid token type' });
    }

    // Development mode - bypass database for demo
    if (process.env.DEV_MODE === 'true' && decoded.phone === process.env.DEV_PHONE) {
      req.user = {
        vendorId: 'dev-vendor-123',
        phone: decoded.phone,
        type: 'vendor'
      };
      return next();
    }

    // Fetch vendor from database
    const vendor = await db.getVendorById(decoded.vendorId);
    if (!vendor || !vendor.is_active) {
      return res.status(401).json({ error: 'Vendor not found or inactive' });
    }

    req.user = {
      vendorId: vendor.id,
      phone: vendor.phone,
      businessName: vendor.business_name,
      type: 'vendor'
    };
    next();
  } catch (error) {
    return res.status(403).json({ error: 'Invalid or expired token' });
  }
};

// Flexible authentication - accepts both admin and vendor tokens
export const authenticateAnyToken = async (req: AuthRequest, res: Response, next: NextFunction) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Access token required' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET!) as any;

    if (decoded.type === 'admin') {
      // Admin token
      if (process.env.DEV_MODE === 'true' && decoded.email === 'admin@cancan.com') {
        req.user = {
          id: 'dev-admin-1',
          email: 'admin@cancan.com',
          role: 'super_admin',
          type: 'admin'
        };
        return next();
      }

      const { data: admin, error } = await supabase
        .from('admin_users')
        .select('*')
        .eq('id', decoded.id)
        .eq('is_active', true)
        .single();

      if (error || !admin) {
        return res.status(401).json({ error: 'Invalid admin token' });
      }

      req.user = {
        ...admin,
        type: 'admin'
      };
      next();
    } else if (decoded.type === 'vendor') {
      // Vendor token
      if (process.env.DEV_MODE === 'true' && decoded.phone === process.env.DEV_PHONE) {
        req.user = {
          vendorId: 'dev-vendor-123',
          phone: decoded.phone,
          type: 'vendor'
        };
        return next();
      }

      const vendor = await db.getVendorById(decoded.vendorId);
      if (!vendor || !vendor.is_active) {
        return res.status(401).json({ error: 'Vendor not found or inactive' });
      }

      req.user = {
        vendorId: vendor.id,
        phone: vendor.phone,
        businessName: vendor.business_name,
        type: 'vendor'
      };
      next();
    } else {
      return res.status(403).json({ error: 'Unknown token type' });
    }
  } catch (error) {
    return res.status(403).json({ error: 'Invalid or expired token' });
  }
};

export const requireRole = (roles: string[]) => {
  return (req: AuthRequest, res: Response, next: NextFunction) => {
    if (!req.user) {
      return res.status(401).json({ error: 'Authentication required' });
    }

    if (req.user.type !== 'admin') {
      return res.status(403).json({ error: 'Admin access required' });
    }

    if (!roles.includes(req.user.role)) {
      return res.status(403).json({ error: 'Insufficient permissions' });
    }

    next();
  };
};

// Check if user is admin
export const requireAdmin = (req: AuthRequest, res: Response, next: NextFunction) => {
  if (!req.user || req.user.type !== 'admin') {
    return res.status(403).json({ error: 'Admin access required' });
  }
  next();
};

// Check if user is vendor
export const requireVendor = (req: AuthRequest, res: Response, next: NextFunction) => {
  if (!req.user || req.user.type !== 'vendor') {
    return res.status(403).json({ error: 'Vendor access required' });
  }
  next();
};