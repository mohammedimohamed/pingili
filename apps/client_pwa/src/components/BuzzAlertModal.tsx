import React, { useEffect } from 'react';
import { BellRing, CheckCircle2, ArrowRight } from 'lucide-react';
import confetti from 'canvas-confetti';
import { audioBuzzer } from '../lib/audioBuzzer';

interface Props {
  displayNumber: string;
  customLabel?: string | null;
  brandColor?: string;
  isAcknowledged: boolean;
  onAcknowledge: () => void;
}

export const BuzzAlertModal: React.FC<Props> = ({
  displayNumber,
  customLabel,
  brandColor = '#f97316',
  isAcknowledged,
  onAcknowledge
}) => {
  useEffect(() => {
    // If acknowledged, trigger celebratory confetti
    if (isAcknowledged) {
      confetti({
        particleCount: 80,
        spread: 70,
        origin: { y: 0.6 }
      });
    }
  }, [isAcknowledged]);

  const handleGotIt = () => {
    audioBuzzer.stopBuzzer();
    onAcknowledge();
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/90 backdrop-blur-xl animate-fade-in">
      <div 
        className="w-full max-w-sm rounded-3xl p-6 text-center text-white border-2 shadow-2xl relative overflow-hidden transition-all duration-300"
        style={{ 
          borderColor: isAcknowledged ? '#10b981' : brandColor,
          backgroundColor: '#0f172a'
        }}
      >
        {/* Pulsing beacon glow */}
        {!isAcknowledged && (
          <div 
            className="absolute -inset-1 rounded-3xl opacity-30 animate-pulse pointer-events-none blur-xl"
            style={{ backgroundColor: brandColor }}
          />
        )}

        <div className="relative z-10">
          <div 
            className="w-20 h-20 mx-auto mb-4 rounded-3xl flex items-center justify-center text-white shadow-2xl animate-bounce"
            style={{ backgroundColor: isAcknowledged ? '#10b981' : brandColor }}
          >
            {isAcknowledged ? (
              <CheckCircle2 className="w-10 h-10" />
            ) : (
              <BellRing className="w-10 h-10 animate-spin" />
            )}
          </div>

          <span className="inline-block px-3 py-1 rounded-full text-xs font-semibold tracking-wider uppercase mb-2 bg-white/10 text-emerald-400">
            {isAcknowledged ? 'Staff Notified • On Your Way' : '🔔 Buzzer Ringing!'}
          </span>

          <h1 className="text-5xl font-black tracking-tight mb-2 font-mono">
            {displayNumber}
          </h1>

          {customLabel && (
            <p className="text-slate-300 font-medium text-sm mb-4">
              {customLabel}
            </p>
          )}

          <div className="bg-slate-800/80 rounded-2xl p-4 mb-6 border border-slate-700">
            <p className="text-lg font-bold text-white mb-1">
              Your Order is Ready!
            </p>
            <p className="text-xs text-slate-400">
              Please proceed to the counter or pickup station.
            </p>
          </div>

          {!isAcknowledged ? (
            <button
              onClick={handleGotIt}
              className="w-full py-4 px-6 rounded-2xl font-bold text-lg text-white shadow-xl transition-all transform active:scale-95 flex items-center justify-center gap-2 cursor-pointer animate-pulse"
              style={{ backgroundColor: brandColor }}
            >
              <span>Got it / Coming! 🏃</span>
              <ArrowRight className="w-5 h-5" />
            </button>
          ) : (
            <div className="w-full py-4 px-6 rounded-2xl font-bold text-emerald-400 bg-emerald-500/10 border border-emerald-500/30 flex items-center justify-center gap-2">
              <CheckCircle2 className="w-5 h-5" />
              <span>We told the staff you're coming!</span>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
