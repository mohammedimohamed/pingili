import { useState, useEffect, useCallback } from 'react';
import type { Ticket, PairingSession } from './types';
import {
  fetchTicketByToken,
  subscribeToTicket,
  sendHeartbeat,
  acknowledgeTicket,
  getClientSessionId,
  requestPairing,
  subscribeToPairing
} from './lib/supabase';
import { audioBuzzer } from './lib/audioBuzzer';
import { wakeLockService } from './lib/wakeLock';
import { PagerView } from './components/PagerView';
import { PairingWaitView } from './components/PairingWaitView';
import { BuzzAlertModal } from './components/BuzzAlertModal';
import { ActivateBuzzerPrompt } from './components/ActivateBuzzerPrompt';
import { Loader2, AlertCircle } from 'lucide-react';

function parseRoute(): { mode: 'ticket'; token: string } | { mode: 'business'; slug: string } {
  const path = window.location.pathname;
  const bizMatch = path.match(/\/b\/([a-zA-Z0-9_-]+)/);
  if (bizMatch && bizMatch[1]) {
    return { mode: 'business', slug: bizMatch[1] };
  }

  const ticketMatch = path.match(/\/t\/([a-zA-Z0-9_-]+)/);
  if (ticketMatch && ticketMatch[1]) {
    return { mode: 'ticket', token: ticketMatch[1] };
  }

  const params = new URLSearchParams(window.location.search);
  if (params.get('b')) return { mode: 'business', slug: params.get('b')! };
  if (params.get('t')) return { mode: 'ticket', token: params.get('t')! };

  return { mode: 'ticket', token: 'demo041' };
}

export function App() {
  const [route] = useState(parseRoute);
  const [token, setToken] = useState<string | null>(route.mode === 'ticket' ? route.token : null);
  const [pairingSession, setPairingSession] = useState<PairingSession | null>(null);
  const [ticket, setTicket] = useState<Ticket | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [audioUnlocked, setAudioUnlocked] = useState(false);
  const [showPrompt, setShowPrompt] = useState(true);
  const [wakeLockActive, setWakeLockActive] = useState(false);

  // Passive Counter QR Flow (/b/:slug)
  useEffect(() => {
    if (route.mode !== 'business' || token) return;

    let unsubscribe: (() => void) | undefined;

    (async () => {
      try {
        setLoading(true);
        setError(null);
        const session = await requestPairing(route.slug);
        setPairingSession(session);
        unsubscribe = subscribeToPairing(session.id, (pairedTicket) => {
          setPairingSession(null);
          setTicket(pairedTicket);
          setToken(pairedTicket.short_token);
          window.history.replaceState({}, '', `/t/${pairedTicket.short_token}`);
        });
      } catch {
        setError(`Business "${route.slug}" was not found.`);
      } finally {
        setLoading(false);
      }
    })();

    return () => {
      if (unsubscribe) unsubscribe();
    };
  }, [route, token]);

  // Direct Ticket Flow (/t/:token)
  const loadTicket = useCallback(async (activeToken: string) => {
    try {
      setLoading(true);
      setError(null);
      const data = await fetchTicketByToken(activeToken);
      if (!data) {
        setError(`Ticket "${activeToken}" was not found or has expired.`);
      } else {
        setTicket(data);
        await sendHeartbeat(activeToken);
      }
    } catch {
      setError('Unable to load ticket. Please check your connection.');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    if (!token) return;

    loadTicket(token);
    const unsubscribe = subscribeToTicket(token, (updatedTicket) => {
      setTicket(updatedTicket);
    });

    const heartbeatInterval = setInterval(() => {
      sendHeartbeat(token);
    }, 25000);

    return () => {
      unsubscribe();
      clearInterval(heartbeatInterval);
      audioBuzzer.stopBuzzer();
      wakeLockService.release();
    };
  }, [token, loadTicket]);

  // Audio & Alarm Trigger effect
  useEffect(() => {
    if (!ticket) return;

    const isReady = ticket.status === 'ready';
    const isAcknowledged = Boolean(ticket.acknowledged_at);

    if (isReady && !isAcknowledged && audioUnlocked) {
      audioBuzzer.startBuzzer();
    } else {
      audioBuzzer.stopBuzzer();
    }
  }, [ticket, audioUnlocked]);

  const handleBeeperActivated = () => {
    setAudioUnlocked(true);
    setShowPrompt(false);
    setWakeLockActive(wakeLockService.active);
  };

  const handleAcknowledge = async () => {
    if (!ticket) return;
    audioBuzzer.stopBuzzer();
    await acknowledgeTicket(ticket.short_token);
    setTicket(prev => prev ? {
      ...prev,
      acknowledged_at: new Date().toISOString()
    } : null);
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-slate-950 flex flex-col items-center justify-center p-4 text-white">
        <Loader2 className="w-10 h-10 text-amber-500 animate-spin mb-4" />
        <p className="text-sm text-slate-400 font-mono">Loading digital pager...</p>
      </div>
    );
  }

  if (error || (!ticket && !pairingSession)) {
    return (
      <div className="min-h-screen bg-slate-950 flex flex-col items-center justify-center p-6 text-white text-center">
        <div className="w-16 h-16 bg-red-500/10 border border-red-500/20 text-red-400 rounded-3xl flex items-center justify-center mb-4">
          <AlertCircle className="w-8 h-8" />
        </div>
        <h1 className="text-xl font-bold mb-2">Not Found</h1>
        <p className="text-slate-400 text-sm max-w-sm mb-6">{error}</p>
        <div className="flex gap-3">
          <a href="/b/burger-bar" className="px-4 py-2 bg-amber-500 hover:bg-amber-400 text-slate-950 rounded-xl text-xs font-bold">
            Try Counter QR (/b/burger-bar)
          </a>
          <a href="/t/demo041" className="px-4 py-2 bg-slate-800 hover:bg-slate-700 rounded-xl text-xs font-semibold">
            Load Demo #041
          </a>
        </div>
      </div>
    );
  }

  const brandColor = ticket?.business?.theme_color || pairingSession?.business?.theme_color || '#f97316';
  const isBuzzerFiring = ticket?.status === 'ready';

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 flex flex-col justify-between selection:bg-amber-500 selection:text-black">
      {showPrompt && !audioUnlocked && (
        <ActivateBuzzerPrompt
          brandColor={brandColor}
          onActivated={handleBeeperActivated}
        />
      )}

      <main className="flex-1 flex flex-col justify-center items-center py-6">
        {pairingSession && !ticket ? (
          <PairingWaitView session={pairingSession} />
        ) : ticket ? (
          <PagerView
            ticket={ticket}
            audioUnlocked={audioUnlocked}
            wakeLockActive={wakeLockActive}
            onActivateAudio={() => setShowPrompt(true)}
          />
        ) : null}
      </main>

      {isBuzzerFiring && ticket && (
        <BuzzAlertModal
          displayNumber={ticket.display_number}
          customLabel={ticket.custom_label}
          brandColor={brandColor}
          isAcknowledged={Boolean(ticket.acknowledged_at)}
          onAcknowledge={handleAcknowledge}
        />
      )}

      <footer className="py-4 text-center text-xs text-slate-600 font-mono">
        Pingili Universal Digital Pager • Session {getClientSessionId().substring(0, 8)}
      </footer>
    </div>
  );
}

export default App;
