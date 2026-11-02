-- ==============================================================================
-- Pingili Phase 1 MVP Database Schema
-- Multi-Tenant Businesses, Daily Atomic Counters, Realtime Tickets & RLS
-- ==============================================================================

-- 1. Businesses Table
CREATE TABLE IF NOT EXISTS public.businesses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    logo_url TEXT,
    theme_color VARCHAR(10) DEFAULT '#0284c7',
    tagline VARCHAR(255) DEFAULT 'Order Ready Notification',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2. Daily Counters Table (Atomic reset per business & day)
CREATE TABLE IF NOT EXISTS public.daily_counters (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
    counter_date DATE NOT NULL DEFAULT CURRENT_DATE,
    last_number INT NOT NULL DEFAULT 0,
    CONSTRAINT unique_business_counter_per_day UNIQUE (business_id, counter_date)
);

-- 3. Tickets Table
CREATE TABLE IF NOT EXISTS public.tickets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
    short_token VARCHAR(16) UNIQUE NOT NULL,
    sequence_number INT NOT NULL,
    display_number VARCHAR(16) NOT NULL,
    custom_label VARCHAR(100),
    status VARCHAR(20) NOT NULL DEFAULT 'waiting',
    client_session_id TEXT,
    is_connected BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    notified_at TIMESTAMPTZ,
    acknowledged_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    CONSTRAINT check_ticket_status CHECK (status IN ('waiting', 'in_progress', 'ready', 'completed', 'cancelled'))
);

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_tickets_business_status ON public.tickets(business_id, status);
CREATE INDEX IF NOT EXISTS idx_tickets_short_token ON public.tickets(short_token);
CREATE INDEX IF NOT EXISTS idx_tickets_created_at ON public.tickets(created_at DESC);

-- ==============================================================================
-- Stored Procedures & Atomic Functions
-- ==============================================================================

-- Atomic Daily Ticket Creation
CREATE OR REPLACE FUNCTION public.create_daily_ticket(
    p_business_id UUID,
    p_custom_label TEXT DEFAULT NULL
)
RETURNS public.tickets
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_next_num INT;
    v_token VARCHAR(16);
    v_ticket public.tickets;
BEGIN
    -- Atomic upsert for today's counter
    INSERT INTO public.daily_counters (business_id, counter_date, last_number)
    VALUES (p_business_id, CURRENT_DATE, 1)
    ON CONFLICT (business_id, counter_date)
    DO UPDATE SET last_number = public.daily_counters.last_number + 1
    RETURNING last_number INTO v_next_num;

    -- Generate random 7-character lowercase URL-safe token
    v_token := lower(substr(md5(random()::text || clock_timestamp()::text), 1, 7));

    -- Insert new ticket
    INSERT INTO public.tickets (
        business_id,
        short_token,
        sequence_number,
        display_number,
        custom_label,
        status,
        is_connected
    )
    VALUES (
        p_business_id,
        v_token,
        v_next_num,
        '#' || lpad(v_next_num::text, 3, '0'),
        p_custom_label,
        'waiting',
        false
    )
    RETURNING * INTO v_ticket;

    RETURN v_ticket;
END;
$$;

-- Heartbeat & Scan Registration (Public accessible via short_token)
CREATE OR REPLACE FUNCTION public.heartbeat_ticket(
    p_short_token TEXT,
    p_client_session_id TEXT DEFAULT NULL
)
RETURNS public.tickets
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_ticket public.tickets;
BEGIN
    UPDATE public.tickets
    SET 
        is_connected = true,
        client_session_id = COALESCE(p_client_session_id, client_session_id)
    WHERE short_token = p_short_token
    RETURNING * INTO v_ticket;

    RETURN v_ticket;
END;
$$;

-- Acknowledge Ticket ("Got it / Coming!")
CREATE OR REPLACE FUNCTION public.acknowledge_ticket(
    p_short_token TEXT,
    p_client_session_id TEXT DEFAULT NULL
)
RETURNS public.tickets
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_ticket public.tickets;
BEGIN
    UPDATE public.tickets
    SET 
        acknowledged_at = now(),
        is_connected = true,
        client_session_id = COALESCE(p_client_session_id, client_session_id)
    WHERE short_token = p_short_token
    RETURNING * INTO v_ticket;

    RETURN v_ticket;
END;
$$;

-- Update Ticket Status by Business
CREATE OR REPLACE FUNCTION public.update_ticket_status(
    p_ticket_id UUID,
    p_new_status VARCHAR(20)
)
RETURNS public.tickets
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_ticket public.tickets;
BEGIN
    UPDATE public.tickets
    SET 
        status = p_new_status,
        notified_at = CASE WHEN p_new_status = 'ready' AND notified_at IS NULL THEN now() ELSE notified_at END,
        completed_at = CASE WHEN p_new_status = 'completed' AND completed_at IS NULL THEN now() ELSE completed_at END
    WHERE id = p_ticket_id
    RETURNING * INTO v_ticket;

    RETURN v_ticket;
END;
$$;

-- ==============================================================================
-- Row-Level Security (RLS) Policies
-- ==============================================================================

ALTER TABLE public.businesses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_counters ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tickets ENABLE ROW LEVEL SECURITY;

-- Businesses: Public read-only for customer branding
CREATE POLICY "Public businesses can be viewed by anyone"
    ON public.businesses FOR SELECT
    USING (true);

-- Businesses: Authenticated owners can manage their own profile
CREATE POLICY "Owners can manage their business profile"
    ON public.businesses FOR ALL
    USING (auth.uid() = owner_id)
    WITH CHECK (auth.uid() = owner_id);

-- Tickets: Public read by short_token
CREATE POLICY "Public can view tickets by short_token"
    ON public.tickets FOR SELECT
    USING (true);

-- Tickets: Authenticated business owners have full CRUD on their tickets
CREATE POLICY "Business owners have full access to their tickets"
    ON public.tickets FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.businesses
            WHERE public.businesses.id = public.tickets.business_id
              AND (public.businesses.owner_id = auth.uid() OR auth.role() = 'service_role')
        )
    );

-- Enable Supabase Realtime publication on tickets
ALTER PUBLICATION supabase_realtime ADD TABLE public.tickets;
