-- ==============================================================================
-- Pingili Passive Counter QR & Returning Device Recognition
-- ==============================================================================

-- 1. Client Devices Table (Tracks returning customers per business)
CREATE TABLE IF NOT EXISTS public.client_devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
    client_session_id TEXT NOT NULL,
    visit_count INT NOT NULL DEFAULT 1,
    last_seen_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT unique_business_device UNIQUE (business_id, client_session_id)
);

-- 2. Pairing Sessions Table (Live 4-digit check-in codes)
CREATE TABLE IF NOT EXISTS public.pairing_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
    pairing_code VARCHAR(4) NOT NULL,
    client_session_id TEXT NOT NULL,
    visit_count INT NOT NULL DEFAULT 1,
    status VARCHAR(20) NOT NULL DEFAULT 'waiting_pair',
    ticket_id UUID REFERENCES public.tickets(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT check_pairing_status CHECK (status IN ('waiting_pair', 'paired', 'expired'))
);

CREATE INDEX IF NOT EXISTS idx_pairing_business_status ON public.pairing_sessions(business_id, status);

-- ==============================================================================
-- RPC: Customer scans passive counter QR (/b/{slug})
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.request_pairing(
    p_business_slug TEXT,
    p_client_session_id TEXT
)
RETURNS public.pairing_sessions
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_business_id UUID;
    v_visit_count INT;
    v_code VARCHAR(4);
    v_session public.pairing_sessions;
BEGIN
    SELECT id INTO v_business_id FROM public.businesses WHERE slug = p_business_slug LIMIT 1;
    IF v_business_id IS NULL THEN
        RAISE EXCEPTION 'Business not found';
    END IF;

    -- Track returning device
    INSERT INTO public.client_devices (business_id, client_session_id, visit_count, last_seen_at)
    VALUES (v_business_id, p_client_session_id, 1, now())
    ON CONFLICT (business_id, client_session_id)
    DO UPDATE SET
        visit_count = public.client_devices.visit_count + 1,
        last_seen_at = now()
    RETURNING visit_count INTO v_visit_count;

    -- Generate 4-digit pairing code (1000-9999)
    v_code := lpad((floor(random() * 9000) + 1000)::int::text, 4, '0');

    INSERT INTO public.pairing_sessions (
        business_id,
        pairing_code,
        client_session_id,
        visit_count,
        status
    )
    VALUES (
        v_business_id,
        v_code,
        p_client_session_id,
        v_visit_count,
        'waiting_pair'
    )
    RETURNING * INTO v_session;

    RETURN v_session;
END;
$$;

-- ==============================================================================
-- RPC: Cashier taps 4-digit code to pair & create ticket in 1 tap
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.pair_session_to_ticket(
    p_pairing_id UUID,
    p_custom_label TEXT DEFAULT NULL
)
RETURNS public.tickets
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_pairing public.pairing_sessions;
    v_ticket public.tickets;
BEGIN
    SELECT * INTO v_pairing FROM public.pairing_sessions WHERE id = p_pairing_id FOR UPDATE;
    IF v_pairing IS NULL THEN
        RAISE EXCEPTION 'Pairing session not found';
    END IF;

    -- Create daily ticket
    SELECT * INTO v_ticket FROM public.create_daily_ticket(v_pairing.business_id, p_custom_label);

    -- Link client session immediately as connected
    UPDATE public.tickets
    SET
        client_session_id = v_pairing.client_session_id,
        is_connected = true
    WHERE id = v_ticket.id
    RETURNING * INTO v_ticket;

    -- Mark pairing session as paired
    UPDATE public.pairing_sessions
    SET
        status = 'paired',
        ticket_id = v_ticket.id
    WHERE id = p_pairing_id;

    RETURN v_ticket;
END;
$$;

-- RLS Policies
ALTER TABLE public.client_devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pairing_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can view pairing sessions"
    ON public.pairing_sessions FOR SELECT
    USING (true);

CREATE POLICY "Business owners manage pairing sessions"
    ON public.pairing_sessions FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.businesses
            WHERE public.businesses.id = public.pairing_sessions.business_id
              AND (public.businesses.owner_id = auth.uid() OR auth.role() = 'service_role')
        )
    );

-- Enable Realtime on pairing_sessions
ALTER PUBLICATION supabase_realtime ADD TABLE public.pairing_sessions;
