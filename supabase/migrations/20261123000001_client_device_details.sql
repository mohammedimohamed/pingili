-- ==============================================================================
-- Client Device Details & Soft Fingerprint Fallback
-- ==============================================================================

ALTER TABLE public.client_devices
    ADD COLUMN IF NOT EXISTS device_fingerprint TEXT,
    ADD COLUMN IF NOT EXISTS device_meta JSONB;

CREATE INDEX IF NOT EXISTS idx_client_devices_fingerprint
    ON public.client_devices(business_id, device_fingerprint);

-- Drop the old 2-argument signature to avoid Postgres function overloading ambiguity
DROP FUNCTION IF EXISTS public.request_pairing(TEXT, TEXT);

-- Update request_pairing to accept device_fingerprint & device_meta
CREATE OR REPLACE FUNCTION public.request_pairing(
    p_business_slug TEXT,
    p_client_session_id TEXT,
    p_device_fingerprint TEXT DEFAULT NULL,
    p_device_meta JSONB DEFAULT NULL
)
RETURNS public.pairing_sessions
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_business_id UUID;
    v_visit_count INT;
    v_existing_id UUID;
    v_code VARCHAR(4);
    v_session public.pairing_sessions;
BEGIN
    SELECT id INTO v_business_id FROM public.businesses WHERE slug = p_business_slug LIMIT 1;
    IF v_business_id IS NULL THEN
        RAISE EXCEPTION 'Business not found';
    END IF;

    -- 1. Try exact match by client_session_id
    SELECT id, visit_count INTO v_existing_id, v_visit_count
    FROM public.client_devices
    WHERE business_id = v_business_id AND client_session_id = p_client_session_id
    LIMIT 1;

    -- 2. Fallback: if storage was cleared, try matching by device_fingerprint
    IF v_existing_id IS NULL AND p_device_fingerprint IS NOT NULL THEN
        SELECT id, visit_count INTO v_existing_id, v_visit_count
        FROM public.client_devices
        WHERE business_id = v_business_id AND device_fingerprint = p_device_fingerprint
        ORDER BY last_seen_at DESC
        LIMIT 1;
    END IF;

    IF v_existing_id IS NOT NULL THEN
        v_visit_count := v_visit_count + 1;
        UPDATE public.client_devices
        SET
            client_session_id = p_client_session_id,
            visit_count = v_visit_count,
            device_fingerprint = COALESCE(p_device_fingerprint, device_fingerprint),
            device_meta = COALESCE(p_device_meta, device_meta),
            last_seen_at = now()
        WHERE id = v_existing_id;
    ELSE
        v_visit_count := 1;
        INSERT INTO public.client_devices (
            business_id,
            client_session_id,
            device_fingerprint,
            device_meta,
            visit_count,
            last_seen_at
        )
        VALUES (
            v_business_id,
            p_client_session_id,
            p_device_fingerprint,
            p_device_meta,
            1,
            now()
        );
    END IF;

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
