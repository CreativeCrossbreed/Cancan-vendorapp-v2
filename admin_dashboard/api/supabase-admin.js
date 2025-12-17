/**
 * SUPABASE ADMIN API
 * Single source of truth for Admin Dashboard + Mobile App Integration
 * Uses Supabase as the database and eliminates custom backend
 */

const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

// Supabase Configuration
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_KEY;

if (!supabaseUrl || !supabaseServiceKey) {
  throw new Error('SUPABASE_URL and SUPABASE_SERVICE_KEY must be set in environment variables');
}

// Create Supabase client with admin privileges
const supabase = createClient(supabaseUrl, supabaseServiceKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false,
  },
});

// Admin authentication functions
class AdminAuth {
  /**
   * Authenticate admin user
   */
  static async login(email, password) {
    try {
      // Check against admin_users table
      const { data: admin, error } = await supabase
        .from('admin_users')
        .select('*')
        .eq('email', email)
        .eq('is_active', true)
        .single();

      if (error || !admin) {
        throw new Error('Invalid admin credentials or account inactive');
      }

      // Verify password (using crypto for hash comparison)
      const crypto = require('crypto');
      const isPasswordValid = crypto.compareSync(password, admin.password_hash);

      if (!isPasswordValid) {
        throw new Error('Invalid admin credentials');
      }

      // Create session token
      const token = crypto.randomBytes(32).toString('hex');
      const tokenHash = crypto.createHash('sha256').update(token).digest('hex');

      // Store session
      await supabase.from('admin_sessions').insert({
        admin_user_id: admin.id,
        token_hash,
        expires_at: new Date(Date.now() + 24 * 60 * 60 * 1000), // 24 hours
        ip_address: null, // Will be set in the actual request
        user_agent: null, // Will be set in the actual request
      });

      // Update last login
      await supabase
        .from('admin_users')
        .update({ last_login: new Date().toISOString() })
        .eq('id', admin.id);

      return {
        success: true,
        admin: {
          id: admin.id,
          email: admin.email,
          full_name: admin.full_name,
          role: admin.role,
        },
        token,
      };
    } catch (error) {
      console.error('Admin login error:', error);
      return {
        success: false,
        error: error.message,
      };
    }
  }

  /**
   * Verify admin session
   */
  static async verifySession(token) {
    try {
      const crypto = require('crypto');
      const tokenHash = crypto.createHash('sha256').update(token).digest('hex');

      const { data: session, error } = await supabase
        .from('admin_sessions')
        .select(`
          admin_user_id,
          admin_users(id, email, full_name, role, is_active)
        `)
        .eq('token_hash', tokenHash)
        .eq('is_active', true) // Assuming we add is_active to sessions
        .gt('expires_at', new Date().toISOString())
        .single();

      if (error || !session || !session.admin_users.is_active) {
        throw new Error('Invalid or expired session');
      }

      return {
        success: true,
        admin: session.admin_users,
      };
    } catch (error) {
      console.error('Session verification error:', error);
      return {
        success: false,
        error: error.message,
      };
    }
  }

  /**
   * Logout admin session
   */
  static async logout(token) {
    try {
      const crypto = require('crypto');
      const tokenHash = crypto.createHash('sha256').update(token).digest('hex');

      await supabase
        .from('admin_sessions')
        .update({ expires_at: new Date().toISOString() })
        .eq('token_hash', tokenHash);

      return { success: true };
    } catch (error) {
      console.error('Logout error:', error);
      return { success: false, error: error.message };
    }
  }
}

