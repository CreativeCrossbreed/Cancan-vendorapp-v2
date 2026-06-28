-- find_nearest_vendors did not exist at all — every webhook call to it
-- errored and silently fell through to the JS fallback resolver, which
-- itself never excluded vendors on vacation. A customer could get matched
-- (or stay matched, via the Model A "owned by one vendor" reassignment
-- flow) to a vendor who is on_vacation or inactive.
CREATE OR REPLACE FUNCTION find_nearest_vendors(
  p_latitude DOUBLE PRECISION,
  p_longitude DOUBLE PRECISION,
  p_radius_km DOUBLE PRECISION DEFAULT 2,
  p_limit INTEGER DEFAULT 1
)
RETURNS TABLE(vendor_id UUID, distance_km DOUBLE PRECISION)
LANGUAGE sql
STABLE
AS $$
  SELECT vendor_id, distance_km FROM (
    SELECT v.id AS vendor_id,
      (
        6371 * acos(
          LEAST(1.0, GREATEST(-1.0,
            cos(radians(p_latitude)) * cos(radians(v.latitude)) *
            cos(radians(v.longitude) - radians(p_longitude)) +
            sin(radians(p_latitude)) * sin(radians(v.latitude))
          ))
        )
      ) AS distance_km
    FROM vendors v
    WHERE v.is_active = true
      AND v.is_on_vacation = false
      AND v.latitude IS NOT NULL
      AND v.longitude IS NOT NULL
      AND EXISTS (
        SELECT 1 FROM vendor_products vp
        WHERE vp.vendor_id = v.id AND vp.is_active = true AND vp.current_stock > 0
      )
  ) ranked
  WHERE distance_km <= p_radius_km
  ORDER BY distance_km ASC
  LIMIT p_limit;
$$;

GRANT EXECUTE ON FUNCTION find_nearest_vendors TO authenticated, service_role, anon;
