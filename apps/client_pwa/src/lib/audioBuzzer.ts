/**
 * Pingili Web Audio Synthesizer
 * Zero-asset, zero-latency digital coaster pager chime and buzzer engine.
 */

class AudioBuzzerService {
  private ctx: AudioContext | null = null;
  private isUnlocked = false;
  private isBuzzing = false;
  private buzzerInterval: number | null = null;

  /**
   * Initializes and unlocks the Web Audio Context.
   * MUST be invoked inside a user interaction handler (e.g. click/tap).
   */
  async unlock(): Promise<boolean> {
    try {
      const AudioCtx = window.AudioContext || (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext;
      if (!this.ctx) {
        this.ctx = new AudioCtx();
      }

      if (this.ctx.state === 'suspended') {
        await this.ctx.resume();
      }

      // Play a short, subtle, pleasant chime to verify the audio pipe
      this.playChime();
      this.isUnlocked = true;
      return true;
    } catch (err) {
      console.warn('[AudioBuzzer] Failed to unlock audio context:', err);
      return false;
    }
  }

  get unlocked(): boolean {
    return this.isUnlocked && this.ctx?.state === 'running';
  }

  /**
   * Short pleasant 2-tone chime played on initial user unlock
   */
  playChime(): void {
    if (!this.ctx) return;

    const now = this.ctx.currentTime;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();

    osc.type = 'sine';
    // Frequency glide: 523.25Hz (C5) -> 659.25Hz (E5)
    osc.frequency.setValueAtTime(523.25, now);
    osc.frequency.exponentialRampToValueAtTime(659.25, now + 0.15);

    gain.gain.setValueAtTime(0.001, now);
    gain.gain.exponentialRampToValueAtTime(0.25, now + 0.05);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.35);

    osc.connect(gain);
    gain.connect(this.ctx.destination);

    osc.start(now);
    osc.stop(now + 0.35);
  }

  /**
   * Plays a single "Beep-Beep" coaster buzzer cycle
   */
  private playBuzzerPulse(): void {
    if (!this.ctx) return;
    if (this.ctx.state === 'suspended') {
      this.ctx.resume();
    }

    const now = this.ctx.currentTime;

    // Dual-tone frequency combination (classic high-urgency restaurant buzzer)
    const playBeep = (startTime: number, duration: number) => {
      if (!this.ctx) return;
      const osc1 = this.ctx.createOscillator();
      const osc2 = this.ctx.createOscillator();
      const gain = this.ctx.createGain();

      osc1.type = 'sawtooth';
      osc2.type = 'square';
      osc1.frequency.setValueAtTime(880, startTime); // A5
      osc2.frequency.setValueAtTime(1174.66, startTime); // D6

      gain.gain.setValueAtTime(0.01, startTime);
      gain.gain.linearRampToValueAtTime(0.35, startTime + 0.02);
      gain.gain.linearRampToValueAtTime(0.01, startTime + duration);

      osc1.connect(gain);
      osc2.connect(gain);
      gain.connect(this.ctx.destination);

      osc1.start(startTime);
      osc2.start(startTime + duration);
      osc1.stop(startTime + duration);
      osc2.stop(startTime + duration);
    };

    // Double beep: "Beep-Beep"
    playBeep(now, 0.12);
    playBeep(now + 0.18, 0.16);

    // Trigger haptic vibration if supported
    if ('vibrate' in navigator) {
      try {
        navigator.vibrate([200, 100, 300, 200]);
      } catch {
        // Ignore vibration errors (e.g. permissions)
      }
    }
  }

  /**
   * Starts repeating the buzzer loop every 1.5 seconds until stopped
   */
  startBuzzer(): void {
    if (this.isBuzzing) return;
    this.isBuzzing = true;

    // Play immediately
    this.playBuzzerPulse();

    // Repeat every 1.5 seconds
    this.buzzerInterval = window.setInterval(() => {
      if (!this.isBuzzing) return;
      this.playBuzzerPulse();
    }, 1500);
  }

  /**
   * Stops the buzzer loop
   */
  stopBuzzer(): void {
    this.isBuzzing = false;
    if (this.buzzerInterval !== null) {
      clearInterval(this.buzzerInterval);
      this.buzzerInterval = null;
    }
    if ('vibrate' in navigator) {
      try {
        navigator.vibrate(0); // Cancel ongoing vibration
      } catch {
        // ignore
      }
    }
  }
}

export const audioBuzzer = new AudioBuzzerService();
