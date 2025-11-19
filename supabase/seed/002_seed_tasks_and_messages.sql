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
