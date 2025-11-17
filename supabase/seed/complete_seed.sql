-- Operations Center Test Seed Data
-- Populates database with realistic test data for development/testing
-- Run this AFTER all migrations have been applied

BEGIN;

-- ============================================================================
-- STAFF (8 members)
-- ============================================================================
INSERT INTO public.staff (staff_id, email, name, role, slack_user_id, phone, status, created_at, updated_at, metadata) VALUES
('01JCQM1A0000000000000001', 'sarah.admin@opscenter.test', 'Sarah Chen', 'admin', 'U01ADMIN001', '+1-415-555-0101', 'active', NOW() - INTERVAL '90 days', NOW() - INTERVAL '1 day', '{"hire_date": "2023-01-15", "department": "leadership"}'),
('01JCQM1A0000000000000002', 'michael.admin@opscenter.test', 'Michael Rodriguez', 'admin', 'U01ADMIN002', '+1-415-555-0102', 'active', NOW() - INTERVAL '85 days', NOW() - INTERVAL '2 days', '{"hire_date": "2023-02-01", "department": "leadership"}'),
('01JCQM1A0000000000000003', 'alex.ops@opscenter.test', 'Alex Johnson', 'operations', 'U01OPS001', '+1-415-555-0103', 'active', NOW() - INTERVAL '60 days', NOW() - INTERVAL '3 hours', '{"hire_date": "2023-05-10", "department": "operations"}'),
('01JCQM1A0000000000000004', 'priya.ops@opscenter.test', 'Priya Patel', 'operations', 'U01OPS002', '+1-415-555-0104', 'active', NOW() - INTERVAL '55 days', NOW() - INTERVAL '1 hour', '{"hire_date": "2023-06-01", "department": "operations"}'),
('01JCQM1A0000000000000005', 'david.ops@opscenter.test', 'David Kim', 'operations', 'U01OPS003', '+1-415-555-0105', 'active', NOW() - INTERVAL '50 days', NOW() - INTERVAL '5 hours', '{"hire_date": "2023-07-15", "department": "operations"}'),
('01JCQM1A0000000000000006', 'emma.marketing@opscenter.test', 'Emma Wilson', 'marketing', 'U01MKT001', '+1-415-555-0106', 'active', NOW() - INTERVAL '45 days', NOW() - INTERVAL '2 days', '{"hire_date": "2023-08-01", "specialization": "photography"}'),
('01JCQM1A0000000000000007', 'jorge.marketing@opscenter.test', 'Jorge Sanchez', 'marketing', 'U01MKT002', '+1-415-555-0107', 'active', NOW() - INTERVAL '40 days', NOW() - INTERVAL '6 hours', '{"hire_date": "2023-09-01", "specialization": "content"}'),
('01JCQM1A0000000000000008', 'lisa.support@opscenter.test', 'Lisa Thompson', 'support', 'U01SUP001', '+1-415-555-0108', 'active', NOW() - INTERVAL '30 days', NOW() - INTERVAL '12 hours', '{"hire_date": "2023-10-15", "department": "support"}');

-- ============================================================================
-- REALTORS (12 realtors)
-- ============================================================================
INSERT INTO public.realtors (realtor_id, email, name, phone, license_number, brokerage, slack_user_id, territories, status, created_at, updated_at, metadata) VALUES
('01JCQM2B0000000000000001', 'james.broker@realty.test', 'James Patterson', '+1-650-555-2001', 'CA-DRE-01234567', 'Golden Gate Realty', 'U02REAL001', ARRAY['San Francisco', 'Peninsula'], 'active', NOW() - INTERVAL '120 days', NOW() - INTERVAL '2 days', '{"years_experience": 15, "specialization": "luxury"}'),
('01JCQM2B0000000000000002', 'maria.garcia@realty.test', 'Maria Garcia', '+1-650-555-2002', 'CA-DRE-01234568', 'Bay Area Homes', 'U02REAL002', ARRAY['South Bay', 'San Jose'], 'active', NOW() - INTERVAL '110 days', NOW() - INTERVAL '1 day', '{"years_experience": 8, "specialization": "residential"}'),
('01JCQM2B0000000000000003', 'robert.chen@realty.test', 'Robert Chen', '+1-650-555-2003', 'CA-DRE-01234569', 'Pacific Properties', 'U02REAL003', ARRAY['East Bay', 'Oakland'], 'active', NOW() - INTERVAL '100 days', NOW() - INTERVAL '5 hours', '{"years_experience": 12, "specialization": "commercial"}'),
('01JCQM2B0000000000000004', 'jennifer.lee@realty.test', 'Jennifer Lee', '+1-650-555-2004', 'CA-DRE-01234570', 'Coastal Realty Group', 'U02REAL004', ARRAY['Peninsula', 'Palo Alto'], 'active', NOW() - INTERVAL '95 days', NOW() - INTERVAL '3 hours', '{"years_experience": 10, "specialization": "luxury"}'),
('01JCQM2B0000000000000005', 'william.brown@realty.test', 'William Brown', '+1-650-555-2005', 'CA-DRE-01234571', 'Prestige Realty', 'U02REAL005', ARRAY['San Francisco', 'Marin'], 'active', NOW() - INTERVAL '85 days', NOW() - INTERVAL '1 day', '{"years_experience": 20, "specialization": "estates"}'),
('01JCQM2B0000000000000006', 'sophia.martinez@realty.test', 'Sophia Martinez', '+1-650-555-2006', 'CA-DRE-01234572', 'Urban Living Realty', 'U02REAL006', ARRAY['San Francisco', 'SOMA'], 'active', NOW() - INTERVAL '75 days', NOW() - INTERVAL '6 hours', '{"years_experience": 6, "specialization": "condos"}'),
('01JCQM2B0000000000000007', 'daniel.nguyen@realty.test', 'Daniel Nguyen', '+1-650-555-2007', 'CA-DRE-01234573', 'Silicon Valley Homes', 'U02REAL007', ARRAY['South Bay', 'Mountain View'], 'active', NOW() - INTERVAL '70 days', NOW() - INTERVAL '12 hours', '{"years_experience": 9, "specialization": "tech_clients"}'),
('01JCQM2B0000000000000008', 'olivia.johnson@realty.test', 'Olivia Johnson', '+1-650-555-2008', 'CA-DRE-01234574', 'Bay Properties Inc', 'U02REAL008', ARRAY['East Bay', 'Berkeley'], 'active', NOW() - INTERVAL '65 days', NOW() - INTERVAL '2 days', '{"years_experience": 7, "specialization": "family_homes"}'),
('01JCQM2B0000000000000009', 'thomas.anderson@realty.test', 'Thomas Anderson', '+1-650-555-2009', 'CA-DRE-01234575', 'Peninsula Real Estate', 'U02REAL009', ARRAY['Peninsula', 'Menlo Park'], 'active', NOW() - INTERVAL '60 days', NOW() - INTERVAL '8 hours', '{"years_experience": 11, "specialization": "investment"}'),
('01JCQM2B0000000000000010', 'isabella.wang@realty.test', 'Isabella Wang', '+1-650-555-2010', 'CA-DRE-01234576', 'Pacific Coast Realty', 'U02REAL010', ARRAY['San Francisco', 'Sunset'], 'active', NOW() - INTERVAL '55 days', NOW() - INTERVAL '1 day', '{"years_experience": 5, "specialization": "first_time_buyers"}'),
('01JCQM2B0000000000000011', 'mark.retired@realty.test', 'Mark Sullivan', '+1-650-555-2011', 'CA-DRE-01234577', 'Golden Gate Realty', NULL, ARRAY['San Francisco'], 'inactive', NOW() - INTERVAL '200 days', NOW() - INTERVAL '90 days', '{"years_experience": 25, "retirement_date": "2024-08-01"}'),
('01JCQM2B0000000000000012', 'amy.pending@realty.test', 'Amy Foster', '+1-650-555-2012', NULL, 'Bay Area Homes', NULL, ARRAY['Peninsula'], 'pending', NOW() - INTERVAL '5 days', NOW() - INTERVAL '1 hour', '{"application_date": "2025-01-10", "status": "background_check"}');

