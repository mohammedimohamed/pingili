export type TicketStatus = 'waiting' | 'in_progress' | 'ready' | 'completed' | 'cancelled';

export interface Business {
  id: string;
  name: string;
  slug: string;
  logo_url?: string | null;
  theme_color?: string | null;
  tagline?: string | null;
}

export interface Ticket {
  id: string;
  business_id: string;
  short_token: string;
  sequence_number: number;
  display_number: string;
  custom_label?: string | null;
  status: TicketStatus;
  client_session_id?: string | null;
  is_connected: boolean;
  created_at: string;
  notified_at?: string | null;
  acknowledged_at?: string | null;
  completed_at?: string | null;
  business?: Business;
}
