import { createClient } from '@supabase/supabase-js';
import type { Ticket, Business, TicketStatus } from '../types';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL || '';
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY || '';

export const isLiveSupabaseConfigured = Boolean(
  supabaseUrl && supabaseAnonKey && !supabaseUrl.includes('placeholder')
);

export const supabase = isLiveSupabaseConfigured
  ? createClient(supabaseUrl, supabaseAnonKey)
  : null;

// ============================================================================
// Demo Mock Storage (Active when Supabase credentials are not yet configured)
// Allows instant 100% functional local testing out of the box!
// ============================================================================

const DEMO_BUSINESS: Business = {
  id: 'b1111111-1111-1111-1111-111111111111',
  name: 'Pingili Burger Bar',
  slug: 'burger-bar',
  theme_color: '#f97316',
  tagline: 'Freshly Crafted, Notified Fast'
};

const mockTickets: Record<string, Ticket> = {
  demo041: {
    id: 't-041',
    business_id: DEMO_BUSINESS.id,
    short_token: 'demo041',
    sequence_number: 41,
    display_number: '#041',
    custom_label: 'Double Smash + Truffle Fries',
    status: 'in_progress',
    is_connected: true,
    created_at: new Date(Date.now() - 1000 * 60 * 12).toISOString(),
    business: DEMO_BUSINESS
  },
  demo042: {
    id: 't-042',
    business_id: DEMO_BUSINESS.id,
    short_token: 'demo042',
    sequence_number: 42,
    display_number: '#042',
    custom_label: 'Sarah - Vanilla Milkshake',
    status: 'waiting',
    is_connected: false,
    created_at: new Date(Date.now() - 1000 * 60 * 5).toISOString(),
    business: DEMO_BUSINESS
  },
  demo043: {
    id: 't-043',
    business_id: DEMO_BUSINESS.id,
    short_token: 'demo043',
    sequence_number: 43,
    display_number: '#043',
    custom_label: 'Alex - Spicy Chicken Burger',
    status: 'ready',
    is_connected: true,
    created_at: new Date(Date.now() - 1000 * 60 * 18).toISOString(),
    notified_at: new Date().toISOString(),
    business: DEMO_BUSINESS
  }
};

const mockListeners = new Set<(ticket: Ticket) => void>();

export function getClientSessionId(): string {
  let sessionId = localStorage.getItem('pingili_client_session_id');
  if (!sessionId) {
    sessionId = 'client_' + Math.random().toString(36).substring(2, 11);
    localStorage.setItem('pingili_client_session_id', sessionId);
  }
  return sessionId;
}

export async function fetchTicketByToken(token: string): Promise<Ticket | null> {
  if (isLiveSupabaseConfigured && supabase) {
    try {
      const { data, error } = await supabase
        .from('tickets')
        .select('*, business:businesses(*)')
        .eq('short_token', token)
        .maybeSingle();

      if (error) throw error;
      return (data as unknown as Ticket) || null;
    } catch (err) {
      console.error('[Supabase] Failed to fetch ticket:', err);
      return null;
    }
  }

  // Fallback to local mock data
  const t = mockTickets[token.toLowerCase()];
  if (t) return { ...t };

  // If token is unknown in mock mode, synthesize a dynamic ticket for easy testing
  return {
    id: 'mock-' + token,
    business_id: DEMO_BUSINESS.id,
    short_token: token,
    sequence_number: 99,
    display_number: '#' + token.toUpperCase().substring(0, 4),
    custom_label: 'Customer Order',
    status: 'waiting',
    is_connected: false,
    created_at: new Date().toISOString(),
    business: DEMO_BUSINESS
  };
}

export async function sendHeartbeat(token: string): Promise<void> {
  const sessionId = getClientSessionId();

  if (isLiveSupabaseConfigured && supabase) {
    await supabase.rpc('heartbeat_ticket', {
      p_short_token: token,
      p_client_session_id: sessionId
    });
    return;
  }

  if (mockTickets[token]) {
    mockTickets[token].is_connected = true;
    mockTickets[token].client_session_id = sessionId;
  }
}

export async function acknowledgeTicket(token: string): Promise<void> {
  const sessionId = getClientSessionId();

  if (isLiveSupabaseConfigured && supabase) {
    await supabase.rpc('acknowledge_ticket', {
      p_short_token: token,
      p_client_session_id: sessionId
    });
    return;
  }

  if (mockTickets[token]) {
    mockTickets[token].acknowledged_at = new Date().toISOString();
    mockTickets[token].is_connected = true;
    mockListeners.forEach(listener => listener({ ...mockTickets[token] }));
  }
}

export function subscribeToTicket(
  token: string,
  onUpdate: (ticket: Ticket) => void
): () => void {
  if (isLiveSupabaseConfigured && supabase) {
    const channel = supabase
      .channel(`ticket_${token}`)
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'tickets',
          filter: `short_token=eq.${token}`
        },
        async () => {
          const fresh = await fetchTicketByToken(token);
          if (fresh) onUpdate(fresh);
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }

  // Mock subscription with cross-tab / local event dispatcher
  mockListeners.add(onUpdate);
  return () => {
    mockListeners.delete(onUpdate);
  };
}

// Dev helper: trigger simulated state transition for mock testing
export function devSimulateStatus(token: string, newStatus: TicketStatus): void {
  if (mockTickets[token]) {
    mockTickets[token].status = newStatus;
    if (newStatus === 'ready') mockTickets[token].notified_at = new Date().toISOString();
    if (newStatus === 'completed') mockTickets[token].completed_at = new Date().toISOString();
    mockListeners.forEach(listener => listener({ ...mockTickets[token] }));
  }
}