-- ============================================================================
-- LISTINGS (25 listings)
-- ============================================================================
INSERT INTO public.listings (listing_id, address_string, status, assignee, realtor_id, due_date, progress, type, notes, created_at, updated_at) VALUES
-- New listings (unclaimed, should appear in Inbox for all staff)
('01JCQM3C0000000000000001', '2847 Pacific Avenue, San Francisco, CA 94115', 'new', NULL, '01JCQM2B0000000000000001', NOW() + INTERVAL '7 days', 0.0, 'SALE', 'Luxury Victorian, needs full photo package', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),
('01JCQM3C0000000000000002', '456 Lombard Street, San Francisco, CA 94133', 'new', NULL, '01JCQM2B0000000000000006', NOW() + INTERVAL '5 days', 0.0, 'RENTAL', 'Popular tourist area, emphasize location', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
('01JCQM3C0000000000000003', '789 Valencia Street, San Francisco, CA 94110', 'new', NULL, '01JCQM2B0000000000000010', NOW() + INTERVAL '10 days', 0.0, 'SALE', 'Mission District condo, first-time buyer focused', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),
('01JCQM3C0000000000000004', '321 Page Street, San Francisco, CA 94102', 'new', NULL, '01JCQM2B0000000000000006', NOW() + INTERVAL '14 days', 0.0, 'RENTAL', 'Haight-Ashbury vintage apartment', NOW() - INTERVAL '6 hours', NOW() - INTERVAL '6 hours'),

-- In progress (claimed by staff, active work)
('01JCQM3C0000000000000005', '1234 Market Street, San Francisco, CA 94102', 'in_progress', '01JCQM1A0000000000000003', '01JCQM2B0000000000000001', NOW() + INTERVAL '3 days', 0.45, 'SALE', 'High-rise condo, photography in progress', NOW() - INTERVAL '10 days', NOW() - INTERVAL '2 hours'),
('01JCQM3C0000000000000006', '567 Castro Street, San Francisco, CA 94114', 'in_progress', '01JCQM1A0000000000000004', '01JCQM2B0000000000000002', NOW() + INTERVAL '2 days', 0.60, 'SALE', 'Castro District home, staging scheduled', NOW() - INTERVAL '8 days', NOW() - INTERVAL '1 day'),
('01JCQM3C0000000000000007', '890 Divisadero Street, San Francisco, CA 94115', 'in_progress', '01JCQM1A0000000000000006', '01JCQM2B0000000000000004', NOW() + INTERVAL '4 days', 0.75, 'SALE', 'Luxury listing, final photo edits underway', NOW() - INTERVAL '12 days', NOW() - INTERVAL '3 hours'),
('01JCQM3C0000000000000008', '1122 Folsom Street, San Francisco, CA 94103', 'in_progress', '01JCQM1A0000000000000005', '01JCQM2B0000000000000003', NOW() + INTERVAL '6 days', 0.30, 'COMMERCIAL', 'SoMa retail space, needs floor plans', NOW() - INTERVAL '15 days', NOW() - INTERVAL '4 hours'),
('01JCQM3C0000000000000009', '2345 Union Street, San Francisco, CA 94123', 'in_progress', '01JCQM1A0000000000000007', '01JCQM2B0000000000000005', NOW() + INTERVAL '1 day', 0.85, 'SALE', 'Marina District condo, almost ready', NOW() - INTERVAL '18 days', NOW() - INTERVAL '5 hours'),
('01JCQM3C0000000000000010', '678 Hayes Street, San Francisco, CA 94102', 'in_progress', '01JCQM1A0000000000000003', '01JCQM2B0000000000000007', NOW() + INTERVAL '8 days', 0.20, 'SALE', 'Hayes Valley loft, just started', NOW() - INTERVAL '5 days', NOW() - INTERVAL '1 hour'),

-- Completed (finished work)
('01JCQM3C0000000000000011', '3456 Chestnut Street, San Francisco, CA 94123', 'completed', '01JCQM1A0000000000000006', '01JCQM2B0000000000000001', NOW() - INTERVAL '2 days', 1.0, 'SALE', 'Successfully listed, great photos', NOW() - INTERVAL '25 days', NOW() - INTERVAL '2 days'),
('01JCQM3C0000000000000012', '789 Russian Hill Place, San Francisco, CA 94133', 'completed', '01JCQM1A0000000000000007', '01JCQM2B0000000000000004', NOW() - INTERVAL '5 days', 1.0, 'SALE', 'Premium listing, all assets delivered', NOW() - INTERVAL '30 days', NOW() - INTERVAL '5 days'),
('01JCQM3C0000000000000013', '1011 Potrero Avenue, San Francisco, CA 94110', 'completed', '01JCQM1A0000000000000004', '01JCQM2B0000000000000008', NOW() - INTERVAL '10 days', 1.0, 'SALE', 'Family home, quick turnaround', NOW() - INTERVAL '20 days', NOW() - INTERVAL '10 days'),
('01JCQM3C0000000000000014', '1213 Cole Street, San Francisco, CA 94117', 'completed', '01JCQM1A0000000000000003', '01JCQM2B0000000000000009', NOW() - INTERVAL '15 days', 1.0, 'RENTAL', 'Rental property, standard package', NOW() - INTERVAL '22 days', NOW() - INTERVAL '15 days'),

-- More in-progress (for task variety)
('01JCQM3C0000000000000015', '1415 Noe Street, San Francisco, CA 94114', 'in_progress', '01JCQM1A0000000000000006', '01JCQM2B0000000000000002', NOW() - INTERVAL '1 day', 0.90, 'SALE', 'OVERDUE: Final edits needed', NOW() - INTERVAL '20 days', NOW() - INTERVAL '6 hours'),
('01JCQM3C0000000000000016', '1617 Guerrero Street, San Francisco, CA 94110', 'in_progress', '01JCQM1A0000000000000007', '01JCQM2B0000000000000006', NOW() + INTERVAL '2 days', 0.55, 'RENTAL', 'Mission District rental, on track', NOW() - INTERVAL '7 days', NOW() - INTERVAL '2 hours'),
('01JCQM3C0000000000000017', '1819 Clement Street, San Francisco, CA 94121', 'in_progress', '01JCQM1A0000000000000005', '01JCQM2B0000000000000007', NOW() + INTERVAL '5 days', 0.40, 'SALE', 'Richmond District home, photography scheduled', NOW() - INTERVAL '9 days', NOW() - INTERVAL '1 day'),
('01JCQM3C0000000000000018', '2021 Irving Street, San Francisco, CA 94122', 'in_progress', '01JCQM1A0000000000000004', '01JCQM2B0000000000000010', NOW() + INTERVAL '3 days', 0.65, 'SALE', 'Sunset District, awaiting drone shots', NOW() - INTERVAL '11 days', NOW() - INTERVAL '3 hours'),

-- More new listings (variety in dates)
('01JCQM3C0000000000000019', '2223 Taraval Street, San Francisco, CA 94116', 'new', NULL, '01JCQM2B0000000000000009', NOW() + INTERVAL '12 days', 0.0, 'SALE', 'Investment property, needs assessment', NOW() - INTERVAL '3 hours', NOW() - INTERVAL '3 hours'),
('01JCQM3C0000000000000020', '2425 Balboa Street, San Francisco, CA 94121', 'new', NULL, '01JCQM2B0000000000000003', NOW() + INTERVAL '9 days', 0.0, 'COMMERCIAL', 'Commercial space, full marketing package needed', NOW() - INTERVAL '12 hours', NOW() - INTERVAL '12 hours'),

-- More completed
('01JCQM3C0000000000000021', '2627 California Street, San Francisco, CA 94115', 'completed', '01JCQM1A0000000000000006', '01JCQM2B0000000000000005', NOW() - INTERVAL '7 days', 1.0, 'SALE', 'Luxury estate, premium package delivered', NOW() - INTERVAL '35 days', NOW() - INTERVAL '7 days'),
('01JCQM3C0000000000000022', '2829 Broadway, San Francisco, CA 94115', 'completed', '01JCQM1A0000000000000007', '01JCQM2B0000000000000001', NOW() - INTERVAL '12 days', 1.0, 'SALE', 'Pacific Heights home, excellent results', NOW() - INTERVAL '28 days', NOW() - INTERVAL '12 days'),

-- Edge cases
('01JCQM3C0000000000000023', '3031 Fillmore Street, San Francisco, CA 94123', 'new', NULL, '01JCQM2B0000000000000008', NOW() + INTERVAL '20 days', 0.0, 'RENTAL', 'Long lead time, flexible schedule', NOW() - INTERVAL '2 hours', NOW() - INTERVAL '2 hours'),
('01JCQM3C0000000000000024', '3233 Sacramento Street, San Francisco, CA 94115', 'in_progress', '01JCQM1A0000000000000003', '01JCQM2B0000000000000004', NOW() - INTERVAL '3 days', 0.50, 'SALE', 'OVERDUE: Needs immediate attention', NOW() - INTERVAL '25 days', NOW() - INTERVAL '8 hours'),
('01JCQM3C0000000000000025', '3435 Green Street, San Francisco, CA 94123', 'in_progress', '01JCQM1A0000000000000005', '01JCQM2B0000000000000002', NOW() + INTERVAL '15 days', 0.15, 'SALE', 'Just assigned, early stage', NOW() - INTERVAL '2 days', NOW() - INTERVAL '4 hours');

-- ============================================================================
-- ACTIVITIES (50 listing-linked tasks)
-- ============================================================================
INSERT INTO public.activities (task_id, listing_id, realtor_id, name, description, task_category, status, priority, visibility_group, assigned_staff_id, due_date, claimed_at, completed_at, created_at, updated_at, inputs, outputs) VALUES
-- Listing 01 tasks
('01JCQM4D0000000000000001', '01JCQM3C0000000000000001', '01JCQM2B0000000000000001', 'Schedule luxury photo shoot', 'Book professional photographer for Victorian property, includes interior, exterior, twilight shots', 'MARKETING', 'OPEN', 90, 'BOTH', NULL, NOW() + INTERVAL '5 days', NULL, NULL, NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day', '{"photographer_type": "luxury", "shot_types": ["interior", "exterior", "twilight"]}', '{}'),
('01JCQM4D0000000000000002', '01JCQM3C0000000000000001', '01JCQM2B0000000000000001', 'Create property description', 'Write compelling listing copy highlighting Victorian architecture and neighborhood', 'MARKETING', 'OPEN', 80, 'MARKETING', NULL, NOW() + INTERVAL '6 days', NULL, NULL, NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day', '{"word_count": "300-400", "tone": "luxury"}', '{}'),

-- Listing 02 tasks
('01JCQM4D0000000000000003', '01JCQM3C0000000000000002', '01JCQM2B0000000000000006', 'Quick rental photography', 'Standard interior/exterior shots for rental listing', 'MARKETING', 'OPEN', 60, 'MARKETING', NULL, NOW() + INTERVAL '3 days', NULL, NULL, NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days', '{"shot_types": ["interior", "exterior"]}', '{}'),

-- Listing 05 tasks (in progress - some claimed)
('01JCQM4D0000000000000004', '01JCQM3C0000000000000005', '01JCQM2B0000000000000001', 'Photo shoot completed', 'Professional photos taken, awaiting edits', 'MARKETING', 'IN_PROGRESS', 85, 'MARKETING', '01JCQM1A0000000000000006', NOW() + INTERVAL '2 days', NOW() - INTERVAL '6 days', NULL, NOW() - INTERVAL '8 days', NOW() - INTERVAL '1 hour', '{"photographer": "Emma Wilson", "edit_deadline": "2 days"}', '{}'),
('01JCQM4D0000000000000005', '01JCQM3C0000000000000005', '01JCQM2B0000000000000001', 'Upload to MLS', 'Upload final photos and description to MLS system', 'ADMIN', 'OPEN', 70, 'AGENT', NULL, NOW() + INTERVAL '3 days', NULL, NULL, NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days', '{"mls_system": "SFAR", "account": "james.broker"}', '{}'),

-- Listing 06 tasks (in progress)
('01JCQM4D0000000000000006', '01JCQM3C0000000000000006', '01JCQM2B0000000000000002', 'Coordinate staging', 'Schedule home staging consultation and setup', 'MARKETING', 'CLAIMED', 75, 'BOTH', '01JCQM1A0000000000000007', NOW() + INTERVAL '1 day', NOW() - INTERVAL '3 days', NULL, NOW() - INTERVAL '7 days', NOW() - INTERVAL '2 hours', '{"staging_company": "SF Staging Co", "budget": "$3000"}', '{}'),
('01JCQM4D0000000000000007', '01JCQM3C0000000000000006', '01JCQM2B0000000000000002', 'Post-staging photography', 'Capture staged home with professional photographer', 'MARKETING', 'OPEN', 80, 'MARKETING', NULL, NOW() + INTERVAL '2 days', NULL, NULL, NOW() - INTERVAL '6 days', NOW() - INTERVAL '6 days', '{"depends_on": "staging", "photographer_type": "residential"}', '{}'),

-- Listing 07 tasks (in progress, high completion)
('01JCQM4D0000000000000008', '01JCQM3C0000000000000007', '01JCQM2B0000000000000004', 'Final photo editing', 'Color correction and enhancement of luxury listing photos', 'MARKETING', 'IN_PROGRESS', 95, 'MARKETING', '01JCQM1A0000000000000006', NOW() + INTERVAL '3 days', NOW() - INTERVAL '10 days', NULL, NOW() - INTERVAL '11 days', NOW() - INTERVAL '1 hour', '{"photo_count": 45, "edits": "color, lighting, perspective"}', '{"completed": 38}'),
('01JCQM4D0000000000000009', '01JCQM3C0000000000000007', '01JCQM2B0000000000000004', 'Create virtual tour', 'Stitch photos into 360 virtual tour', 'MARKETING', 'OPEN', 85, 'MARKETING', NULL, NOW() + INTERVAL '4 days', NULL, NULL, NOW() - INTERVAL '10 days', NOW() - INTERVAL '10 days', '{"tour_platform": "Matterport", "room_count": 6}', '{}'),

-- Listing 08 tasks (commercial property)
('01JCQM4D0000000000000010', '01JCQM3C0000000000000008', '01JCQM2B0000000000000003', 'Create floor plan diagram', 'Measure and draft commercial space floor plan', 'ADMIN', 'CLAIMED', 70, 'BOTH', '01JCQM1A0000000000000005', NOW() + INTERVAL '5 days', NOW() - INTERVAL '8 days', NULL, NOW() - INTERVAL '14 days', NOW() - INTERVAL '3 hours', '{"sqft": 2400, "format": "PDF, CAD"}', '{}'),
('01JCQM4D0000000000000011', '01JCQM3C0000000000000008', '01JCQM2B0000000000000003', 'Commercial photography', 'Wide-angle shots emphasizing retail space layout', 'MARKETING', 'OPEN', 65, 'MARKETING', NULL, NOW() + INTERVAL '6 days', NULL, NULL, NOW() - INTERVAL '13 days', NOW() - INTERVAL '13 days', '{"shot_types": ["wide_angle", "detail", "storefront"]}', '{}'),

-- Listing 09 tasks (almost done)
('01JCQM4D0000000000000012', '01JCQM3C0000000000000009', '01JCQM2B0000000000000005', 'Final QA check', 'Review all listing materials before publishing', 'ADMIN', 'IN_PROGRESS', 100, 'BOTH', '01JCQM1A0000000000000002', NOW() + INTERVAL '1 day', NOW() - INTERVAL '2 days', NULL, NOW() - INTERVAL '5 days', NOW() - INTERVAL '30 minutes', '{"checklist": ["photos", "description", "price", "disclosures"]}', '{"photos": "approved", "description": "approved"}'),

-- Listing 10 tasks (just started)
('01JCQM4D0000000000000013', '01JCQM3C0000000000000010', '01JCQM2B0000000000000007', 'Initial property photography', 'Basic interior/exterior shots for Hayes Valley loft', 'MARKETING', 'OPEN', 65, 'MARKETING', NULL, NOW() + INTERVAL '7 days', NULL, NULL, NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days', '{"shot_types": ["interior", "exterior", "neighborhood"]}', '{}'),

-- Completed listings (showing DONE tasks)
('01JCQM4D0000000000000014', '01JCQM3C0000000000000011', '01JCQM2B0000000000000001', 'Photo package delivered', 'All photos edited and delivered to agent', 'MARKETING', 'DONE', 90, 'MARKETING', '01JCQM1A0000000000000006', NOW() - INTERVAL '3 days', NOW() - INTERVAL '20 days', NOW() - INTERVAL '3 days', NOW() - INTERVAL '24 days', NOW() - INTERVAL '3 days', '{"photo_count": 35}', '{"delivery_method": "Dropbox", "delivered_at": "2024-12-20"}'),
('01JCQM4D0000000000000015', '01JCQM3C0000000000000011', '01JCQM2B0000000000000001', 'MLS upload complete', 'Listing live on MLS with all media', 'ADMIN', 'DONE', 85, 'AGENT', '01JCQM1A0000000000000003', NOW() - INTERVAL '2 days', NOW() - INTERVAL '18 days', NOW() - INTERVAL '2 days', NOW() - INTERVAL '23 days', NOW() - INTERVAL '2 days', '{"mls_id": "SF12345678"}', '{"url": "https://mls.sfar.com/listing/12345678"}'),

-- More variety across other listings
('01JCQM4D0000000000000016', '01JCQM3C0000000000000015', '01JCQM2B0000000000000002', 'URGENT: Final edits OVERDUE', 'Complete photo edits for overdue listing', 'MARKETING', 'IN_PROGRESS', 100, 'MARKETING', '01JCQM1A0000000000000006', NOW() - INTERVAL '1 day', NOW() - INTERVAL '5 days', NULL, NOW() - INTERVAL '15 days', NOW() - INTERVAL '2 hours', '{"priority": "urgent", "edits": "color, brightness"}', '{"progress": "75%"}'),
('01JCQM4D0000000000000017', '01JCQM3C0000000000000016', '01JCQM2B0000000000000006', 'Rental property photos', 'Standard photo package for rental listing', 'MARKETING', 'CLAIMED', 55, 'MARKETING', '01JCQM1A0000000000000007', NOW() + INTERVAL '1 day', NOW() - INTERVAL '3 days', NULL, NOW() - INTERVAL '6 days', NOW() - INTERVAL '1 day', '{"shot_types": ["interior", "exterior"]}', '{}'),
('01JCQM4D0000000000000018', '01JCQM3C0000000000000017', '01JCQM2B0000000000000007', 'Schedule drone photography', 'Book drone operator for aerial shots of Richmond property', 'MARKETING', 'OPEN', 70, 'BOTH', NULL, NOW() + INTERVAL '4 days', NULL, NULL, NOW() - INTERVAL '8 days', NOW() - INTERVAL '8 days', '{"drone_operator": "SkyView SF", "weather_dependent": true}', '{}'),
('01JCQM4D0000000000000019', '01JCQM3C0000000000000018', '01JCQM2B0000000000000010', 'Awaiting drone shots', 'Waiting for clear weather for drone photography', 'MARKETING', 'CLAIMED', 60, 'MARKETING', '01JCQM1A0000000000000006', NOW() + INTERVAL '2 days', NOW() - INTERVAL '6 days', NULL, NOW() - INTERVAL '10 days', NOW() - INTERVAL '1 day', '{"weather": "pending", "backup_date": "next_week"}', '{}'),

-- More DONE tasks from completed listings
('01JCQM4D0000000000000020', '01JCQM3C0000000000000012', '01JCQM2B0000000000000004', 'Premium photo package', 'Luxury listing photography completed', 'MARKETING', 'DONE', 95, 'MARKETING', '01JCQM1A0000000000000006', NOW() - INTERVAL '6 days', NOW() - INTERVAL '25 days', NOW() - INTERVAL '6 days', NOW() - INTERVAL '29 days', NOW() - INTERVAL '6 days', '{"photo_count": 50, "includes_twilight": true}', '{"delivered": "Dropbox", "agent_feedback": "Excellent"}'),
('01JCQM4D0000000000000021', '01JCQM3C0000000000000013', '01JCQM2B0000000000000008', 'Family home photo package', 'Standard residential photography', 'MARKETING', 'DONE', 70, 'MARKETING', '01JCQM1A0000000000000007', NOW() - INTERVAL '11 days', NOW() - INTERVAL '18 days', NOW() - INTERVAL '11 days', NOW() - INTERVAL '19 days', NOW() - INTERVAL '11 days', '{"photo_count": 25}', '{"delivered": "Email"}'),

-- New listings (OPEN tasks)
('01JCQM4D0000000000000022', '01JCQM3C0000000000000019', '01JCQM2B0000000000000009', 'Investment property assessment', 'Document property condition for investment buyer', 'ADMIN', 'OPEN', 65, 'AGENT', NULL, NOW() + INTERVAL '10 days', NULL, NULL, NOW() - INTERVAL '2 hours', NOW() - INTERVAL '2 hours', '{"assessment_type": "investment", "focus": "ROI"}', '{}'),
('01JCQM4D0000000000000023', '01JCQM3C0000000000000020', '01JCQM2B0000000000000003', 'Commercial marketing package', 'Full commercial listing package with floor plans', 'MARKETING', 'OPEN', 75, 'BOTH', NULL, NOW() + INTERVAL '8 days', NULL, NULL, NOW() - INTERVAL '10 hours', NOW() - INTERVAL '10 hours', '{"includes": ["photos", "floor_plan", "demographics"]}', '{}'),

-- More completed tasks
('01JCQM4D0000000000000024', '01JCQM3C0000000000000021', '01JCQM2B0000000000000005', 'Luxury estate package', 'Premium photography and marketing materials', 'MARKETING', 'DONE', 100, 'BOTH', '01JCQM1A0000000000000006', NOW() - INTERVAL '8 days', NOW() - INTERVAL '30 days', NOW() - INTERVAL '8 days', NOW() - INTERVAL '34 days', NOW() - INTERVAL '8 days', '{"photo_count": 60, "includes": ["twilight", "aerial", "virtual_tour"]}', '{"delivered": "Luxury package portal", "virtual_tour_url": "https://tours.example.com/2627-california"}'),

-- Overdue task
('01JCQM4D0000000000000025', '01JCQM3C0000000000000024', '01JCQM2B0000000000000004', 'OVERDUE: Urgent photo edits', 'Complete overdue photo editing immediately', 'MARKETING', 'IN_PROGRESS', 100, 'MARKETING', '01JCQM1A0000000000000006', NOW() - INTERVAL '3 days', NOW() - INTERVAL '15 days', NULL, NOW() - INTERVAL '24 days', NOW() - INTERVAL '4 hours', '{"priority": "critical", "escalated": true}', '{"progress": "60%"}'),

-- Additional tasks for variety (mix of statuses, categories, visibility)
('01JCQM4D0000000000000026', '01JCQM3C0000000000000005', '01JCQM2B0000000000000001', 'Create property flyer', 'Design print flyer for open house', 'MARKETING', 'OPEN', 50, 'MARKETING', NULL, NOW() + INTERVAL '4 days', NULL, NULL, NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days', '{"format": "8.5x11", "quantity": 100}', '{}'),
('01JCQM4D0000000000000027', '01JCQM3C0000000000000006', '01JCQM2B0000000000000002', 'Update CRM with listing', 'Add listing details to CRM system', 'ADMIN', 'CLAIMED', 40, 'AGENT', '01JCQM1A0000000000000004', NOW() + INTERVAL '2 days', NOW() - INTERVAL '4 days', NULL, NOW() - INTERVAL '7 days', NOW() - INTERVAL '1 day', '{"crm_system": "Salesforce"}', '{}'),
('01JCQM4D0000000000000028', '01JCQM3C0000000000000007', '01JCQM2B0000000000000004', 'Social media campaign', 'Create Instagram/Facebook posts for luxury listing', 'MARKETING', 'OPEN', 65, 'MARKETING', NULL, NOW() + INTERVAL '5 days', NULL, NULL, NOW() - INTERVAL '10 days', NOW() - INTERVAL '10 days', '{"platforms": ["Instagram", "Facebook"], "post_count": 5}', '{}'),
('01JCQM4D0000000000000029', '01JCQM3C0000000000000008', '01JCQM2B0000000000000003', 'Zoning verification', 'Verify commercial zoning and permitted uses', 'ADMIN', 'IN_PROGRESS', 80, 'AGENT', '01JCQM1A0000000000000003', NOW() + INTERVAL '6 days', NOW() - INTERVAL '10 days', NULL, NOW() - INTERVAL '14 days', NOW() - INTERVAL '2 hours', '{"zoning_type": "C-2", "contact": "SF Planning"}', '{"status": "in_review"}'),
('01JCQM4D0000000000000030', '01JCQM3C0000000000000009', '01JCQM2B0000000000000005', 'Schedule open house', 'Coordinate open house date and materials', 'ADMIN', 'CLAIMED', 75, 'BOTH', '01JCQM1A0000000000000003', NOW() + INTERVAL '1 day', NOW() - INTERVAL '8 days', NULL, NOW() - INTERVAL '15 days', NOW() - INTERVAL '6 hours', '{"open_house_date": "this_weekend", "signage": true}', '{}'),

-- More tasks across various listings
('01JCQM4D0000000000000031', '01JCQM3C0000000000000010', '01JCQM2B0000000000000007', 'Loft marketing copy', 'Write compelling description highlighting loft features', 'MARKETING', 'OPEN', 55, 'MARKETING', NULL, NOW() + INTERVAL '7 days', NULL, NULL, NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days', '{"word_count": "200-300", "highlight": "open_layout"}', '{}'),
('01JCQM4D0000000000000032', '01JCQM3C0000000000000014', '01JCQM2B0000000000000009', 'Rental listing publish', 'Publish rental listing on Zillow, Trulia, etc', 'ADMIN', 'DONE', 60, 'AGENT', '01JCQM1A0000000000000004', NOW() - INTERVAL '16 days', NOW() - INTERVAL '21 days', NOW() - INTERVAL '16 days', NOW() - INTERVAL '21 days', NOW() - INTERVAL '16 days', '{"platforms": ["Zillow", "Trulia", "Apartments.com"]}', '{"published": true, "listing_ids": ["Z123", "T456", "A789"]}'),
('01JCQM4D0000000000000033', '01JCQM3C0000000000000015', '01JCQM2B0000000000000002', 'Photo retouching', 'Advanced retouching for select hero shots', 'MARKETING', 'CLAIMED', 85, 'MARKETING', '01JCQM1A0000000000000006', NOW() + INTERVAL '1 day', NOW() - INTERVAL '12 days', NULL, NOW() - INTERVAL '18 days', NOW() - INTERVAL '3 hours', '{"hero_shots": 5, "retouching": "advanced"}', '{"completed": 3}'),
('01JCQM4D0000000000000034', '01JCQM3C0000000000000016', '01JCQM2B0000000000000006', 'Mission District neighborhood guide', 'Create neighborhood highlights document', 'MARKETING', 'OPEN', 45, 'MARKETING', NULL, NOW() + INTERVAL '3 days', NULL, NULL, NOW() - INTERVAL '6 days', NOW() - INTERVAL '6 days', '{"sections": ["restaurants", "transit", "schools"]}', '{}'),
('01JCQM4D0000000000000035', '01JCQM3C0000000000000017', '01JCQM2B0000000000000007', 'Richmond District photography', 'Standard interior/exterior photo shoot', 'MARKETING', 'CLAIMED', 60, 'MARKETING', '01JCQM1A0000000000000007', NOW() + INTERVAL '4 days', NOW() - INTERVAL '5 days', NULL, NOW() - INTERVAL '8 days', NOW() - INTERVAL '2 days', '{"shot_types": ["interior", "exterior"]}', '{}'),

-- Additional edge case tasks
('01JCQM4D0000000000000036', '01JCQM3C0000000000000018', '01JCQM2B0000000000000010', 'Weather delay notification', 'Notify agent of drone photography delay', 'ADMIN', 'OPEN', 30, 'AGENT', NULL, NOW() + INTERVAL '1 day', NULL, NULL, NOW() - INTERVAL '9 days', NOW() - INTERVAL '9 days', '{"reason": "weather", "new_date": "TBD"}', '{}'),
('01JCQM4D0000000000000037', '01JCQM3C0000000000000001', '01JCQM2B0000000000000001', 'Victorian architecture documentation', 'Document historical details for marketing materials', 'MARKETING', 'OPEN', 70, 'BOTH', NULL, NOW() + INTERVAL '6 days', NULL, NULL, NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day', '{"research": "historical_details", "photos": "architectural_features"}', '{}'),
('01JCQM4D0000000000000038', '01JCQM3C0000000000000002', '01JCQM2B0000000000000006', 'Lombard Street location highlight', 'Create location-focused marketing content', 'MARKETING', 'OPEN', 65, 'MARKETING', NULL, NOW() + INTERVAL '4 days', NULL, NULL, NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days', '{"focus": "tourist_attraction_proximity"}', '{}'),
('01JCQM4D0000000000000039', '01JCQM3C0000000000000003', '01JCQM2B0000000000000010', 'First-time buyer package', 'Create educational materials for first-time buyers', 'MARKETING', 'OPEN', 55, 'BOTH', NULL, NOW() + INTERVAL '9 days', NULL, NULL, NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day', '{"materials": ["buyer_guide", "financing_overview"]}', '{}'),
('01JCQM4D0000000000000040', '01JCQM3C0000000000000004', '01JCQM2B0000000000000006', 'Haight vintage aesthetic', 'Photography emphasizing vintage character', 'MARKETING', 'OPEN', 50, 'MARKETING', NULL, NOW() + INTERVAL '12 days', NULL, NULL, NOW() - INTERVAL '5 hours', NOW() - INTERVAL '5 hours', '{"style": "vintage", "emphasis": "character_details"}', '{}'),

-- Final variety tasks
('01JCQM4D0000000000000041', '01JCQM3C0000000000000022', '01JCQM2B0000000000000001', 'Pacific Heights delivery', 'Final asset delivery to agent', 'ADMIN', 'DONE', 90, 'AGENT', '01JCQM1A0000000000000003', NOW() - INTERVAL '13 days', NOW() - INTERVAL '26 days', NOW() - INTERVAL '13 days', NOW() - INTERVAL '27 days', NOW() - INTERVAL '13 days', '{"delivery_method": "Agent portal"}', '{"confirmed": true}'),
('01JCQM4D0000000000000042', '01JCQM3C0000000000000023', '01JCQM2B0000000000000008', 'Flexible scheduling coordination', 'Coordinate with agent for photography timing', 'ADMIN', 'OPEN', 35, 'AGENT', NULL, NOW() + INTERVAL '18 days', NULL, NULL, NOW() - INTERVAL '1 hour', NOW() - INTERVAL '1 hour', '{"flexibility": "high", "lead_time": "20_days"}', '{}'),
('01JCQM4D0000000000000043', '01JCQM3C0000000000000024', '01JCQM2B0000000000000004', 'Escalation notice', 'Notify management of overdue listing', 'ADMIN', 'CLAIMED', 100, 'BOTH', '01JCQM1A0000000000000002', NOW() - INTERVAL '2 days', NOW() - INTERVAL '20 days', NULL, NOW() - INTERVAL '24 days', NOW() - INTERVAL '6 hours', '{"escalation_level": "high", "notify": "management"}', '{"notified": "Sarah Chen"}'),
('01JCQM4D0000000000000044', '01JCQM3C0000000000000025', '01JCQM2B0000000000000002', 'Initial property walkthrough', 'Document property condition and shoot plan', 'ADMIN', 'OPEN', 60, 'BOTH', NULL, NOW() + INTERVAL '13 days', NULL, NULL, NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day', '{"walkthrough_type": "pre_shoot"}', '{}'),

-- Final tasks to reach 50
('01JCQM4D0000000000000045', '01JCQM3C0000000000000007', '01JCQM2B0000000000000004', 'Email campaign design', 'Create email campaign for luxury listing announcement', 'MARKETING', 'OPEN', 70, 'MARKETING', NULL, NOW() + INTERVAL '5 days', NULL, NULL, NOW() - INTERVAL '11 days', NOW() - INTERVAL '11 days', '{"email_count": 1, "audience": "luxury_buyers"}', '{}'),
('01JCQM4D0000000000000046', '01JCQM3C0000000000000008', '01JCQM2B0000000000000003', 'Commercial tenant info', 'Create information packet for potential commercial tenants', 'MARKETING', 'OPEN', 55, 'BOTH', NULL, NOW() + INTERVAL '7 days', NULL, NULL, NOW() - INTERVAL '13 days', NOW() - INTERVAL '13 days', '{"packet_type": "commercial_rental"}', '{}'),
('01JCQM4D0000000000000047', '01JCQM3C0000000000000009', '01JCQM2B0000000000000005', 'Marina District marketing', 'Highlight Marina location benefits', 'MARKETING', 'CLAIMED', 60, 'MARKETING', '01JCQM1A0000000000000007', NOW() + INTERVAL '1 day', NOW() - INTERVAL '14 days', NULL, NOW() - INTERVAL '17 days', NOW() - INTERVAL '4 hours', '{"focus": "lifestyle", "neighborhood": "Marina"}', '{}'),
('01JCQM4D0000000000000048', '01JCQM3C0000000000000013', '01JCQM2B0000000000000008', 'Family home highlights', 'Emphasize family-friendly features in marketing', 'MARKETING', 'DONE', 65, 'MARKETING', '01JCQM1A0000000000000007', NOW() - INTERVAL '12 days', NOW() - INTERVAL '19 days', NOW() - INTERVAL '12 days', NOW() - INTERVAL '19 days', NOW() - INTERVAL '12 days', '{"features": ["schools", "parks", "safety"]}', '{"completed": "Full family package"}'),
('01JCQM4D0000000000000049', '01JCQM3C0000000000000021', '01JCQM2B0000000000000005', 'Estate video walkthrough', 'Create cinematic video tour of luxury estate', 'MARKETING', 'DONE', 100, 'MARKETING', '01JCQM1A0000000000000006', NOW() - INTERVAL '9 days', NOW() - INTERVAL '32 days', NOW() - INTERVAL '9 days', NOW() - INTERVAL '33 days', NOW() - INTERVAL '9 days', '{"video_length": "3-5min", "style": "cinematic"}', '{"youtube_url": "https://youtube.com/watch?v=example", "vimeo_url": "https://vimeo.com/example"}'),
('01JCQM4D0000000000000050', '01JCQM3C0000000000000010', '01JCQM2B0000000000000007', 'Hayes Valley lifestyle content', 'Create neighborhood lifestyle guide for buyers', 'MARKETING', 'OPEN', 50, 'MARKETING', NULL, NOW() + INTERVAL '8 days', NULL, NULL, NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days', '{"content_type": "lifestyle_guide", "neighborhood": "Hayes_Valley"}', '{}');

COMMIT;
-- Operations Center Test Seed Data - Part 2
-- Agent Tasks, Listing Acknowledgments, and Slack Messages
-- Run this AFTER 001_seed_test_data.sql

BEGIN;

-- ============================================================================
-- AGENT_TASKS (25 standalone realtor tasks)
-- ============================================================================
INSERT INTO public.agent_tasks (task_id, realtor_id, task_key, name, description, task_category, status, priority, assigned_staff_id, due_date, claimed_at, completed_at, created_at, updated_at, inputs, outputs) VALUES
-- Active realtor ongoing tasks
('01JCQM5E0000000000000001', '01JCQM2B0000000000000001', 'crm_update_q4', 'Update CRM with Q4 contacts', 'Import and verify all Q4 client contact information into CRM system', 'ADMIN', 'OPEN', 75, NULL, NOW() + INTERVAL '5 days', NULL, NULL, NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days', '{"quarter": "Q4", "contact_count": "~150"}', '{}'),
('01JCQM5E0000000000000002', '01JCQM2B0000000000000001', 'marketing_materials', 'Refresh marketing materials', 'Update personal branding materials with new headshots and bio', 'MARKETING', 'CLAIMED', 60, '01JCQM1A0000000000000007', NOW() + INTERVAL '10 days', NOW() - INTERVAL '2 days', NULL, NOW() - INTERVAL '7 days', NOW() - INTERVAL '1 day', '{"materials": ["headshots", "bio", "brochure"]}', '{"headshots": "delivered"}'),
('01JCQM5E0000000000000003', '01JCQM2B0000000000000001', 'broker_license_renewal', 'Renew broker license', 'Complete continuing education and submit renewal application', 'ADMIN', 'IN_PROGRESS', 90, '01JCQM1A0000000000000003', NOW() + INTERVAL '15 days', NOW() - INTERVAL '5 days', NULL, NOW() - INTERVAL '10 days', NOW() - INTERVAL '2 hours', '{"ce_hours": 45, "deadline": "30_days"}', '{"ce_hours_completed": 30}'),

('01JCQM5E0000000000000004', '01JCQM2B0000000000000002', 'website_update_2025', 'Update agent website for 2025', 'Refresh website content, testimonials, and recent sales', 'MARKETING', 'OPEN', 55, NULL, NOW() + INTERVAL '20 days', NULL, NULL, NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days', '{"pages": ["home", "about", "testimonials", "sales"]}', '{}'),
('01JCQM5E0000000000000005', '01JCQM2B0000000000000002', 'client_appreciation_event', 'Plan client appreciation event', 'Organize Q1 client appreciation event - venue, catering, invites', 'ADMIN', 'CLAIMED', 70, '01JCQM1A0000000000000004', NOW() + INTERVAL '30 days', NOW() - INTERVAL '1 day', NULL, NOW() - INTERVAL '4 days', NOW() - INTERVAL '6 hours', '{"guest_count": "~80", "budget": "$5000"}', '{"venue": "researching"}'),

('01JCQM5E0000000000000006', '01JCQM2B0000000000000003', 'commercial_portfolio_update', 'Update commercial property portfolio', 'Compile recent commercial sales and leases for portfolio', 'MARKETING', 'OPEN', 65, NULL, NOW() + INTERVAL '12 days', NULL, NULL, NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day', '{"properties": 8, "format": "PDF"}', '{}'),
('01JCQM5E0000000000000007', '01JCQM2B0000000000000003', 'costar_profile_update', 'Update CoStar profile', 'Refresh commercial broker profile on CoStar platform', 'ADMIN', 'OPEN', 50, NULL, NOW() + INTERVAL '8 days', NULL, NULL, NOW() - INTERVAL '5 hours', NOW() - INTERVAL '5 hours', '{"platform": "CoStar"}', '{}'),

('01JCQM5E0000000000000008', '01JCQM2B0000000000000004', 'luxury_brochure_design', 'Design luxury listing brochure template', 'Create high-end brochure template for luxury listings', 'MARKETING', 'IN_PROGRESS', 80, '01JCQM1A0000000000000006', NOW() + INTERVAL '7 days', NOW() - INTERVAL '8 days', NULL, NOW() - INTERVAL '12 days', NOW() - INTERVAL '3 hours', '{"style": "luxury", "pages": 4}', '{"draft_1": "approved"}'),
('01JCQM5E0000000000000009', '01JCQM2B0000000000000004', 'photography_standards_doc', 'Create photography standards guide', 'Document photography requirements for all luxury listings', 'ADMIN', 'CLAIMED', 70, '01JCQM1A0000000000000006', NOW() + INTERVAL '10 days', NOW() - INTERVAL '3 days', NULL, NOW() - INTERVAL '6 days', NOW() - INTERVAL '1 day', '{"doc_type": "guide", "audience": "photographers"}', '{"outline": "completed"}'),

('01JCQM5E0000000000000010', '01JCQM2B0000000000000005', 'estate_marketing_package', 'Develop estate marketing package', 'Create comprehensive marketing package template for estates', 'MARKETING', 'OPEN', 85, NULL, NOW() + INTERVAL '14 days', NULL, NULL, NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days', '{"includes": ["photography", "video", "print", "digital"]}', '{}'),
('01JCQM5E0000000000000011', '01JCQM2B0000000000000005', 'marin_expansion_plan', 'Marin County expansion plan', 'Research and plan expansion into Marin County market', 'ADMIN', 'IN_PROGRESS', 75, '01JCQM1A0000000000000001', NOW() + INTERVAL '25 days', NOW() - INTERVAL '10 days', NULL, NOW() - INTERVAL '15 days', NOW() - INTERVAL '4 hours', '{"research": ["demographics", "competition", "inventory"]}', '{"demographics": "completed", "competition": "in_progress"}'),

('01JCQM5E0000000000000012', '01JCQM2B0000000000000006', 'soma_market_analysis', 'SoMa condo market analysis', 'Quarterly market analysis for SoMa condo segment', 'ADMIN', 'OPEN', 60, NULL, NOW() + INTERVAL '18 days', NULL, NULL, NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days', '{"quarter": "Q1_2025", "property_type": "condo"}', '{}'),
('01JCQM5E0000000000000013', '01JCQM2B0000000000000006', 'instagram_content_calendar', 'Create Q1 Instagram content calendar', 'Plan Instagram posts for Q1 2025 - listings, market updates, lifestyle', 'MARKETING', 'CLAIMED', 55, '01JCQM1A0000000000000007', NOW() + INTERVAL '8 days', NOW() - INTERVAL '1 day', NULL, NOW() - INTERVAL '4 days', NOW() - INTERVAL '12 hours', '{"posts_per_week": 3, "themes": ["listings", "market", "lifestyle"]}', '{"january": "drafted"}'),

('01JCQM5E0000000000000014', '01JCQM2B0000000000000007', 'tech_client_referral_program', 'Launch tech client referral program', 'Design referral program targeting tech professionals', 'MARKETING', 'OPEN', 70, NULL, NOW() + INTERVAL '22 days', NULL, NULL, NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day', '{"incentive": "TBD", "channels": ["email", "linkedin"]}', '{}'),
('01JCQM5E0000000000000015', '01JCQM2B0000000000000007', 'mountain_view_market_report', 'Mountain View quarterly market report', 'Create Q4 2024 market report for Mountain View area', 'ADMIN', 'CLAIMED', 65, '01JCQM1A0000000000000004', NOW() + INTERVAL '6 days', NOW() - INTERVAL '4 days', NULL, NOW() - INTERVAL '9 days', NOW() - INTERVAL '8 hours', '{"data_sources": ["MLS", "public_records"], "format": "PDF"}', '{"data_collection": "90%"}'),

('01JCQM5E0000000000000016', '01JCQM2B0000000000000008', 'family_homes_guide', 'Berkeley family homes buyer guide', 'Create guide for families relocating to Berkeley', 'MARKETING', 'OPEN', 50, NULL, NOW() + INTERVAL '16 days', NULL, NULL, NOW() - INTERVAL '6 hours', NOW() - INTERVAL '6 hours', '{"topics": ["schools", "parks", "neighborhoods"]}', '{}'),
('01JCQM5E0000000000000017', '01JCQM2B0000000000000008', 'school_district_database', 'Update school district database', 'Update internal database with latest school ratings and boundaries', 'ADMIN', 'OPEN', 45, NULL, NOW() + INTERVAL '12 days', NULL, NULL, NOW() - INTERVAL '3 hours', NOW() - INTERVAL '3 hours', '{"districts": ["BUSD", "Albany", "Piedmont"]}', '{}'),

('01JCQM5E0000000000000018', '01JCQM2B0000000000000009', 'investment_analysis_templates', 'Create investment property analysis templates', 'Excel templates for ROI, cash flow, cap rate analysis', 'ADMIN', 'IN_PROGRESS', 80, '01JCQM1A0000000000000003', NOW() + INTERVAL '9 days', NOW() - INTERVAL '7 days', NULL, NOW() - INTERVAL '11 days', NOW() - INTERVAL '5 hours', '{"templates": ["ROI", "cash_flow", "cap_rate", "1031_exchange"]}', '{"ROI": "completed", "cash_flow": "in_progress"}'),
('01JCQM5E0000000000000019', '01JCQM2B0000000000000009', 'investor_newsletter_q1', 'Q1 investor newsletter', 'Quarterly newsletter for investment property clients', 'MARKETING', 'OPEN', 60, NULL, NOW() + INTERVAL '20 days', NULL, NULL, NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days', '{"topics": ["market_trends", "tax_updates", "opportunities"]}', '{}'),

('01JCQM5E0000000000000020', '01JCQM2B0000000000000010', 'first_time_buyer_workshop', 'Plan first-time buyer workshop', 'Organize educational workshop for first-time buyers', 'ADMIN', 'CLAIMED', 70, '01JCQM1A0000000000000004', NOW() + INTERVAL '28 days', NOW() - INTERVAL '2 days', NULL, NOW() - INTERVAL '5 days', NOW() - INTERVAL '1 day', '{"date": "late_February", "venue": "TBD", "capacity": 50}', '{"topic_outline": "completed"}'),
('01JCQM5E0000000000000021', '01JCQM2B0000000000000010', 'sunset_neighborhood_guide', 'Sunset District neighborhood guide', 'Comprehensive neighborhood guide for Sunset District', 'MARKETING', 'OPEN', 55, NULL, NOW() + INTERVAL '15 days', NULL, NULL, NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day', '{"sections": ["overview", "dining", "schools", "transit", "parks"]}', '{}'),

-- Some completed tasks for historical data
('01JCQM5E0000000000000022', '01JCQM2B0000000000000001', 'annual_review_2024', 'Complete 2024 annual review', 'Year-end performance review and goal setting for 2025', 'ADMIN', 'DONE', 100, '01JCQM1A0000000000000001', NOW() - INTERVAL '20 days', NOW() - INTERVAL '35 days', NOW() - INTERVAL '20 days', NOW() - INTERVAL '40 days', NOW() - INTERVAL '20 days', '{"year": 2024, "includes": ["metrics", "goals", "strategy"]}', '{"2024_sales": "$12.5M", "2025_goal": "$15M"}'),
('01JCQM5E0000000000000023', '01JCQM2B0000000000000004', 'luxury_certification_2024', 'Complete luxury certification course', 'Certified Luxury Home Marketing Specialist course', 'ADMIN', 'DONE', 85, '01JCQM1A0000000000000003', NOW() - INTERVAL '45 days', NOW() - INTERVAL '60 days', NOW() - INTERVAL '45 days', NOW() - INTERVAL '65 days', NOW() - INTERVAL '45 days', '{"course": "CLHMS", "provider": "Institute for Luxury Home Marketing"}', '{"certification": "completed", "cert_number": "CLHMS-2024-5678"}'),
('01JCQM5E0000000000000024', '01JCQM2B0000000000000006', 'holiday_cards_2024', 'Send holiday cards to client database', 'Design and mail holiday cards to all active clients', 'MARKETING', 'DONE', 50, '01JCQM1A0000000000000007', NOW() - INTERVAL '60 days', NOW() - INTERVAL '75 days', NOW() - INTERVAL '60 days', NOW() - INTERVAL '80 days', NOW() - INTERVAL '60 days', '{"client_count": 245, "card_design": "custom"}', '{"mailed": "December 1, 2024"}'),

-- Failed/Cancelled examples
('01JCQM5E0000000000000025', '01JCQM2B0000000000000007', 'video_series_pilot', 'Tech buyer video series pilot', 'Create pilot video for tech buyer education series', 'MARKETING', 'CANCELLED', 40, NULL, NOW() - INTERVAL '10 days', NULL, NULL, NOW() - INTERVAL '30 days', NOW() - INTERVAL '10 days', '{"video_count": 3, "topics": ["financing", "timeline", "contracts"]}', '{"cancellation_reason": "Budget reallocation"}');

-- ============================================================================
-- LISTING_ACKNOWLEDGMENTS (40 records)
-- Track which staff have claimed which listings
-- ============================================================================
INSERT INTO public.listing_acknowledgments (id, listing_id, staff_id, acknowledged_at, acknowledged_from) VALUES
-- Sarah (admin) has acknowledged many listings
('ack_01_sarah_listing05', '01JCQM3C0000000000000005', '01JCQM1A0000000000000001', NOW() - INTERVAL '9 days', 'web'),
('ack_02_sarah_listing06', '01JCQM3C0000000000000006', '01JCQM1A0000000000000001', NOW() - INTERVAL '7 days', 'web'),
('ack_03_sarah_listing11', '01JCQM3C0000000000000011', '01JCQM1A0000000000000001', NOW() - INTERVAL '24 days', 'web'),
('ack_04_sarah_listing12', '01JCQM3C0000000000000012', '01JCQM1A0000000000000001', NOW() - INTERVAL '29 days', 'web'),

-- Michael (admin) oversight on key listings
('ack_05_michael_listing09', '01JCQM3C0000000000000009', '01JCQM1A0000000000000002', NOW() - INTERVAL '17 days', 'web'),
('ack_06_michael_listing24', '01JCQM3C0000000000000024', '01JCQM1A0000000000000002', NOW() - INTERVAL '23 days', 'web'),
('ack_07_michael_listing21', '01JCQM3C0000000000000021', '01JCQM1A0000000000000002', NOW() - INTERVAL '33 days', 'web'),

-- Alex (operations) - assigned listings
('ack_08_alex_listing05', '01JCQM3C0000000000000005', '01JCQM1A0000000000000003', NOW() - INTERVAL '9 days', 'mobile'),
('ack_09_alex_listing10', '01JCQM3C0000000000000010', '01JCQM1A0000000000000003', NOW() - INTERVAL '4 days', 'mobile'),
('ack_10_alex_listing14', '01JCQM3C0000000000000014', '01JCQM1A0000000000000003', NOW() - INTERVAL '21 days', 'mobile'),
('ack_11_alex_listing24', '01JCQM3C0000000000000024', '01JCQM1A0000000000000003', NOW() - INTERVAL '24 days', 'notification'),
('ack_12_alex_listing11', '01JCQM3C0000000000000011', '01JCQM1A0000000000000003', NOW() - INTERVAL '24 days', 'mobile'),

-- Priya (operations) - assigned listings
('ack_13_priya_listing06', '01JCQM3C0000000000000006', '01JCQM1A0000000000000004', NOW() - INTERVAL '7 days', 'mobile'),
('ack_14_priya_listing13', '01JCQM3C0000000000000013', '01JCQM1A0000000000000004', NOW() - INTERVAL '19 days', 'mobile'),
('ack_15_priya_listing18', '01JCQM3C0000000000000018', '01JCQM1A0000000000000004', NOW() - INTERVAL '10 days', 'mobile'),
('ack_16_priya_listing12', '01JCQM3C0000000000000012', '01JCQM1A0000000000000004', NOW() - INTERVAL '29 days', 'notification'),

-- David (operations) - assigned listings
('ack_17_david_listing08', '01JCQM3C0000000000000008', '01JCQM1A0000000000000005', NOW() - INTERVAL '14 days', 'mobile'),
('ack_18_david_listing17', '01JCQM3C0000000000000017', '01JCQM1A0000000000000005', NOW() - INTERVAL '7 days', 'mobile'),
('ack_19_david_listing25', '01JCQM3C0000000000000025', '01JCQM1A0000000000000005', NOW() - INTERVAL '1 day', 'mobile'),
('ack_20_david_listing22', '01JCQM3C0000000000000022', '01JCQM1A0000000000000005', NOW() - INTERVAL '27 days', 'notification'),

-- Emma (marketing) - photo-heavy listings
('ack_21_emma_listing05', '01JCQM3C0000000000000005', '01JCQM1A0000000000000006', NOW() - INTERVAL '9 days', 'mobile'),
('ack_22_emma_listing07', '01JCQM3C0000000000000007', '01JCQM1A0000000000000006', NOW() - INTERVAL '11 days', 'mobile'),
('ack_23_emma_listing11', '01JCQM3C0000000000000011', '01JCQM1A0000000000000006', NOW() - INTERVAL '24 days', 'mobile'),
('ack_24_emma_listing12', '01JCQM3C0000000000000012', '01JCQM1A0000000000000006', NOW() - INTERVAL '29 days', 'mobile'),
('ack_25_emma_listing15', '01JCQM3C0000000000000015', '01JCQM1A0000000000000006', NOW() - INTERVAL '19 days', 'notification'),
('ack_26_emma_listing18', '01JCQM3C0000000000000018', '01JCQM1A0000000000000006', NOW() - INTERVAL '10 days', 'mobile'),
('ack_27_emma_listing21', '01JCQM3C0000000000000021', '01JCQM1A0000000000000006', NOW() - INTERVAL '34 days', 'mobile'),
('ack_28_emma_listing24', '01JCQM3C0000000000000024', '01JCQM1A0000000000000006', NOW() - INTERVAL '24 days', 'mobile'),

-- Jorge (marketing) - content/copy focused
('ack_29_jorge_listing06', '01JCQM3C0000000000000006', '01JCQM1A0000000000000007', NOW() - INTERVAL '7 days', 'mobile'),
('ack_30_jorge_listing09', '01JCQM3C0000000000000009', '01JCQM1A0000000000000007', NOW() - INTERVAL '17 days', 'mobile'),
('ack_31_jorge_listing13', '01JCQM3C0000000000000013', '01JCQM1A0000000000000007', NOW() - INTERVAL '19 days', 'mobile'),
('ack_32_jorge_listing16', '01JCQM3C0000000000000016', '01JCQM1A0000000000000007', NOW() - INTERVAL '6 days', 'notification'),
('ack_33_jorge_listing17', '01JCQM3C0000000000000017', '01JCQM1A0000000000000007', NOW() - INTERVAL '8 days', 'mobile'),
('ack_34_jorge_listing22', '01JCQM3C0000000000000022', '01JCQM1A0000000000000007', NOW() - INTERVAL '27 days', 'mobile'),

-- Lisa (support) - limited acknowledgments (support role)
('ack_35_lisa_listing05', '01JCQM3C0000000000000005', '01JCQM1A0000000000000008', NOW() - INTERVAL '8 days', 'web'),
('ack_36_lisa_listing06', '01JCQM3C0000000000000006', '01JCQM1A0000000000000008', NOW() - INTERVAL '7 days', 'web'),
('ack_37_lisa_listing09', '01JCQM3C0000000000000009', '01JCQM1A0000000000000008', NOW() - INTERVAL '16 days', 'web'),

-- Strategic omissions for Inbox testing:
-- Listings 01, 02, 03, 04 (new) - NOBODY has acknowledged yet (will appear in everyone's Inbox)
-- Listing 19 (new) - Nobody acknowledged (Inbox)
-- Listing 20 (new) - Nobody acknowledged (Inbox)
-- Listing 23 (new) - Nobody acknowledged (Inbox)
-- This creates realistic Inbox distribution

-- Some cross-team acknowledgments
('ack_38_alex_listing07', '01JCQM3C0000000000000007', '01JCQM1A0000000000000003', NOW() - INTERVAL '10 days', 'mobile'),
('ack_39_priya_listing08', '01JCQM3C0000000000000008', '01JCQM1A0000000000000004', NOW() - INTERVAL '13 days', 'mobile'),
('ack_40_david_listing16', '01JCQM3C0000000000000016', '01JCQM1A0000000000000005', NOW() - INTERVAL '5 days', 'notification');

-- ============================================================================
-- SLACK_MESSAGES (15 messages showing classification tracking)
-- ============================================================================
INSERT INTO public.slack_messages (message_id, slack_user_id, slack_channel_id, slack_ts, slack_thread_ts, message_text, classification, message_type, task_key, group_key, confidence, created_listing_id, created_task_id, created_task_type, received_at, processed_at, processing_status, error_message, metadata) VALUES
-- New listing creation messages
('msg_001', 'U02REAL001', 'C01LISTINGS', '1736870400.123456', NULL,
 'New listing at 2847 Pacific Avenue, San Francisco. Luxury Victorian needs full photo package ASAP.',
 '{"intent": "new_listing", "address": "2847 Pacific Avenue, San Francisco, CA 94115", "property_type": "luxury", "urgency": "high"}',
 'new_listing', NULL, 'listings', 0.95, '01JCQM3C0000000000000001', NULL, NULL,
 NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day', 'processed', NULL,
 '{"source": "slack_channel", "priority": "high"}'),

('msg_002', 'U02REAL006', 'C01LISTINGS', '1736784000.234567', NULL,
 'Just got a new rental at 456 Lombard Street. Popular tourist area, need to emphasize location in photos.',
 '{"intent": "new_listing", "address": "456 Lombard Street, San Francisco, CA 94133", "property_type": "rental", "special_note": "location_focused"}',
 'new_listing', NULL, 'listings', 0.92, '01JCQM3C0000000000000002', NULL, NULL,
 NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days', 'processed', NULL,
 '{"source": "slack_channel", "notes": "tourist_area"}'),

-- Task creation messages
('msg_003', 'U02REAL001', 'C01TASKS', '1736524800.345678', NULL,
 'Need to update my CRM with all Q4 contacts before EOY. Can someone help schedule this?',
 '{"intent": "task_request", "task_type": "admin", "deadline": "EOY", "category": "CRM"}',
 'task_request', 'crm_update_q4', 'admin', 0.88, NULL, '01JCQM5E0000000000000001', 'agent_task',
 NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days', 'processed', NULL,
 '{"task_category": "admin", "realtor_id": "01JCQM2B0000000000000001"}'),

('msg_004', 'U02REAL004', 'C01MARKETING', '1735920000.456789', NULL,
 'I need a new luxury brochure template for my high-end listings. Something really premium.',
 '{"intent": "task_request", "task_type": "marketing", "deliverable": "brochure_template", "style": "luxury"}',
 'task_request', 'luxury_brochure_design', 'marketing', 0.90, NULL, '01JCQM5E0000000000000008', 'agent_task',
 NOW() - INTERVAL '12 days', NOW() - INTERVAL '12 days', 'processed', NULL,
 '{"task_category": "marketing", "realtor_id": "01JCQM2B0000000000000004"}'),

-- Listing-specific task messages (threading)
('msg_005', 'U02REAL001', 'C01LISTINGS', '1736352000.567890', '1736870400.123456',
 'For the Pacific Avenue Victorian, we definitely need twilight shots. Schedule photographer ASAP.',
 '{"intent": "task_request", "task_type": "photography", "shot_type": "twilight", "urgency": "high", "listing_id": "01JCQM3C0000000000000001"}',
 'listing_task', NULL, 'photography', 0.93, NULL, '01JCQM4D0000000000000001', 'activity',
 NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day', 'processed', NULL,
 '{"parent_listing": "01JCQM3C0000000000000001", "task_id": "01JCQM4D0000000000000001"}'),

('msg_006', 'U02REAL005', 'C01MARKETING', '1735574400.678901', NULL,
 'The Marina District condo needs a QA check before we publish. Can someone review all materials?',
 '{"intent": "task_request", "task_type": "admin", "deliverable": "qa_review", "listing_address": "Marina District"}',
 'listing_task', NULL, 'quality_assurance', 0.87, NULL, '01JCQM4D0000000000000012', 'activity',
 NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days', 'processed', NULL,
 '{"parent_listing": "01JCQM3C0000000000000009", "assigned_to": "Sarah Chen"}'),

-- Status update messages
('msg_007', 'U01OPS001', 'C01UPDATES', '1736265600.789012', NULL,
 'Photos for 1234 Market Street are done and uploaded. Awaiting client approval.',
 '{"intent": "status_update", "listing": "1234 Market Street", "status": "awaiting_approval", "deliverable": "photos"}',
 'status_update', NULL, 'updates', 0.85, NULL, NULL, NULL,
 NOW() - INTERVAL '2 hours', NOW() - INTERVAL '2 hours', 'processed', NULL,
 '{"listing_id": "01JCQM3C0000000000000005", "staff_id": "01JCQM1A0000000000000003"}'),

('msg_008', 'U01MKT001', 'C01UPDATES', '1736179200.890123', NULL,
 'Final edits for the Divisadero luxury listing are 90% complete. Should be ready by tomorrow.',
 '{"intent": "status_update", "listing": "Divisadero", "progress": "90%", "eta": "tomorrow"}',
 'status_update', NULL, 'updates', 0.82, NULL, NULL, NULL,
 NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day', 'processed', NULL,
 '{"listing_id": "01JCQM3C0000000000000007", "staff_id": "01JCQM1A0000000000000006"}'),

-- Question/clarification messages
('msg_009', 'U02REAL002', 'C01SUPPORT', '1736006400.901234', NULL,
 'Quick question - what's our standard turnaround time for rental photography?',
 '{"intent": "question", "topic": "turnaround_time", "property_type": "rental"}',
 'question', NULL, 'support', 0.78, NULL, NULL, NULL,
 NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days', 'processed', NULL,
 '{"category": "policy_question"}'),

-- Urgent/escalation messages
('msg_010', 'U02REAL004', 'C01URGENT', '1735833600.012345', NULL,
 'URGENT: The Noe Street listing is past due and we still need final edits. Client is asking for updates.',
 '{"intent": "escalation", "urgency": "critical", "listing": "Noe Street", "issue": "overdue"}',
 'escalation', NULL, 'urgent', 0.96, NULL, NULL, NULL,
 NOW() - INTERVAL '6 hours', NOW() - INTERVAL '6 hours', 'processed', NULL,
 '{"listing_id": "01JCQM3C0000000000000015", "escalation_level": "high"}'),

('msg_011', 'U01ADMIN002', 'C01URGENT', '1735747200.123456', NULL,
 'Sacramento Street listing is 3 days overdue. Need immediate status update and completion plan.',
 '{"intent": "escalation", "urgency": "critical", "listing": "Sacramento Street", "days_overdue": 3}',
 'escalation', NULL, 'urgent', 0.94, NULL, NULL, NULL,
 NOW() - INTERVAL '8 hours', NOW() - INTERVAL '8 hours', 'processed', NULL,
 '{"listing_id": "01JCQM3C0000000000000024", "escalated_by": "Michael Rodriguez"}'),

-- General requests
('msg_012', 'U02REAL007', 'C01MARKETING', '1735660800.234567', NULL,
 'I'd like to create a Q1 Instagram content calendar. Can marketing team help with this?',
 '{"intent": "task_request", "task_type": "marketing", "deliverable": "content_calendar", "timeline": "Q1"}',
 'task_request', 'instagram_content_calendar', 'marketing', 0.89, NULL, '01JCQM5E0000000000000013', 'agent_task',
 NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days', 'processed', NULL,
 '{"realtor_id": "01JCQM2B0000000000000007"}'),

-- Pending/unprocessed message (recent)
('msg_013', 'U02REAL010', 'C01LISTINGS', '1736956800.345678', NULL,
 'New listing coming in next week: 3435 Green Street. Will need standard photo package.',
 '{"intent": "new_listing_notice", "address": "3435 Green Street", "timeline": "next_week"}',
 'listing_notice', NULL, 'listings', 0.80, NULL, NULL, NULL,
 NOW() - INTERVAL '2 hours', NULL, 'pending', NULL,
 '{"status": "advance_notice"}'),

-- Failed processing example
('msg_014', 'U02REAL999', 'C01GENERAL', '1736870400.456789', NULL,
 'Hey can someone call me? 555-1234',
 '{"intent": "unknown", "contains_phone": true}',
 'unclassified', NULL, NULL, 0.15, NULL, NULL, NULL,
 NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day', 'skipped', 'Insufficient classification confidence',
 '{"confidence_threshold": 0.70, "actual": 0.15}'),

-- Successfully processed new listing (recent)
('msg_015', 'U02REAL003', 'C01LISTINGS', '1736956800.567890', NULL,
 'Commercial space at 2425 Balboa Street. Need full marketing package including floor plans.',
 '{"intent": "new_listing", "address": "2425 Balboa Street, San Francisco, CA 94121", "property_type": "commercial", "requirements": ["marketing_package", "floor_plans"]}',
 'new_listing', NULL, 'listings', 0.91, '01JCQM3C0000000000000020', NULL, NULL,
 NOW() - INTERVAL '12 hours', NOW() - INTERVAL '12 hours', 'processed', NULL,
 '{"created": "listing", "realtor_id": "01JCQM2B0000000000000003"}');

COMMIT;