// Vendor Management Functions
class VendorManager {
  /**
   * Create new vendor (admin onboarding)
   */
  static async createVendor(vendorData, adminId) {
    try {
      // Validate required fields
      const requiredFields = ['business_name', 'owner_name', 'phone', 'address', 'latitude', 'longitude'];
      for (const field of requiredFields) {
        if (!vendorData[field]) {
          throw new Error(`${field} is required`);
        }
      }

      // Check if phone already exists
      const { data: existingVendor } = await supabase
        .from('vendors')
        .select('id')
        .eq('phone', vendorData.phone)
        .single();

      if (existingVendor) {
        throw new Error('Vendor with this phone number already exists');
      }

      // Create vendor record
      const { data: vendor, error } = await supabase
        .from('vendors')
        .insert({
          ...vendorData,
          verification_status: 'pending',
          onboarding_status: 'pending',
          created_by: adminId,
        })
        .select()
        .single();

      if (error) {
        throw new Error(`Failed to create vendor: ${error.message}`);
      }

      // Create vendor wallet
      await supabase
        .from('vendor_wallets')
        .insert({
          vendor_id: vendor.id,
          balance: 0,
          pending_balance: 0,
        });

      // Send welcome notification
      await supabase
        .from('notifications')
        .insert({
          recipient_type: 'vendor',
          recipient_id: vendor.id,
          title: 'Welcome to Can Can!',
          message: `Hi ${vendor.owner_name}, your business "${vendor.business_name}" has been registered. We will verify your details and activate your account soon.`,
          type: 'welcome',
          data: { vendor_id: vendor.id },
        });

      return {
        success: true,
        vendor,
        message: 'Vendor created successfully. Pending verification.',
      };
    } catch (error) {
      console.error('Create vendor error:', error);
      return {
        success: false,
        error: error.message,
      };
    }
  }

  /**
   * Get all vendors with pagination and filters
   */
  static async getVendors(options = {}) {
    try {
      const {
        page = 1,
        limit = 20,
        status,
        verificationStatus,
        search,
        sortBy = 'created_at',
        sortOrder = 'desc',
      } = options;

      let query = supabase
        .from('vendors')
        .select(`
          *,
          vendor_wallets(balance, pending_balance),
          admin_users!created_by(full_name)
        `, { count: 'exact' });

      // Apply filters
      if (status !== undefined) {
        query = query.eq('is_active', status === 'active');
      }

      if (verificationStatus) {
        query = query.eq('verification_status', verificationStatus);
      }

      if (search) {
        query = query.or(`business_name.ilike.%${search}%,owner_name.ilike.%${search}%,phone.ilike.%${search}%`);
      }

      // Apply sorting
      query = query.order(sortBy, { ascending: sortOrder === 'asc' });

      // Apply pagination
      const offset = (page - 1) * limit;
      query = query.range(offset, offset + limit - 1);

      const { data: vendors, error, count } = await query;

      if (error) {
        throw new Error(`Failed to fetch vendors: ${error.message}`);
      }

      return {
        success: true,
        vendors,
        pagination: {
          page,
          limit,
          total: count,
          totalPages: Math.ceil(count / limit),
        },
      };
    } catch (error) {
      console.error('Get vendors error:', error);
      return {
        success: false,
        error: error.message,
      };
    }
  }

  /**
   * Get vendor by ID
   */
  static async getVendorById(vendorId) {
    try {
      const { data: vendor, error } = await supabase
        .from('vendors')
        .select(`
          *,
          vendor_wallets(balance, pending_balance),
          vendor_products(id, product_id, products!inner(name, category), selling_price, current_stock),
          admin_users!created_by(full_name)
        `)
        .eq('id', vendorId)
        .single();

      if (error) {
        throw new Error(`Failed to fetch vendor: ${error.message}`);
      }

      // Get recent orders
      const { data: recentOrders } = await supabase
        .from('orders')
        .select('order_number, status, total_amount, created_at, customer_id, customers(name)')
        .eq('vendor_id', vendorId)
        .order('created_at', { ascending: false })
        .limit(10);

      // Get performance metrics
      const { data: metrics } = await supabase
        .from('orders')
        .select('status, total_amount')
        .eq('vendor_id', vendorId)
        .gte('created_at', new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString()); // Last 30 days

      return {
        success: true,
        vendor: {
          ...vendor,
          recentOrders,
          metrics: {
            totalOrders: metrics?.length || 0,
            completedOrders: metrics?.filter(o => o.status === 'delivered').length || 0,
            totalRevenue: metrics?.reduce((sum, o) => sum + (o.status === 'delivered' ? parseFloat(o.total_amount) : 0), 0) || 0,
          },
        },
      };
    } catch (error) {
      console.error('Get vendor by ID error:', error);
      return {
        success: false,
        error: error.message,
      };
    }
  }

