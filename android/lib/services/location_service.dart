import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../utils/logger.dart';

/// Location Service - Handles geolocation, geofencing, and service areas
class LocationService {
  final _supabase = SupabaseConfig.client;

  /// Get current location with high accuracy
  Future<Map<String, dynamic>?> getCurrentLocation({
    bool forceLocationManager = false,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      AppLogger.d('Getting current location...');

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return {
            'error': 'Location permission denied',
            'message': 'Location access is required for vendor operations',
          };
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return {
          'error': 'Location permission permanently denied',
          'message': 'Please enable location access in device settings',
        };
      }

      // Check if location services are enabled
      bool isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isLocationServiceEnabled) {
        return {
          'error': 'Location services disabled',
          'message': 'Please enable location services in device settings',
        };
      }

      // Get location with high accuracy
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        forceAndroidLocationManager: forceLocationManager,
        timeLimit: timeout,
      );

      AppLogger.i('Location obtained: ${position.latitude}, ${position.longitude}');

      // Get address from coordinates (optional - requires geocoding service)
      String? address = await _getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'altitude': position.altitude,
        'speed': position.speed,
        'heading': position.heading,
        'timestamp': DateTime.now().toIso8601String(),
        'address': address,
        'success': true,
      };
    } on LocationServiceDisabledException catch (e) {
      AppLogger.e('Location services disabled: $e');
      return {
        'error': 'Location services disabled',
        'message': 'Please enable location services',
      };
    } on LocationPermissionDeniedException catch (e) {
      AppLogger.e('Location permission denied: $e');
      return {
        'error': 'Location permission denied',
        'message': 'Location permission is required',
      };
    } on LocationServiceDeniedException catch (e) {
      AppLogger.e('Location service denied: $e');
      return {
        'error': 'Location service denied',
        'message': 'Location access is denied',
      };
    } on TimeoutException catch (e) {
      AppLogger.e('Location timeout: $e');
      return {
        'error': 'Location timeout',
        'message': 'Unable to get location within specified time',
      };
    } catch (e) {
      AppLogger.e('Error getting location: $e');
      return {
        'error': 'Failed to get location',
        'message': e.toString(),
      };
    }
  }

  /// Start location tracking (continuous updates)
  Future<Stream<Position>> startLocationTracking({
    LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 10, // Minimum distance in meters
      timeInterval: Duration(seconds: 30), // Minimum time interval
    ),
  }) async {
    try {
      // Check permissions first
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission permanently denied');
      }

      return Geolocator.getPositionStream(locationSettings: locationSettings);
    } catch (e) {
      AppLogger.e('Error starting location tracking: $e');
      throw Exception('Failed to start location tracking: $e');
    }
  }

  /// Update vendor location in database
  Future<Map<String, dynamic>> updateVendorLocation({
    required double latitude,
    required double longitude,
    double? accuracy,
    double? altitude,
    double? speed,
    double? heading,
    String? locationMethod = 'gps',
    int? batteryLevel,
    bool? isCharging,
  }) async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        throw Exception('Vendor not authenticated');
      }

      final locationData = {
        'vendor_id': vendorId,
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'altitude': altitude,
        'speed': speed,
        'heading': heading,
        'location_method': locationMethod,
        'battery_level': batteryLevel,
        'is_charging': isCharging ?? false,
        'created_at': DateTime.now().toIso8601String(),
      };

      // Insert location record
      await _supabase.from('vendor_locations').insert(locationData);

      // Update vendor's last location update time
      await _supabase
          .from('vendors')
          .update({'last_location_update': DateTime.now().toIso8601String()})
          .eq('id', vendorId);

      // Also update vendor's primary location if not set
      final existingVendor = await _supabase
          .from('vendors')
          .select('latitude, longitude')
          .eq('id', vendorId)
          .single();

      if (existingVendor['latitude'] == null || existingVendor['longitude'] == null) {
        await _supabase.from('vendors').update({
          'latitude': latitude,
          'longitude': longitude,
        }).eq('id', vendorId);
      }

      AppLogger.i('Vendor location updated: $latitude, $longitude');

      return {
        'success': true,
        'message': 'Location updated successfully',
      };
    } catch (e) {
      AppLogger.e('Error updating vendor location: $e');
      return {
        'success': false,
        'error': 'Failed to update location',
        'message': e.toString(),
      };
    }
  }

  /// Get vendor service area (for geofencing)
  Future<Map<String, dynamic>?> getVendorServiceArea() async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        throw Exception('Vendor not authenticated');
      }

      final vendor = await _supabase
          .from('vendors')
          .select('''
            latitude,
            longitude,
            service_radius_km,
            service_areas,
            service_pincodes
          ''')
          .eq('id', vendorId)
          .single();

      if (vendor == null) {
        return null;
      }

      return {
        'latitude': vendor['latitude'],
        'longitude': vendor['longitude'],
        'serviceRadiusKm': vendor['service_radius_km'],
        'serviceAreas': vendor['service_areas'],
        'servicePincodes': vendor['service_pincodes'],
      };
    } catch (e) {
      AppLogger.e('Error getting vendor service area: $e');
      return null;
    }
  }

  /// Check if a location is within vendor's service area
  Future<bool> isLocationInServiceArea(
    double customerLatitude,
    double customerLongitude, {
    double? vendorLatitude,
    double? vendorLongitude,
    double? serviceRadiusKm,
  }) async {
    try {
      // Get vendor service area if not provided
      final serviceArea = await getVendorServiceArea();
      if (serviceArea == null) {
        return false;
      }

      vendorLatitude ??= serviceArea['latitude'];
      vendorLongitude ??= serviceArea['longitude'];
      serviceRadiusKm ??= serviceArea['serviceRadiusKm'];

      if (vendorLatitude == null || vendorLongitude == null) {
        return false;
      }

      // Check custom service areas (polygons)
      final serviceAreas = serviceArea['serviceAreas'] as List?;
      if (serviceAreas != null && serviceAreas.isNotEmpty) {
        // For simplicity, check radius first
        // TODO: Implement polygon checking when we have proper polygon handling
      }

      // Check service pincodes
      final servicePincodes = serviceArea['servicePincodes'] as List?;
      if (servicePincodes != null && servicePincodes.isNotEmpty) {
        // TODO: Get customer pincode and check against service pincodes
      }

      // Check radius (default geofencing)
      if (vendorLatitude != null && vendorLongitude != null && serviceRadiusKm != null) {
        final double distance = _calculateDistance(
          vendorLatitude,
          vendorLongitude,
          customerLatitude,
          customerLongitude,
        );

        return distance <= serviceRadiusKm;
      }

      return false;
    } catch (e) {
      AppLogger.e('Error checking service area: $e');
      return false;
    }
  }

  /// Get nearby vendors based on customer location
  Future<List<Map<String, dynamic>>> getNearbyVendors(
    double customerLatitude,
    double customerLongitude, {
    double radiusKm = 10,
    int limit = 10,
  }) async {
    try {
      // Use Supabase function for efficient geospatial query
      final response = await _supabase.rpc('find_nearest_vendors', params: {
        'p_latitude': customerLatitude,
        'p_longitude': customerLongitude,
        'p_radius_km': radiusKm,
        'p_limit': limit,
      });

      if (response.error != null) {
        AppLogger.e('Error getting nearby vendors: ${response.error}');
        return [];
      }

      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((vendor) => {
        'id': vendor['vendor_id'],
        'businessName': vendor['business_name'],
        'phone': vendor['phone'],
        'distance': vendor['distance_km'],
        'rating': vendor['rating'],
        'deliveryTime': vendor['delivery_time'],
        'isAvailable': vendor['is_available'],
      }).toList();
    } catch (e) {
      AppLogger.e('Error getting nearby vendors: $e');
      return [];
    }
  }

  /// Calculate distance between two coordinates using Haversine formula
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);

    double a = (dLat / 2).sin() * (dLat / 2).sin() +
        (lat1.toRadians().cos() * lat2.toRadians().cos()) *
            (dLon / 2).sin() * (dLon / 2).sin();
    double c = 2 * a.asin().sqrt();

    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (3.141592653589793 / 180);
  }

  /// Convert coordinates to LatLng for Google Maps
  LatLng toLatLng(double latitude, double longitude) {
    return LatLng(latitude, longitude);
  }

  /// Create Circle for service area visualization
  Set<Circle> createServiceAreaCircles(
    LatLng center, {
    double radiusKm = 5,
    Color color = Colors.blue.withOpacity(0.2),
    Color borderColor = Colors.blue,
    double strokeWidth = 2.0,
  }) {
    // Convert radius in km to meters (approximately)
    double radiusInMeters = radiusKm * 1000;

    return {
      Circle(
        circleId: CircleId('service_area'),
        center: center,
        radius: radiusInMeters,
        fillColor: color,
        strokeColor: borderColor,
        strokeWidth: strokeWidth,
      ),
    };
  }

  /// Get battery level (Android only)
  Future<int?> getBatteryLevel() async {
    try {
      // This would require platform-specific implementation
      // For now, return null (not implemented)
      return null;
    } catch (e) {
      AppLogger.e('Error getting battery level: $e');
      return null;
    }
  }

  /// Check if device is charging (Android only)
  Future<bool?> getIsCharging() async {
    try {
      // This would require platform-specific implementation
      // For now, return null (not implemented)
      return null;
    } catch (e) {
      AppLogger.e('Error getting charging status: $e');
      return null;
    }
  }

  /// Get address from coordinates (reverse geocoding)
  Future<String?> _getAddressFromCoordinates(
      double latitude, double longitude) async {
    try {
      // This would require a geocoding service like Google Geocoding API
      // For now, return formatted coordinates
      return 'Lat: ${latitude.toStringAsFixed(6)}, Lon: ${longitude.toStringAsFixed(6)}';
    } catch (e) {
      AppLogger.e('Error getting address from coordinates: $e');
      return null;
    }
  }

  /// Request location permissions with explanation
  Future<Map<String, dynamic>> requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        // Show user-friendly explanation
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        return {
          'granted': false,
          'message': 'Location permission was permanently denied. Please enable it in device settings.',
        };
      }

      if (permission == LocationLocationServiceDisabledException) {
        return {
          'granted': false,
          'message': 'Location services are disabled. Please enable them in device settings.',
        };
      }

      if (permission == LocationPermission.whileInUse) {
        return {
          'granted': true,
          'message': 'Location permission granted while app is in use.',
        };
      }

      if (permission == LocationPermission.always) {
        return {
          'granted': true,
          'message': 'Location permission granted always.',
        };
      }

      return {
        'granted': false,
        'message': 'Location permission not granted.',
      };
    } catch (e) {
      AppLogger.e('Error requesting location permission: $e');
      return {
        'granted': false,
        'message': 'Failed to request location permission.',
      };
    }
  }

  /// Validate location data
  bool isValidLocation(double latitude, double longitude) {
    return latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180;
  }

  /// Format location for display
  String formatLocationForDisplay(double latitude, double longitude) {
    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }

  /// Calculate estimated delivery time based on distance
  int estimateDeliveryTime(double distanceKm, {
    double averageSpeedKmPerHour = 30, // Average delivery speed
    int preparationTimeMinutes = 15, // Preparation time
  }) {
    double travelTimeHours = distanceKm / averageSpeedKmPerHour;
    int travelTimeMinutes = (travelTimeHours * 60).round();
    return preparationTimeMinutes + travelTimeMinutes;
  }

  /// Check if vendor is within working hours
  Future<bool> isVendorWithinWorkingHours() async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        return false;
      }

      final vendor = await _supabase
          .from('vendors')
          .select('business_hours, is_on_vacation')
          .eq('id', vendorId)
          .single();

      if (vendor == null || vendor['is_on_vacation'] == true) {
        return false;
      }

      final businessHours = vendor['business_hours'] as Map<String, dynamic>?;
      if (businessHours == null) {
        return true; // Assume always open if not specified
      }

      final now = DateTime.now();
      final weekday = now.weekday == 0 ? 'sunday' : [
        'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'
      ][now.weekday - 1];

      final dayHours = businessHours[weekday] as Map<String, dynamic>?;
      if (dayHours == null || dayHours['closed'] == true) {
        return false;
      }

      // Parse opening and closing times
      final openTime = dayHours['open'] as String?;
      final closeTime = dayHours['close'] as String?;

      if (openTime == null || closeTime == null) {
        return true; // Assume open if times not specified
      }

      // Simple time comparison (TODO: Implement proper time parsing)
      return true; // Simplified for now
    } catch (e) {
      AppLogger.e('Error checking working hours: $e');
      return true; // Assume open on error
    }
  }
}