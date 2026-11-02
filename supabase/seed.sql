-- ==============================================================================
-- Pingili Demo Seed Data
-- Creates a sample restaurant business and ready-to-test active tickets
-- ==============================================================================

-- 1. Insert Demo Business (Using a fixed deterministic UUID for easy testing)
INSERT INTO public.businesses (id, name, slug, theme_color, tagline)
VALUES (
    'b1111111-1111-1111-1111-111111111111',
    'Pingili Gourmet Burgers & Shakes',
    'gourmet-burgers',
    '#f97316',
    'Freshly Crafted, Notified Fast'
)
ON CONFLICT (id) DO UPDATE 
SET name = EXCLUDED.name, theme_color = EXCLUDED.theme_color;

-- 2. Insert Sample Tickets for testing
-- Ticket #041 (In Progress)
INSERT INTO public.tickets (
    id,
    business_id,
    short_token,
    sequence_number,
    display_number,
    custom_label,
    status,
    is_connected
)
VALUES (
    't1111111-1111-1111-1111-111111111101',
    'b1111111-1111-1111-1111-111111111111',
    'demo041',
    41,
    '#041',
    'Double Smash + Truffle Fries',
    'in_progress',
    true
)
ON CONFLICT (short_token) DO NOTHING;

-- Ticket #042 (Waiting)
INSERT INTO public.tickets (
    id,
    business_id,
    short_token,
    sequence_number,
    display_number,
    custom_label,
    status,
    is_connected
)
VALUES (
    't1111111-1111-1111-1111-111111111102',
    'b1111111-1111-1111-1111-111111111111',
    'demo042',
    42,
    '#042',
    'Sarah - Vanilla Milkshake',
    'waiting',
    false
)
ON CONFLICT (short_token) DO NOTHING;

-- Ticket #043 (Ready / Buzzed)
INSERT INTO public.tickets (
    id,
    business_id,
    short_token,
    sequence_number,
    display_number,
    custom_label,
    status,
    is_connected,
    notified_at
)
VALUES (
    't1111111-1111-1111-1111-111111111103',
    'b1111111-1111-1111-1111-111111111111',
    'demo043',
    43,
    '#043',
    'Alex - Spicy Chicken Burger',
    'ready',
    true,
    now()
)
ON CONFLICT (short_token) DO NOTHING;
