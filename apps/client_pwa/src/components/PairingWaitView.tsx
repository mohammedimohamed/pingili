import React from 'react';
import { Sparkles, Smartphone, CheckCircle2 } from 'lucide-react';
import type { PairingSession } from '../types';
import { devSimulatePairSuccess, isLiveSupabaseConfigured } from '../lib/supabase';

interface Props {
  session: PairingSession;
}

export const PairingWaitView: React.FC<Props> = ({ session }) => {
  const brandColor = session.business?.theme_color || '#f97316';
  const businessName = session.business?.name || 'Pingili Pager';

  return (
    <div className="w-full max-w-sm mx-auto px-4 py-8 flex flex-col items-center">
      <div className="w-full bg-gradient-to-b from-slate-900 via-slate-900 to-slate-950 border-4 border-slate-800 rounded-[2.5rem] p-6 shadow-2xl text-white flex flex-col items-center text-center">
        {/* Returning Customer Badge */}
        {session.visit_count > 1 ? (
          <div className="mb-4 inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-emerald-500/15 border border-emerald-500/30 text-emerald-400 text-xs font-semibold">
            <Sparkles className="w-3.5 h-3.5" />
            <span>Welcome back! Visit #{session.visit_count}</span>
          </div>
        ) : (
          <div className="mb-4 inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-slate-800 border border-slate-700 text-slate-300 text-xs font-medium">
            <Smartphone className="w-3.5 h-3.5" />
            <span>Instant Check-In</span>
          </div>
        )}

        {/* Business Brand */}
        <div
          className="w-12 h-12 mx-auto mb-2 rounded-2xl flex items-center justify-center font-black text-xl text-white shadow-lg"
          style={{ backgroundColor: brandColor }}
        >
          {businessName.substring(0, 2).toUpperCase()}
        </div>
        <h2 className="text-lg font-bold tracking-tight text-slate-100">
          {businessName}
        </h2>
        <p className="text-xs text-slate-400 mb-6">
          Show or say this code to the cashier
        </p>

        {/* Big 4-Digit Pairing Code */}
        <div className="w-full bg-black/90 border-2 border-slate-800 rounded-3xl p-6 shadow-inner mb-6">
          <div className="text-[10px] tracking-widest text-slate-500 font-mono uppercase mb-1">
            YOUR CHECK-IN CODE
          </div>
          <div
            className="text-6xl font-black font-mono tracking-[0.2em] my-2"
            style={{ color: brandColor }}
          >
            {session.pairing_code}
          </div>
          <div className="flex items-center justify-center gap-2 text-xs text-slate-400 mt-3">
            <span className="w-2 h-2 rounded-full bg-amber-400 animate-ping" />
            <span>Waiting for cashier to tap your code...</span>
          </div>
        </div>

        <p className="text-[11px] text-slate-500 leading-relaxed">
          Your digital pager will start automatically as soon as your order is linked.
        </p>
      </div>

      {/* Mock Mode Helper */}
      {!isLiveSupabaseConfigured && (
        <div className="w-full mt-6 p-4 bg-slate-900/90 border border-slate-800 rounded-2xl text-xs text-slate-400 text-center">
          <p className="mb-3 text-slate-300 font-medium">
            Mock Mode: Simulate the cashier tapping <strong className="text-white">{session.pairing_code}</strong>
          </p>
          <button
            onClick={devSimulatePairSuccess}
            className="w-full py-2.5 px-4 bg-emerald-600 hover:bg-emerald-500 text-white rounded-xl font-bold transition cursor-pointer flex items-center justify-center gap-2"
          >
            <CheckCircle2 className="w-4 h-4" />
            <span>Simulate Cashier 1-Tap Pair → #044</span>
          </button>
        </div>
      )}
    </div>
  );
};