  /**
   * Update vendor verification status
   */
  static async updateVerificationStatus(vendorId, status, notes, adminId) {
    try {
      const { data: vendor, error } = await supabase
        .from('vendors')
        .update({
          verification_status: status,
          verification_notes: notes,
          is_verified: status === 'verified',
          onboarding_status: status === 'verified' ? 'completed' : 'rejected',
          updated_at: new Date().toISOString(),
        })
        .eq('id', vendorId)
        .select()
        .single();

      if (error) {
        throw new Error(`Failed to update vendor status: ${error.message}`);
      }

      // Create Supabase auth user for verified vendors
      if (status === 'verified') {
        try {
          // Create user in Supabase Auth
          const { data: authUser, error: authError } = await supabase.auth.admin.createUser({
            email: vendor.email || `${vendor.phone}@cancan.local`,
            phone: vendor.phone,
            password: 'changeme123', // Temporary password, vendor will change it
            email_confirm: true,
            phone_confirm: true,
            user_metadata: {
              role: 'vendor',
              vendor_id: vendorId,
              business_name: vendor.business_name,
            },
          });

          if (authError) {
            console.error('Error creating auth user:', authError);
            // Don't throw error here, vendor is still verified in database
          } else {
            // Link auth user to vendor
            await supabase
              .from('vendors')
              .update({ user_id: authUser.user.id })
              .eq('id', vendorId);
          }
        } catch (authError) {
          console.error('Error creating auth user:', authError);
        }
      }

      // Send notification to vendor
      await supabase
        .from('notifications')
        .insert({
          recipient_type: 'vendor',
          recipient_id: vendorId,
          title: `Verification ${status === 'verified' ? 'Approved' : status === 'rejected' ? 'Rejected' : 'Updated'}`,
          message: status === 'verified'
            ? 'Congratulations! Your vendor account has been verified. You can now start accepting orders.'
            : status === 'rejected'
            ? `Your vendor account verification was rejected. Reason: ${notes}`
            : `Your verification status has been updated to: ${status}`,
          type: 'verification',
          data: { status, notes },
        });

      return {
        success: true,
        vendor,
        message: `Vendor verification status updated to ${status}`,
      };
    } catch (error) {
      console.error('Update verification status error:', error);
      return {
        success: false,
        error: error.message,
      };
    }
  }

  /**
   * Toggle vendor active status
   */
  static async toggleVendorStatus(vendorId, isActive, reason) {
    try {
      const { data: vendor, error } = await supabase
        .from('vendors')
        .update({
          is_active: isActive,
          updated_at: new Date().toISOString(),
        })
        .eq('id', vendorId)
        .select()
        .single();

      if (error) {
        throw new Error(`Failed to update vendor status: ${error.message}`);
      }

      // Send notification
      await supabase
        .from('notifications')
        .insert({
          recipient_type: 'vendor',
          recipient_id: vendorId,
          title: `Account ${isActive ? 'Activated' : 'Deactivated'}`,
          message: `Your vendor account has been ${isActive ? 'activated' : 'deactivated'}. Reason: ${reason || 'Admin action'}`,
          type: 'account_status',
          data: { is_active: isActive, reason },
        });

      return {
        success: true,
        vendor,
        message: `Vendor ${isActive ? 'activated' : 'deactivated'} successfully`,
      };
    } catch (error) {
      console.error('Toggle vendor status error:', error);
      return {
        success: false,
        error: error.message,
      };
    }
  }

