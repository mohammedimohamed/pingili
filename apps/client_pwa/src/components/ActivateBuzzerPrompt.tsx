import React, { useState } from 'react';
import { Volume2, Bell, ShieldCheck, Loader2 } from 'lucide-react';
import { audioBuzzer } from '../lib/audioBuzzer';
import { wakeLockService } from '../lib/wakeLock';

interface Props {
  onActivated: () => void;
  brandColor?: string;
}

export const ActivateBuzzerPrompt: React.FC<Props> = ({ onActivated, brandColor = '#0284c7' }) => {
  const [loading, setLoading] = useState(false);

  const handleActivate = async () => {
    setLoading(true);
    try {
      // 1. Unlock Web Audio
      await audioBuzzer.unlock();

      // 2. Request Wake Lock
      await wakeLockService.request();

      // 3. Request Push Notification permission if supported
      if ('Notification' in window && Notification.permission === 'default') {
        try {
          await Notification.requestPermission();
        } catch {
          // ignore
        }
      }

      onActivated();
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center p-4 bg-black/80 backdrop-blur-md animate-fade-in">
      <div className="w-full max-w-md bg-slate-900 border border-slate-800 rounded-3xl p-6 shadow-2xl text-center text-white">
        <div 
          className="w-16 h-16 mx-auto mb-4 rounded-2xl flex items-center justify-center text-white shadow-lg animate-bounce"
          style={{ backgroundColor: brandColor }}
        >
          <Bell className="w-8 h-8" />
        </div>

        <h2 className="text-2xl font-bold tracking-tight mb-2">
          Activate Live Beeper
        </h2>
        <p className="text-slate-400 text-sm mb-6 leading-relaxed">
          Tap below to allow Pingili to sound the alarm and keep your ticket live so you don't miss your turn.
        </p>

        <div className="bg-slate-800/60 rounded-2xl p-4 mb-6 text-left space-y-2 text-xs text-slate-300">
          <div className="flex items-center gap-2">
            <Volume2 className="w-4 h-4 text-emerald-400 shrink-0" />
            <span>Sounds pager chime when called</span>
          </div>
          <div className="flex items-center gap-2">
            <ShieldCheck className="w-4 h-4 text-emerald-400 shrink-0" />
            <span>Prevents phone screen from going dark</span>
          </div>
        </div>

        <button
          onClick={handleActivate}
          disabled={loading}
          className="w-full py-4 px-6 rounded-2xl font-bold text-lg text-white shadow-xl transition-all transform active:scale-98 flex items-center justify-center gap-2 cursor-pointer"
          style={{ backgroundColor: brandColor }}
        >
          {loading ? (
            <Loader2 className="w-6 h-6 animate-spin" />
          ) : (
            <>
              <Volume2 className="w-6 h-6" />
              <span>Tap to Activate Beeper 🔔</span>
            </>
          )}
        </button>

        <p className="mt-3 text-slate-500 text-xs">
          Zero app install • 100% private
        </p>
      </div>
    </div>
  );
};
