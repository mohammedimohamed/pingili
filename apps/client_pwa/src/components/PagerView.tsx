import React from 'react';
import { 
  Wifi, 
  Clock, 
  ChefHat, 
  CheckCircle2, 
  Sparkles,
  Volume2,
  SlidersHorizontal
} from 'lucide-react';
import type { Ticket, TicketStatus } from '../types';
import { devSimulateStatus, isLiveSupabaseConfigured } from '../lib/supabase';
import { audioBuzzer } from '../lib/audioBuzzer';

interface Props {
  ticket: Ticket;
  audioUnlocked: boolean;
  wakeLockActive: boolean;
  onActivateAudio: () => void;
}

export const PagerView: React.FC<Props> = ({
  ticket,
  audioUnlocked,
  wakeLockActive,
  onActivateAudio
}) => {
  const brandColor = ticket.business?.theme_color || '#f97316';
  const businessName = ticket.business?.name || 'Pingili Pager';
  const businessTagline = ticket.business?.tagline || 'Live Order Tracker';

  const stages: { key: TicketStatus; label: string; icon: React.ReactNode }[] = [
    { key: 'waiting', label: 'Queued', icon: <Clock className="w-4 h-4" /> },
    { key: 'in_progress', label: 'Preparing', icon: <ChefHat className="w-4 h-4" /> },
    { key: 'ready', label: 'Ready', icon: <Sparkles className="w-4 h-4" /> },
    { key: 'completed', label: 'Completed', icon: <CheckCircle2 className="w-4 h-4" /> }
  ];

  const currentStageIndex = stages.findIndex(s => s.key === ticket.status);

  return (
    <div className="w-full max-w-sm mx-auto px-4 py-8 flex flex-col items-center">
      {/* Pager Chassis */}
      <div className="w-full bg-gradient-to-b from-slate-900 via-slate-900 to-slate-950 border-4 border-slate-800 rounded-[2.5rem] p-6 shadow-2xl relative overflow-hidden text-white flex flex-col items-center">
        
        {/* Coaster Pager Top LED Ring */}
        <div className="w-full flex items-center justify-between mb-6 px-2">
          {/* Status LED */}
          <div className="flex items-center gap-2 bg-slate-800/80 px-3 py-1.5 rounded-full border border-slate-700 text-xs">
            <span className="w-2.5 h-2.5 rounded-full bg-emerald-500 animate-pulse shadow-[0_0_8px_#10b981]" />
            <span className="text-slate-300 font-medium">Live Queue</span>
          </div>

          {/* Audio / Wake Lock Status */}
          <div className="flex items-center gap-2">
            {audioUnlocked ? (
              <span className="p-1.5 bg-emerald-500/10 text-emerald-400 rounded-full border border-emerald-500/20" title="Audio Beeper Ready">
                <Volume2 className="w-3.5 h-3.5" />
              </span>
            ) : (
              <button 
                onClick={onActivateAudio}
                className="px-2.5 py-1 bg-amber-500/20 text-amber-400 rounded-full border border-amber-500/30 text-xs font-semibold animate-pulse cursor-pointer flex items-center gap-1"
              >
                <span>Tap for Sound</span>
              </button>
            )}

            <span 
              className={`p-1.5 rounded-full border ${
                wakeLockActive 
                  ? 'bg-blue-500/10 text-blue-400 border-blue-500/20' 
                  : 'bg-slate-800 text-slate-500 border-slate-700'
              }`}
              title={wakeLockActive ? 'Screen kept awake' : 'Normal screen timeout'}
            >
              <Wifi className="w-3.5 h-3.5" />
            </span>
          </div>
        </div>

        {/* Business Branding */}
        <div className="text-center mb-6">
          <div 
            className="w-12 h-12 mx-auto mb-2 rounded-2xl flex items-center justify-center font-black text-xl text-white shadow-lg"
            style={{ backgroundColor: brandColor }}
          >
            {businessName.substring(0, 2).toUpperCase()}
          </div>
          <h2 className="text-lg font-bold tracking-tight text-slate-100">
            {businessName}
          </h2>
          <p className="text-xs text-slate-400">
            {businessTagline}
          </p>
        </div>

        {/* Digital LED Screen Window */}
        <div className="w-full bg-black/90 border-2 border-slate-800 rounded-3xl p-6 text-center shadow-inner relative mb-6">
          <div className="absolute top-2 left-4 text-[10px] tracking-widest text-slate-500 font-mono uppercase">
            DIGITAL PAGER ID
          </div>

          <div 
            className="text-6xl font-black font-mono tracking-tight my-2 drop-shadow-[0_0_15px_rgba(255,255,255,0.2)]"
            style={{ color: ticket.status === 'ready' ? brandColor : '#ffffff' }}
          >
            {ticket.display_number}
          </div>

          {ticket.custom_label && (
            <div className="text-sm font-medium text-slate-300 bg-slate-900/80 py-1 px-3 rounded-full inline-block border border-slate-800 max-w-[90%] truncate">
              {ticket.custom_label}
            </div>
          )}
        </div>

        {/* Progress Pipeline */}
        <div className="w-full bg-slate-950/60 rounded-2xl p-4 border border-slate-800/80 mb-4">
          <div className="flex items-center justify-between mb-2">
            <span className="text-xs text-slate-400 font-medium">Order Status</span>
            <span 
              className="text-xs font-bold uppercase tracking-wider px-2 py-0.5 rounded-full"
              style={{ 
                backgroundColor: `${brandColor}22`,
                color: brandColor 
              }}
            >
              {ticket.status.replace('_', ' ')}
            </span>
          </div>

          {/* Multi-step progress bars */}
          <div className="grid grid-cols-4 gap-1.5 my-3">
            {stages.map((stage, idx) => {
              const isPastOrCurrent = idx <= currentStageIndex;
              const isCurrent = idx === currentStageIndex;
              return (
                <div key={stage.key} className="flex flex-col items-center gap-1.5">
                  <div 
                    className={`h-2 w-full rounded-full transition-all duration-500 ${
                      isPastOrCurrent ? 'shadow-sm' : 'bg-slate-800'
                    }`}
                    style={{ 
                      backgroundColor: isPastOrCurrent ? brandColor : undefined 
                    }}
                  />
                  <span className={`text-[10px] font-medium transition-colors ${
                    isCurrent ? 'text-white font-bold' : isPastOrCurrent ? 'text-slate-300' : 'text-slate-600'
                  }`}>
                    {stage.label}
                  </span>
                </div>
              );
            })}
          </div>

          <p className="text-[11px] text-slate-400 text-center mt-3">
            {ticket.status === 'waiting' && 'Your order is in queue. Relax, we will buzz you!'}
            {ticket.status === 'in_progress' && 'Staff are preparing your order right now.'}
            {ticket.status === 'ready' && '🎉 Order ready! Please collect at the counter.'}
            {ticket.status === 'completed' && '✅ Order completed. Thank you for your visit!'}
          </p>
        </div>

        {/* Bottom Coaster Details */}
        <div className="text-[10px] text-slate-500 font-mono tracking-wider">
          TOKEN: {ticket.short_token.toUpperCase()} • PINGILI CLOUD PAGER
        </div>
      </div>

      {/* Dev Simulator Bar (Allows rapid testing without backend credentials) */}
      <div className="w-full mt-6 p-4 bg-slate-900/90 border border-slate-800 rounded-2xl text-xs text-slate-400">
        <div className="flex items-center justify-between mb-3 text-slate-300 font-semibold">
          <div className="flex items-center gap-1.5">
            <SlidersHorizontal className="w-3.5 h-3.5 text-amber-400" />
            <span>Interactive Dev Simulator</span>
          </div>
          <span className="text-[10px] bg-slate-800 px-2 py-0.5 rounded text-slate-400">
            {isLiveSupabaseConfigured ? 'Supabase Live' : 'Mock Mode'}
          </span>
        </div>

        <p className="text-[11px] text-slate-400 mb-3">
          Simulate cashier actions to test the real-time sound and vibration:
        </p>

        <div className="grid grid-cols-2 gap-2">
          <button
            onClick={() => devSimulateStatus(ticket.short_token, 'in_progress')}
            className="py-2 px-3 bg-slate-800 hover:bg-slate-700 text-slate-200 rounded-xl font-medium transition cursor-pointer"
          >
            Mark In Progress
          </button>
          <button
            onClick={() => {
              devSimulateStatus(ticket.short_token, 'ready');
              audioBuzzer.startBuzzer();
            }}
            className="py-2 px-3 bg-amber-500 hover:bg-amber-400 text-slate-950 rounded-xl font-bold transition cursor-pointer"
          >
            🔔 Buzz Ready!
          </button>
          <button
            onClick={() => devSimulateStatus(ticket.short_token, 'completed')}
            className="py-2 px-3 bg-emerald-600 hover:bg-emerald-500 text-white rounded-xl font-medium transition cursor-pointer"
          >
            Mark Completed
          </button>
          <button
            onClick={() => audioBuzzer.playChime()}
            className="py-2 px-3 bg-slate-800 hover:bg-slate-700 text-slate-200 rounded-xl font-medium transition cursor-pointer"
          >
            Test Chime 🎵
          </button>
        </div>
      </div>
    </div>
  );
};
