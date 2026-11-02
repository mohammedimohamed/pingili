# 🔔 Pingili — Universal Digital Pager & Virtual Queue Notification Platform

Pingili replaces physical restaurant buzzers, paper tickets, and crowded waiting rooms with an instant, zero-friction digital workflow.

- **Zero App Install for Customers:** Customers scan a dynamic QR code that opens an ultra-fast PWA in their mobile browser (< 1.5s). Their phone beeps, vibrates, and alerts them when their order or turn is ready.
- **Turnkey for Businesses:** Cashiers and operators use the **Pingili Business App** (built with Flutter) to generate tickets in 1 tap, display dynamic QR codes, track customer connection status in real-time, and trigger the pager alert.

---

## 🏗️ Repository Architecture

This repository is structured as a monorepo:

```
pingili/
├── apps/
│   ├── client_pwa/          # Zero-Install Customer PWA (Vite + React + TS + Tailwind)
│   └── business_app/        # Cashier / Staff App (Flutter + Riverpod + Supabase)
├── supabase/
│   ├── migrations/          # PostgreSQL schema, RLS policies, & stored procedures
│   └── seed.sql             # Demo business profile & initial tickets
├── REQUIREMENTS.md          # Full Product Requirements Document (PRD)
└── package.json             # Root workspace scripts
```

---

## ⚡ Tech Stack

| Component | Technology | Role |
| :--- | :--- | :--- |
| **Backend & Realtime** | **Supabase (PostgreSQL)** | Auth, Database, Realtime WebSockets, atomic daily ticket counters, RLS |
| **Client PWA** | **React + Vite + Tailwind CSS** | Zero-asset Web Audio buzzer synthesizer, Screen Wake Lock API, Vibration API, PWA Service Worker |
| **Business App** | **Flutter + Riverpod** | Multi-device cashier dashboard (iOS, Android, Tablet, Web, Windows Desktop) |

---

## 🚀 Getting Started

### 1. Database Setup (Supabase)

You can run Supabase locally with Docker or use a free [Supabase Cloud](https://supabase.com) project.

1. In Supabase Cloud SQL Editor (or via `supabase db reset` locally), run:
   - [supabase/migrations/20261102000001_initial_schema.sql](supabase/migrations/20261102000001_initial_schema.sql)
   - [supabase/seed.sql](supabase/seed.sql)
2. Note your `SUPABASE_URL` and `SUPABASE_ANON_KEY`.

### 2. Client PWA (Customer Experience)

```bash
cd apps/client_pwa
npm install
cp .env.example .env.local
npm run dev
```

Open `http://localhost:5173/t/demo123` to test the customer buzzer experience.

### 3. Business App (Cashier Dashboard)

```bash
cd apps/business_app
flutter pub get
flutter run -d chrome     # Run as web app for side-by-side testing
# or
flutter run -d windows    # Run as native Windows app
```

---

## 📱 The Core "Beeper" Alert Mechanism

Mobile browsers restrict auto-playing audio unless initiated by a user gesture. Pingili solves this gracefully:
1. When the client opens `/t/{short_token}`, they tap **"Tap to Activate Live Beeper 🔔"**.
2. This gesture unlocks the **Web Audio API** oscillator, requests **Web Push** permission, and acquires a **Screen Wake Lock**.
3. When the cashier taps **"Notify / Buzz"**, the Supabase Realtime channel fires, instantly synthesizing a rhythmic pager sound, pulsing device vibration, and flashing a high-contrast visual alert.
4. The client taps **"Got it / Coming!"**, immediately confirming acknowledgment on the cashier's dashboard.

---

## 📄 License
MIT © Pingili Team