  /**
   * Get vendor statistics
   */
  static async getVendorStatistics() {
    try {
      const { data: stats, error } = await supabase
        .from('vendors')
        .select('verification_status, is_active, created_at');

      if (error) {
        throw new Error(`Failed to fetch vendor statistics: ${error.message}`);
      }

      const totalVendors = stats.length;
      const activeVendors = stats.filter(v => v.is_active).length;
      const verifiedVendors = stats.filter(v => v.verification_status === 'verified').length;
      const pendingVendors = stats.filter(v => v.verification_status === 'pending').length;

      // Get new vendors in last 30 days
      const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
      const newVendors = stats.filter(v => new Date(v.created_at) > thirtyDaysAgo).length;

      // Get revenue from completed orders
      const { data: revenueData } = await supabase
        .from('orders')
        .select('total_amount, vendor_id')
        .eq('status', 'delivered');

      const totalRevenue = revenueData?.reduce((sum, order) => sum + parseFloat(order.total_amount), 0) || 0;

      return {
        success: true,
        statistics: {
          totalVendors,
          activeVendors,
          verifiedVendors,
          pendingVendors,
          newVendors,
          totalRevenue,
          averageRevenuePerVendor: totalVendors > 0 ? totalRevenue / totalVendors : 0,
        },
      };
    } catch (error) {
      console.error('Get vendor statistics error:', error);
      return {
        success: false,
        error: error.message,
      };
    }
  }
}

// Location Services for vendor geofencing
class LocationService {
  /**
   * Update vendor location
   */
  static async updateVendorLocation(vendorId, locationData) {
    try {
      const { data, error } = await supabase
        .from('vendor_locations')
        .insert({
          vendor_id: vendorId,
          latitude: locationData.latitude,
          longitude: locationData.longitude,
          accuracy: locationData.accuracy,
          altitude: locationData.altitude,
          speed: locationData.speed,
          heading: locationData.heading,
          location_method: locationData.method || 'gps',
          battery_level: locationData.batteryLevel,
          is_charging: locationData.isCharging || false,
          created_at: new Date().toISOString(),
        });

      // Update vendor's last location update time
      await supabase
        .from('vendors')
        .update({
          last_location_update: new Date().toISOString(),
        })
        .eq('id', vendorId);

      if (error) {
        throw new Error(`Failed to update location: ${error.message}`);
      }

      return {
        success: true,
        message: 'Location updated successfully',
      };
    } catch (error) {
      console.error('Update vendor location error:', error);
      return {
        success: false,
        error: error.message,
      };
    }
  }

  /**
   * Get vendor's current location
   */
  static async getVendorLocation(vendorId) {
    try {
      const { data, error } = await supabase
        .from('vendor_locations')
        .select('*')
        .eq('vendor_id', vendorId)
        .order('created_at', { ascending: false })
        .limit(1)
        .single();

      if (error) {
        throw new Error(`Failed to get location: ${error.message}`);
      }

      return {
        success: true,
        location: data,
      };
    } catch (error) {
      console.error('Get vendor location error:', error);
      return {
        success: false,
        error: error.message,
      };
    }
  }

  /**
   * Find vendors near a location
   */
  static async findNearbyVendors(latitude, longitude, radiusKm = 10, limit = 10) {
    try {
      const { data, error } = await supabase
        .rpc('find_nearest_vendors', {
          p_latitude: latitude,
          p_longitude: longitude,
          p_radius_km: radiusKm,
          p_limit: limit,
        });

      if (error) {
        throw new Error(`Failed to find nearby vendors: ${error.message}`);
      }

      return {
        success: true,
        vendors: data,
      };
    } catch (error) {
      console.error('Find nearby vendors error:', error);
      return {
        success: false,
        error: error.message,
      };
    }
  }
}

// Real-time subscriptions
class RealtimeService {
  /**
   * Subscribe to order updates
   */
  static subscribeToOrders(callback) {
    return supabase
      .channel('orders')
      .on('postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'orders'
        },
        (payload) => callback(payload)
      )
      .subscribe();
  }

  /**
   * Subscribe to vendor updates
   */
  static subscribeToVendors(callback) {
    return supabase
      .channel('vendors')
      .on('postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'vendors'
        },
        (payload) => callback(payload)
      )
      .subscribe();
  }

  /**
   * Subscribe to new notifications
   */
  static subscribeToNotifications(recipientType, recipientId, callback) {
    return supabase
      .channel(`notifications:${recipientType}:${recipientId}`)
      .on('postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'notifications',
          filter: `recipient_type=eq.${recipientType}&recipient_id=eq.${recipientId}`
        },
        (payload) => callback(payload)
      )
      .subscribe();
  }
}

module.exports = {
  supabase,
  AdminAuth,
  VendorManager,
  LocationService,
  RealtimeService,
};