/**
 * Screen Wake Lock Utility
 * Keeps mobile screen awake while the customer waits for their order.
 */

class WakeLockService {
  private sentinel: WakeLockSentinel | null = null;
  private isRequested = false;

  async request(): Promise<boolean> {
    this.isRequested = true;
    if (!('wakeLock' in navigator)) {
      console.info('[WakeLock] Screen Wake Lock API not supported on this browser.');
      return false;
    }

    try {
      this.sentinel = await navigator.wakeLock.request('screen');
      console.info('[WakeLock] Screen Wake Lock acquired successfully.');

      this.sentinel.addEventListener('release', () => {
        console.info('[WakeLock] Screen Wake Lock was released.');
        this.sentinel = null;
      });

      // Handle visibility changes: Re-request lock if page becomes visible again
      document.addEventListener('visibilitychange', this.handleVisibilityChange);

      return true;
    } catch (err) {
      console.warn('[WakeLock] Failed to acquire wake lock:', err);
      return false;
    }
  }

  private handleVisibilityChange = async () => {
    if (this.isRequested && document.visibilityState === 'visible' && !this.sentinel) {
      try {
        if ('wakeLock' in navigator) {
          this.sentinel = await navigator.wakeLock.request('screen');
          console.info('[WakeLock] Screen Wake Lock re-acquired on tab focus.');
        }
      } catch (err) {
        console.warn('[WakeLock] Re-acquiring wake lock failed:', err);
      }
    }
  };

  release(): void {
    this.isRequested = false;
    document.removeEventListener('visibilitychange', this.handleVisibilityChange);
    if (this.sentinel) {
      this.sentinel.release().catch(() => {});
      this.sentinel = null;
    }
  }

  get active(): boolean {
    return this.sentinel !== null;
  }
}

export const wakeLockService = new WakeLockService();
