import { useState, useEffect, useCallback } from 'react';
import type { Ticket } from './types';
import { 
  fetchTicketByToken, 
  subscribeToTicket, 
  sendHeartbeat, 
  acknowledgeTicket,
  getClientSessionId
} from './lib/supabase';
import { audioBuzzer } from './lib/audioBuzzer';
import { wakeLockService } from './lib/wakeLock';
import { PagerView } from './components/PagerView';
import { BuzzAlertModal } from './components/BuzzAlertModal';
import { ActivateBuzzerPrompt } from './components/ActivateBuzzerPrompt';
import { Loader2, AlertCircle } from 'lucide-react';

export function App() {
  // Extract token from pathname /t/{token} or fallback to 'demo041'
  const getTokenFromUrl = (): string => {
    const path = window.location.pathname;
    const match = path.match(/\/t\/([a-zA-Z0-9_-]+)/);
    if (match && match[1]) return match[1];

    // Check query param ?t=xxx
    const params = new URLSearchParams(window.location.search);
    const paramToken = params.get('t');
    if (paramToken) return paramToken;

    return 'demo041';
  };

  const [token] = useState<string>(getTokenFromUrl);
  const [ticket, setTicket] = useState<Ticket | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [audioUnlocked, setAudioUnlocked] = useState(false);
  const [showPrompt, setShowPrompt] = useState(true);
  const [wakeLockActive, setWakeLockActive] = useState(false);

  // Load ticket
  const loadTicket = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await fetchTicketByToken(token);
      if (!data) {
        setError(`Ticket "${token}" was not found or has expired.`);
      } else {
        setTicket(data);
        // Register heartbeat / presence
        await sendHeartbeat(token);
      }
    } catch {
      setError('Unable to load ticket. Please check your connection.');
    } finally {
      setLoading(false);
    }
  }, [token]);

  useEffect(() => {
    loadTicket();

    // Subscribe to real-time updates
    const unsubscribe = subscribeToTicket(token, (updatedTicket) => {
      setTicket(updatedTicket);
    });

    // Send periodic presence heartbeat every 25 seconds
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
    // Optimistic update
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

  if (error || !ticket) {
    return (
      <div className="min-h-screen bg-slate-950 flex flex-col items-center justify-center p-6 text-white text-center">
        <div className="w-16 h-16 bg-red-500/10 border border-red-500/20 text-red-400 rounded-3xl flex items-center justify-center mb-4">
          <AlertCircle className="w-8 h-8" />
        </div>
        <h1 className="text-xl font-bold mb-2">Ticket Not Found</h1>
        <p className="text-slate-400 text-sm max-w-sm mb-6">{error}</p>
        <div className="flex gap-3">
          <a 
            href="/t/demo041" 
            className="px-4 py-2 bg-slate-800 hover:bg-slate-700 rounded-xl text-xs font-semibold"
          >
            Load Demo #041
          </a>
          <a 
            href="/t/demo043" 
            className="px-4 py-2 bg-amber-500 hover:bg-amber-400 text-slate-950 rounded-xl text-xs font-bold"
          >
            Load Ready #043
          </a>
        </div>
      </div>
    );
  }

  const isBuzzerFiring = ticket.status === 'ready';

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 flex flex-col justify-between selection:bg-amber-500 selection:text-black">
      {/* First-visit Gesture Unlock Modal */}
      {showPrompt && !audioUnlocked && (
        <ActivateBuzzerPrompt
          brandColor={ticket.business?.theme_color || '#f97316'}
          onActivated={handleBeeperActivated}
        />
      )}

      {/* Main Pager Screen */}
      <main className="flex-1 flex flex-col justify-center items-center py-6">
        <PagerView
          ticket={ticket}
          audioUnlocked={audioUnlocked}
          wakeLockActive={wakeLockActive}
          onActivateAudio={() => setShowPrompt(true)}
        />
      </main>

      {/* High-visibility Urgent Buzz Alert Modal */}
      {isBuzzerFiring && (
        <BuzzAlertModal
          displayNumber={ticket.display_number}
          customLabel={ticket.custom_label}
          brandColor={ticket.business?.theme_color || '#f97316'}
          isAcknowledged={Boolean(ticket.acknowledged_at)}
          onAcknowledge={handleAcknowledge}
        />
      )}

      {/* Footer */}
      <footer className="py-4 text-center text-xs text-slate-600 font-mono">
        Pingili Universal Digital Pager • Session {getClientSessionId().substring(0, 8)}
      </footer>
    </div>
  );
}

export default App;
