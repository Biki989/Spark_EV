-- Spark EV Charging Platform - Booking & Search Improvements
-- PostgreSQL Migration 002

-- ============================================
-- BOOKING CONFLICT PREVENTION
-- ============================================

-- Required for exclusion constraints on non-btree types
CREATE EXTENSION IF NOT EXISTS btree_gist;

-- Composite index for fast conflict lookups during booking creation
CREATE INDEX IF NOT EXISTS idx_bookings_conflict_lookup
  ON bookings (station_id, port, status, start_time, end_time);

-- Exclusion constraint: prevent overlapping bookings on the same station+port
-- Only enforced for 'confirmed' and 'active' bookings
-- NOTE: This requires the btree_gist extension above
-- The constraint uses tstzrange to represent the booking time window
-- and prevents any two rows with the same station_id + port from having overlapping ranges
ALTER TABLE bookings ADD CONSTRAINT no_overlapping_bookings
  EXCLUDE USING gist (
    station_id WITH =,
    port WITH =,
    tstzrange(start_time, end_time, '[)') WITH &&
  ) WHERE (status IN ('confirmed', 'active'));

-- ============================================
-- OPTIMIZED GEO SEARCH INDEXES
-- ============================================

-- Separate lat/lng indexes for bounding-box pre-filter queries
CREATE INDEX IF NOT EXISTS idx_stations_lat ON stations(latitude);
CREATE INDEX IF NOT EXISTS idx_stations_lng ON stations(longitude);
