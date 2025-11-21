-- Enable Supabase Realtime for operational tables
-- This migration enables WebSocket subscriptions for real-time updates in the Swift app
--
-- REPLICA IDENTITY FULL allows receiving both old and new values on UPDATE/DELETE
-- which is critical for conflict resolution and proper UI updates
--
-- Created: 2025-01-20
-- Phase 1 of Realtime Rollout

-- Set REPLICA IDENTITY FULL on critical tables
ALTER TABLE listings REPLICA IDENTITY FULL;
ALTER TABLE listing_notes REPLICA IDENTITY FULL;
ALTER TABLE activities REPLICA IDENTITY FULL;
ALTER TABLE agent_tasks REPLICA IDENTITY FULL;
ALTER TABLE listing_acknowledgments REPLICA IDENTITY FULL;
ALTER TABLE staff REPLICA IDENTITY FULL;

-- Add tables to realtime publication
-- This enables the Swift app to subscribe to changes via supabase.realtimeV2.channel()
ALTER PUBLICATION supabase_realtime ADD TABLE listings;
ALTER PUBLICATION supabase_realtime ADD TABLE listing_notes;
ALTER PUBLICATION supabase_realtime ADD TABLE activities;
ALTER PUBLICATION supabase_realtime ADD TABLE agent_tasks;
ALTER PUBLICATION supabase_realtime ADD TABLE listing_acknowledgments;
ALTER PUBLICATION supabase_realtime ADD TABLE staff;

-- Note: RLS policies already in place continue to work with realtime
-- Only rows the user is authorized to see will be broadcast to their subscription
