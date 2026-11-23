# Pingili — Project Todos & Roadmap

## 🚀 Immediate Pilot Launch (Pre-Flight)
- [ ] Run `supabase/migrations/20261123000001_client_device_details.sql` in Supabase SQL Editor.
- [ ] Enable **Anonymous Sign-Ins** in Supabase Dashboard → Authentication → Providers.
- [ ] Deploy `apps/client_pwa` (`npm run build`) to TechWise Advisors HTTPS server with SPA rewrite (`/* -> /index.html`).
- [ ] Build Android APK (`flutter create --platforms=android .` + `flutter build apk --release`) with `--dart-define=PWA_BASE_URL=https://<techwise-domain>`.
- [ ] Test end-to-end on two physical phones over mobile data / HTTPS.

## 📦 Phase 2: Value-Added Modules
- [ ] **Module 1 (Loyalty & Stamp Cards):** Award automatic digital stamps/points upon ticket `completed` and show reward redemption badge on cashier app.
- [ ] **Module 2 (SMS / WhatsApp Fallback):** Optional phone number input on PWA for long-wait services (car detailing, repair shops).
- [ ] **Module 3 (Micro-Feedback & Google Reviews):** 1–5 star rating prompt 5 minutes after completion (4–5 stars → Google Maps review link; 1–3 stars → private owner feedback).
- [ ] **Module 4 (TV Waiting Room Display):** Dedicated `/tv/:slug` view for clinics and fast-food monitors.
- [ ] **Web Push VAPID:** Server-side Edge Function to wake locked phones when browser is backgrounded.
- [ ] **Multi-Staff RBAC:** Optional staff PIN / role switcher (`Owner`, `Manager`, `Operator`) for larger teams.
